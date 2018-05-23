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

using std::pair;



AbstractFitter::AbstractFitter(std::shared_ptr<DecayModel> model_, int n_param_extra, int max_region_size, GlobalAlgorithm global_algorithm, int n_thread, FittingOptions options, std::shared_ptr<ProgressReporter> reporter) :
   max_region_size(max_region_size), 
   global_algorithm(global_algorithm), 
   n_thread(n_thread), 
   options(options),
   reporter(reporter),
   lifetime_estimator(model_->getTransformedDataParameters()),
   inc(INC_ENTRIES),
   inc_full(INC_ENTRIES)
{
   // We need our own copy
   model = std::make_shared<DecayModel>(*model_);

   irf_idx_0 = 0;
   variable_phi = false;

   nl = model->getNumNonlinearVariables();
   l = model->getNumColumns();
   lmax = l;
   n = model->getTransformedDataParameters()->n_meas;
   
   pmax  = model->getNumDerivatives();

   ndim = std::max( n, 2*nl+3 );
   nmax = n + 16; // pad to prevent false sharing  

   n_param = nl + n_param_extra;

   // Check for valid input
   //----------------------------------
   if  (!(             l >= 0
          &&          nl >= 0
          && (nl<<1) + 3 <= ndim
          && !(nl == 0 && l == 0)))
   {
      throw std::runtime_error("Invalid input");
   }
   params.resize(nl);
   kap.resize(nl + 1);
   alf_err.resize(nl);
   alf_buf.resize(nl);
   alf.resize(n_param);
   err_upper.resize(n_param);
   err_lower.resize(n_param);

   avg_y.resize(n);
   w.resize(n); 
    
   int a_size = nmax * (l + 1);
   a.resize(a_size);

   fixed_param = -1;

   getting_errs = false;

   init();
   if (pmax != p)
      throw std::runtime_error("Inc matrix incorrectly setup");

   counts_per_photon = model->getTransformedDataParameters()->counts_per_photon;
}


int AbstractFitter::init()
{
   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   int lp1 = l+1;
   philp1 = l == 0;
   p = 0;

   if ( l > 0 && nl > 0 )
   {
      model->setupIncMatrix(inc);

      if (fixed_param >= 0)
      {
         int idx = 0;
         for (int k = 0; k < nl; k++)
         {
            if (k != fixed_param)
            {
               for (int j = 0; j < lp1; ++j) 
                  inc[idx + j * MAX_VARIABLES] = inc[k + j * MAX_VARIABLES];
               idx++;
            }
         }
         for (int j = 0; j < lp1; ++j) 
            inc[idx + j * MAX_VARIABLES] = 0;
      }

      p = 0;
      for (int j = 0; j < lp1; ++j) 
      {
         //if (p == 0) 
         //   nconp1 = j + 1;
         for (int k = 0; k < nl; ++k) 
         {
            int inckj = inc[k + j * MAX_VARIABLES];
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
         philp1 = philp1 | (inc[k + l * MAX_VARIABLES] == 1);
   }

   return 0;
}

int AbstractFitter::fit(RegionData& region_data, FitResultsRegion& results, int itmax, int& niter, int &ierr_, double& c2)
{
   cur_chi2   = &c2;

   fixed_param = -1;
   getting_errs = false;

   init();

   region_data.GetAverageDecay(avg_y.data());

   if (global_algorithm == GlobalAnalysis)
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
   results.getPointers(alf_results, lin_params, chi2);

   chi2_norm = n - ((float)(nl))/s - l;

   // Assign initial guesses to nonlinear variables  
   std::vector<double> initial_alf(nl + l);
   double tau_mean = lifetime_estimator.EstimateMeanLifetime(avg_y, region_data.data_type);
   model->getInitialVariables(initial_alf, tau_mean);

   // Fit!
   fitFcn(nl, initial_alf, niter, ierr_);

   chi2_final = *cur_chi2;


   for(int i=0; i<nl; i++)
      alf_results[i] = (float) initial_alf[i];


   if (global_algorithm == GlobalBinning)
   {
      s = region_data.GetSize();
      region_data.GetPointers(y, irf_idx);

      getLinearParams();
   }


   results.setFitStatus(ierr_);

   return 0;
}




double tol(double a, double b)
{
   return 2*(b-a)/(a+b) < 0.001;
}


int AbstractFitter::calculateErrors(double conf_limit)
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
   
   this->conf_limit = conf_limit;

   std::copy(alf.begin(), alf.end(), alf_buf.begin());
   std::copy(inc.begin(), inc.end(), inc_full.begin());
   

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
   
         init();

         search_dir = lim;

         uintmax_t max = 20;

         errno = 0;
         ans = toms748_solve(boost::bind(&AbstractFitter::errMinFcn,this,_1), 
                     0.0, 0.1*fixed_value_initial, tol, max, c_policy());    
         
         if (errno != 0)
         {
            ans = toms748_solve(boost::bind(&AbstractFitter::errMinFcn,this,_1), 
                     0.1*fixed_value_initial, 0.8*fixed_value_initial, tol, max, c_policy());    
         }

         if (reporter->shouldTerminate())
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

double AbstractFitter::errMinFcn(double x)
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

   fitFcn(nl-1,alf_err,niter,ierr);
            
   F = (*cur_chi2-chi2_final)/chi2_final * nmp ;
   
   dF = (F-F_crit)/F_crit;

   if(f_debug)
      fprintf(f_debug,"%d, %d, %f, %f, %f, %f, %f, %f\n",fixed_param,search_dir,fixed_value_initial,fixed_value_cur,chi2_crit,*cur_chi2,F_crit,F);

   // terminate ASAP
   if (reporter->shouldTerminate())
      F = F_crit;

   return F-F_crit;
}

void AbstractFitter::setAlf(const double* alf_)
{
   std::copy(alf_, alf_ + nl, alf.begin());

   int idx = 0;
   for (int i = 0; i<nl; i++)
   {
      if (i == fixed_param)
         params[i] = fixed_value_cur;
      else
         params[i] = alf[idx++];
   }
}

void AbstractFitter::getModel(std::shared_ptr<DecayModel> model, int irf_idx, aligned_vector<double>& a)
{
   model->calculateModel(a, nmax, kap, params, irf_idx);
}

void AbstractFitter::getDerivatives(std::shared_ptr<DecayModel> model, int irf_idx, aligned_vector<double>& b)
{
   int valid_cols = 0;
   int ignore_cols = 0;

   model->calculateDerivatives(b, ndim, kap, params, irf_idx);

   // If required remove derivatives associated with fixed columns
   if (fixed_param >= 0)
   {
   
      for (int k = 0; k < fixed_param; ++k)
         for (int j = 0; j < l; ++j) 
            valid_cols += inc_full[k + j * MAX_VARIABLES];

      for (int j = 0; j < l; ++j)
         ignore_cols += inc_full[fixed_param + j * MAX_VARIABLES];

      auto src = b.begin() + ndim * (valid_cols + ignore_cols);
      auto dest = b.begin() + ndim * valid_cols;
      int size = ndim * (pmax - (valid_cols + ignore_cols)) * sizeof(double);

      std::move(src, src + size, dest);      
   }
}

int AbstractFitter::getFit(int irf_idx, const std::vector<double>& alf, float* lin_params, double* fit)
{
   float* adjust = model->getConstantAdjustment();
   model->calculateModel(a, nmax, kap, params, irf_idx);

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
