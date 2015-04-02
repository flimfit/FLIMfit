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
#include "DecayModel.h"
#include "FlagDefinitions.h"

#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include <boost/math/tools/roots.hpp>
#include "boost/bind.hpp"
#include <limits>
#include <exception>


//#include "util.h"

using std::min;
using std::max;
using std::pair;



AbstractFitter::AbstractFitter(shared_ptr<DecayModel> model, int n_param_extra, int max_region_size, int global_algorithm, int n_thread, int* terminate) :
   model(model),
   n_param(n_param),
   max_region_size(max_region_size), 
   global_algorithm(global_algorithm), 
   n_thread(n_thread), 
   terminate(terminate),
   lifetime_estimator(model->GetAcquisitionParameters())
{
   err = 0;


   irf_idx_0 = 0;

   nl = model->GetNumNonlinearVariables();
   l = model->GetNumColumns();
   lmax = l;
   n    = model->GetAcquisitionParameters()->n_meas;
   
   pmax  = model->GetNumDerivatives();

   ndim       = max( n, 2*nl+3 );
   nmax       = n + 16; // pad to prevent false sharing  

   n_param = nl + n_param_extra;


   for (int i = 0; i < n_thread; i++)
      models.push_back(*model);


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
   

   a_size = nmax * (l+1);
   b_size = ndim * ( pmax + 3 );

   a_.resize(n_thread, vector<double>(a_size));
   b_.resize(n_thread, vector<double>(b_size));
   r.resize(nmax * max_region_size);
   kap.resize(nl + 1);
   params.resize(nl);
   alf_err.resize(nl);
   alf_buf.resize(nl);
   alf.resize(n_param);
   err_upper.resize(n_param);
   err_lower.resize(n_param);

   avg_y.resize(n);
   w.resize(n); 
    
   fixed_param = -1;

   getting_errs = false;

   Init();

   counts_per_photon = model->GetAcquisitionParameters()->counts_per_photon;


   if (pmax != p)
      err = ERR_INVALID_INPUT;

}


AbstractFitter* new_clone(AbstractFitter const& other)
{
   return other.clone();
}

int AbstractFitter::Init()
{
   //int j, k, inckj;

   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   int lp1 = l+1;

   //nconp1 = lp1;
   philp1 = l == 0;
   p = 0;

   

   if ( l > 0 && nl > 0 )
   {
      model->SetupIncMatrix(inc);

      if (fixed_param >= 0)
      {
         int idx = 0;
         for (int k = 0; k < nl; k++)
         {
            if (k != fixed_param)
            {
               for (int j = 0; j < lp1; ++j) 
                  inc[idx + j * 12] = inc[k + j * 12];
               idx++;
            }
         }
         for (int j = 0; j < lp1; ++j) 
            inc[idx + j * 12] = 0;
      }

      p = 0;
      for (int j = 0; j < lp1; ++j) 
      {
         //if (p == 0) 
         //   nconp1 = j + 1;
         for (int k = 0; k < nl; ++k) 
         {
            int inckj = inc[k + j * 12];
            if (inckj != 0 && inckj != 1)
               break;
            if (inckj == 1)
               p++;
         }
      }

      // Determine if column L+1 is in the model
      //---------------------------------------------
      philp1 = false;
      for (int k = 0; k < nl; ++k) 
         philp1 = philp1 | (inc[k + l * 12] == 1); 
   }

   //ncon = nconp1 - 1;
   

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

   region_data.GetAverageDecay(avg_y.data());

   if (global_algorithm == MODE_GLOBAL_ANALYSIS)
   {
      s = region_data.GetSize();
      region_data.GetPointers(y, irf_idx);
   }
   else
   {
      s = 1;
      y = avg_y.data();
      irf_idx = &irf_idx_0;
   }


   float *alf_results;
   results.GetPointers(alf_results, lin_params, chi2);

   chi2_norm = n - ((float)(nl))/s - l;

   // Assign initial guesses to nonlinear variables  
   double tau_mean = lifetime_estimator.EstimateMeanLifetime(avg_y, region_data.data_type);
   model->GetInitialVariables(alf, tau_mean);

   // Fit!
   int ret = FitFcn(nl, alf, itmax, &niter, &ierr);

   chi2_final = *cur_chi2;


   for(int i=0; i<nl; i++)
      alf_results[i] = (float) alf[i];


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

   std::copy(alf.begin(), alf.end(), alf_buf.begin());
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


void AbstractFitter::GetParams(int nl, const vector<double>& alf)
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

double* AbstractFitter::GetModel(const vector<double>& alf, int irf_idx, int isel, int thread)
{
   return GetModel(alf.data(), irf_idx, isel, thread);
}


/*
   Get the model and derivatives, potentially removing a row if we're fitting
   with a fixed column (to calculate errors)
*/
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

   vector<double>& a = a_[omp_thread];
   vector<double>& b = b_[omp_thread];

   _ASSERT(_CrtCheckMemory());
   models[omp_thread].CalculateModel(a, nmax, b, ndim, kap, params, irf_idx, isel);
   _ASSERT(_CrtCheckMemory());

   // If required remove derivatives associated with fixed columns
   if (fixed_param >= 0)
   {
   
      for (int k = 0; k < fixed_param; ++k)
         for (int j = 0; j < l; ++j) 
            valid_cols += inc_full[k + j * 12];

      for (int j = 0; j < l; ++j)
         ignore_cols += inc_full[fixed_param + j * 12];

      auto src = b.begin() + ndim * (valid_cols + ignore_cols);
      auto dest = b.begin() + ndim * valid_cols;
      int size = ndim * (pmax - (valid_cols + ignore_cols)) * sizeof(double);

      std::move(src, src + size, dest);      
   }

   return params.data();
}

int AbstractFitter::GetFit(int irf_idx, const vector<double>& alf, float* lin_params, double* fit)
{
   if (err != 0)
      return err;

   vector<double>& a = a_[0];
   vector<double>& b = b_[0];

   float* adjust = model->GetConstantAdjustment();
   model->CalculateModel(a, n, b, ndim, kap, params, irf_idx, 1);

   int idx = 0;
   for(int i=0; i<n; i++)
   {
      fit[idx] = adjust[i];
      for(int j=0; j<l; j++)
         fit[idx] += a[nmax*j+i] * lin_params[j];

      fit[idx]   += a[nmax*l+i];
      fit[idx++] *= counts_per_photon;
   }

   return 0;
}

void AbstractFitter::ReleaseResidualMemory()
{
   r.clear();
}
