//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================
#include "AbstractFitter.h"

#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include <boost/math/tools/roots.hpp>
#include "boost/bind.hpp"
#include <limits>
#include <exception>

#include "FlagDefinitions.h"
#include "util.h"

using namespace std;

AbstractFitter::AbstractFitter(FitModel* model, int n_param, int max_region_size, int global_algorithm, int n_thread, int* terminate) : 
    model(model), n_param(n_param), max_region_size(max_region_size), global_algorithm(global_algorithm), n_thread(n_thread), terminate(terminate)
{
   err = 0;

   a_   = NULL;
   r   = NULL;
   b_   = NULL;
   kap = NULL;
   alf = NULL;
   err_upper = NULL;
   err_lower = NULL;
   alf_buf = NULL;
   alf_err = NULL;

   params = NULL;
   alf_err = NULL;

   nl   = model->nl;
   l    = model->l;
   n    = model->n;
   nmax = model->n;

   pmax  = model->p;

   ndim       = max( n, 2*nl+3 );
   nmax       = n + 16; // pad to prevent false sharing  

   int lp1 = l+1;


   for (int i=0; i<n_thread; i++)
      model_buffer.push_back( model->CreateBuffer() );


   // Check for valid input
   //----------------------------------
   if  (!(             l >= 0
          &&          nl >= 0
          && (nl<<1) + 3 <= ndim
          && !(nl == 0 && l == 0)))
   {
      err = ERR_INVALID_INPUT;
      return;
   }
   

   a_size = nmax * lp1;
   b_size = ndim * ( pmax + 3 );

   a_      = new double[ a_size * n_thread ]; //free ok
   r       = new double[ nmax * max_region_size ];
   b_      = new double[ ndim * ( pmax + 3 ) * n_thread ]; //free ok
   kap     = new double[ model->nl + 1 ];
   params  = new double[ model->nl ];
   alf_err = new double[ model->nl ];
   alf_buf = new double[ model->nl ];
   alf     = new double[ n_param ];
   err_upper = new double[ n_param ];
   err_lower = new double[ n_param ];

   y            = new float[ max_region_size * nmax ]; //free ok 
   irf_idx      = new int[ max_region_size ];

   w            = new float[ nmax ]; //free ok
    
   fixed_param = -1;

   getting_errs = false;

   Init();

   if (pmax != p)
      err = ERR_INVALID_INPUT;

}

AbstractFitter::~AbstractFitter()
{
   for (vector<WorkingBuffers*>::iterator it = model_buffer.begin(); it != model_buffer.end(); ++it)
      model->DisposeBuffer( *it );

   ClearVariable(r);
   ClearVariable(a_);
   ClearVariable(b_);
   ClearVariable(kap);

   ClearVariable(params);
   ClearVariable(alf_err);
   ClearVariable(alf_buf);
   ClearVariable(alf);
   ClearVariable(err_lower);
   ClearVariable(err_upper);
}

int AbstractFitter::Init()
{
   int j, k, inckj;

   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   int lp1 = l+1;

   nconp1 = lp1;
   philp1 = l == 0;
   p = 0;

   

   if ( l > 0 && nl > 0 )
   {
      model->SetupIncMatrix(inc);

      if (fixed_param >= 0)
      {
         int idx = 0;
         for (k = 0; k < nl; k++)
         {
            if (k != fixed_param)
            {
               for (j = 0; j < lp1; ++j) 
                  inc[idx + j * 12] = inc[k + j * 12];
               idx++;
            }
         }
         for (j = 0; j < lp1; ++j) 
            inc[idx + j * 12] = 0;
      }

      p = 0;
      for (j = 0; j < lp1; ++j) 
      {
         if (p == 0) 
            nconp1 = j + 1;
         for (k = 0; k < nl; ++k) 
         {
            inckj = inc[k + j * 12];
            if (inckj != 0 && inckj != 1)
               break;
            if (inckj == 1)
               p++;
         }
      }

      // Determine if column L+1 is in the model
      //---------------------------------------------
      philp1 = false;
      for (k = 0; k < nl; ++k) 
         philp1 = philp1 | (inc[k + l * 12] == 1); 
   }

   ncon = nconp1 - 1;
   

   return 0;
}

int AbstractFitter::Fit(RegionData& region_data, FitResultsRegion& results, int itmax, int& niter, int &ierr, double& c2)
{
   if (err != 0)
      return err;

   cur_chi2   = &c2;

   fixed_param = -1;
   getting_errs = false;

   Init();

   region_data.GetAverageDecay(avg_y);

   if (global_algorithm = MODE_GLOBAL_ANALYSIS)
   {
      s = region_data.GetSize();
      region_data.GetPointers(y, irf_idx);
   }
   else
   {
      s = 1;
      y = avg_y;
      irf_idx[0] = 0;
   }


   float *alf_results;
   results.GetPointers(alf_results, lin_params, chi2);


   chi2_norm = n - ((double)(model->nl))/s - l;



   // Assign initial guesses to nonlinear variables
   //------------------------------   
   //TODO: decide best place for average lifetime estimation
   //tau_ma = EstimateAverageLifetime(average_y, 0);
   double tau_ma = 0;

   model->SetInitialParameters(alf, tau_ma);


   int ret = FitFcn(model->nl, alf, itmax, &niter, &ierr);

   chi2_final = *cur_chi2;


   if (global_algorithm == MODE_GLOBAL_BINNING)
   {
      s = region_data.GetSize();
      region_data.GetPointers(y, irf_idx);

      GetLinearParams();
   }


   results.SetFitStatus(ierr);

   return ret;
}




double tol(double a, double b)
{
   return 2*(b-a)/(a+b) < 0.001;
}



int AbstractFitter::CalculateErrors(double conf_limit)
{
   using namespace boost::math;
   using namespace boost::math::tools;
   using namespace boost::math::policies;
   using boost::math::policies::domain_error;
   using boost::math::policies::ignore_error;

   pair<double , double> ans;

   typedef policy<
      domain_error<errno_on_error>
   > c_policy;

   f_debug = fopen("c:\\users\\scw09\\ERROR_DEBUG_OUTPUT4.csv","w");

   if(f_debug)
      fprintf(f_debug,"VAR, LIM,fixed_value_initial, fixed_value_cur, chi2_crit, chi2, F_crit, F\n");
   
   if (err != 0)
      return err;

   this->conf_limit = conf_limit;

   memcpy(alf_buf, alf, model->nl * sizeof(double));
   memcpy(inc_full, inc, 96*sizeof(int));

   getting_errs = true;

  
   // Get lower (lim=0) and upper (lim=1) limit
   for(int lim=0; lim<2; lim++)
   {

      for(int i=0; i<nl; i++)
      {

         fixed_param = i;
         fixed_value_initial = alf_buf[i];

         if(f_debug)
            fprintf(f_debug,"%d, %d, %f, %f, NaN, %f, NaN, NaN\n", i, lim, fixed_value_initial, fixed_value_initial, chi2_final);
   
   
         Init();

         search_dir = lim;

         uintmax_t max = 20;

         errno = 0;
         ans = toms748_solve(boost::bind(&AbstractFitter::ErrMinFcn,this,_1), 
                     0.0, 0.1*fixed_value_initial, tol, max, c_policy());    
         
         if (errno != 0)
         {
            ans = toms748_solve(boost::bind(&AbstractFitter::ErrMinFcn,this,_1), 
                     0.1*fixed_value_initial, 0.8*fixed_value_initial, tol, max, c_policy());    
         }

         if (*terminate)
         {
            lim = 2;
            break;
         }

         if (lim==0)
            err_lower[i] = (ans.first+ans.second)/2;
         else
            err_upper[i] = (ans.first+ans.second)/2;

      }
   }

   if(f_debug)
      fclose(f_debug);

   return 0;

}


double AbstractFitter::ErrMinFcn(double x)
{
   using namespace boost::math;
   
   double F,F_crit,chi2_crit,dF;
   int itmax = 10;

   int niter, ierr;

   double xs = x;
   if (search_dir == 0)
      xs *= -1;
   fixed_value_cur = fixed_value_initial + xs; 

   int nl = model->nl;

   int nmp = (n-l) * s - nl - s * l;

   fisher_f dist(1, nmp);
   F_crit = quantile(complement(dist, conf_limit/2));
   
   chi2_crit = chi2_final*(F_crit/nmp+1);

   // Use default starting parameters
   int idx = 0;
   for(int j=0; j<nl; j++)
      if (j!=fixed_param)
         alf_err[idx++] = alf_buf[j];

   FitFcn(nl-1,alf_err,itmax,&niter,&ierr);
            
   F = (*cur_chi2-chi2_final)/chi2_final * nmp ;
   
   dF = (F-F_crit)/F_crit;

   if(f_debug)
      fprintf(f_debug,"%d, %d, %f, %f, %f, %f, %f, %f\n",fixed_param,search_dir,fixed_value_initial,fixed_value_cur,chi2_crit,*cur_chi2,F_crit,F);

   // terminate ASAP
   if (*terminate)
      F = F_crit;

   return F-F_crit;
}


void AbstractFitter::GetParams(int nl, const double* alf)
{
   int idx = 0;
   for(int i=0; i<nl; i++)
   {
      if (i==fixed_param)
         params[i] = fixed_value_cur; 
      else
         params[i] = alf[idx++];
   }
}

double* AbstractFitter::GetModel(const double* alf, int irf_idx, int isel, int omp_thread)
{
   int valid_cols  = 0;
   int ignore_cols = 0;

   int idx = 0;
   for(int i=0; i<model->nl; i++)
   {
      if (i==fixed_param)
         params[i] = fixed_value_cur; 
      else
         params[i] = alf[idx++];
   }

   double* a = a_ + omp_thread * a_size;
   double* b = b_ + omp_thread * b_size;

   model->CalculateModel(model_buffer[omp_thread], a, n, b, ndim, kap, params, irf_idx, isel);

   // If required remove derivatives associated with fixed columns
   if (fixed_param >= 0)
   {
   
      for (int k = 0; k < fixed_param; ++k)
         for (int j = 0; j < l; ++j) 
            valid_cols += inc_full[k + j * 12];

      for (int j = 0; j < l; ++j)
         ignore_cols += inc_full[fixed_param + j * 12];

      double* src = b + ndim * (valid_cols + ignore_cols);
      double* dest = b + ndim * valid_cols;
      int size = ndim * (pmax - (valid_cols + ignore_cols)) * sizeof(double);

      memmove(dest, src, size);
      
   }

   return params;
}

int AbstractFitter::GetFit(int irf_idx, double* alf, float* lin_params, double* fit)
{
   if (err != 0)
      return err;

   float* adjust = model->GetConstantAdjustment();
   model->CalculateModel(model_buffer[0], a_, n, b_, ndim, kap, alf, irf_idx, 1);

   int idx = 0;
   for(int i=0; i<n; i++)
   {
      fit[idx] = adjust[i];
      for(int j=0; j<l; j++)
         fit[idx] += a_[nmax*j+i] * lin_params[j];

      fit[idx] += a_[nmax*l+i];
      fit[idx++] /= photons_per_count;
   }

   return 0;
}

void AbstractFitter::ReleaseResidualMemory()
{
   ClearVariable(r);
}
