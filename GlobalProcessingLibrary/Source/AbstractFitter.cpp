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

AbstractFitter::AbstractFitter(FitModel* model, int smax, int l, int nl, int gnl, int nmax, int ndim, int p_full, double *t, int variable_phi, int n_thread, int* terminate) : 
    model(model), smax(smax), l(l), nl(nl), gnl(gnl), gnl_full(gnl), nmax(nmax), ndim(ndim), p_full(p_full), t(t), variable_phi(variable_phi), n_thread(n_thread), terminate(terminate)
{
   err = 0;

   a_   = NULL;
   r   = NULL;
   b_   = NULL;
   kap = NULL;
   alf_buf = NULL;
   alf_err = NULL;

   params = NULL;
   alf_err = NULL;
   
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
   
   lp1 = l+1;

   a_      = new double[ nmax * lp1 * n_thread ]; //free ok
   r       = new double[ nmax * smax ];
   b_      = new double[ ndim * ( p_full + 3 ) * n_thread ]; //free ok
   kap     = new double[ nl + 1 ];
   params  = new double[ nl ];
   alf_err = new double[ nl ];
   alf_buf = new double[ nl ];

   fixed_param = -1;

   getting_errs = false;

   Init();

   if (p_full != p)
      err = ERR_INVALID_INPUT;

}

int AbstractFitter::Init()
{
   int j, k, inckj;

   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   nconp1 = l+1;
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

int AbstractFitter::Fit(int s, int n, int lmax, float* y, float *avg_y, int* irf_idx, double *alf, float *lin_params, float *chi2, int thread, int itmax, double smoothing, int& niter, int &ierr, double& c2)
{

   if (err != 0)
      return err;

   fixed_param = -1;
   getting_errs = false;

   Init();


   this->n          = n;
   this->s          = s;
   this->lmax       = lmax;
   this->y          = y;
   this->avg_y      = avg_y;
   this->lin_params = lin_params;
   this->irf_idx    = irf_idx;
   this->chi2       = chi2;
   this->cur_chi2   = &c2;
   this->smoothing  = smoothing;
   this->thread     = thread;

   gnl = gnl_full;

   int max_jacb = 65536; 

   chi2_norm = n - ((double)(nl))/s - l;
   
   int ret = FitFcn(nl, alf, itmax, max_jacb, &niter, &ierr);

   chi2_final = *cur_chi2;

   return ret;
}

double tol(double a, double b)
{
   return 2*(b-a)/(a+b) < 0.001;
}

int AbstractFitter::CalculateErrors(double* alf, double conf_limit, double* err_lower, double *err_upper)
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

   memcpy(alf_buf, alf, nl * sizeof(double));
   memcpy(inc_full, inc, 96*sizeof(int));

   getting_errs = true;

   gnl = gnl_full - 1;

   // Get lower (lim=0) and upper (lim=1) limit
   for(int lim=0; lim<2; lim++)
   {

      for(int i=0; i<gnl_full; i++)
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

   int nmp = (n-l) * s/smoothing - nl - s/smoothing * l;
   //int nmp = n * s - nl - s * l;

   fisher_f dist(1, nmp);
   F_crit = quantile(complement(dist, conf_limit/2));
   
   chi2_crit = chi2_final*(F_crit/nmp+1);

   // Use default starting parameters
   int idx = 0;
   for(int j=0; j<nl; j++)
      if (j!=fixed_param)
         alf_err[idx++] = alf_buf[j];


   int max_jacb = 65536;

   FitFcn(nl-1,alf_err,itmax,max_jacb,&niter,&ierr);
            
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
   for(int i=0; i<nl; i++)
   {
      if (i==fixed_param)
         params[i] = fixed_value_cur; 
      else
         params[i] = alf[idx++];
   }

   double* a = a_ + omp_thread * nmax * (l+1);
   double* b = b_ + omp_thread * ndim * ( p_full + 3 );

   model->CalculateModel(a, b, kap, params, irf_idx, isel, thread * n_thread + omp_thread);

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
      int size = ndim * (p_full - (valid_cols + ignore_cols)) * sizeof(double);

      memmove(dest, src, size);
      
   }

   return params;
}


int AbstractFitter::GetFit(int n_meas, int irf_idx, double* alf, float* lin_params, float* adjust, double counts_per_photon, double* fit)
{
   if (err != 0)
      return err;

   model->CalculateModel(a_, b_, kap, alf, irf_idx, 1, 0);

   int idx = 0;
   for(int i=0; i<n_meas; i++)
   {
      fit[idx] = adjust[i];
      for(int j=0; j<l; j++)
         fit[idx] += a_[n_meas*j+i] * lin_params[j];

      fit[idx] += a_[n_meas*l+i];
      fit[idx++] *= counts_per_photon;
   }

   return 0;
}

void AbstractFitter::ReleaseResidualMemory()
{
   ClearVariable(r);
}

AbstractFitter::~AbstractFitter()
{
   ClearVariable(r);
   ClearVariable(a_);
   ClearVariable(b_);
   ClearVariable(kap);

   ClearVariable(params);
   ClearVariable(alf_err);
   ClearVariable(alf_buf);
}
