
#include <boost/math/distributions/fisher_f.hpp>
#include <boost/math/tools/minima.hpp>
#include <boost/bind.hpp>
#include <limits>

#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "IRFConvolution.h"
#include "util.h"

using namespace boost::interprocess;

/*===============================================
  ProcessRegion
  ===============================================*/

int FLIMGlobalFitController::ProcessRegion(int g, int region, int px, int thread)
{
   using namespace boost::math;
   using namespace boost::math::tools;

   int i, j, s_thresh, itmax;
   int lin_idx;
   float I0;

   double ref = 0;
   double tau_ma;

   int ierr_local = 0;

//   int n_px = data->n_px;

   int r_idx = data->GetRegionIndex(g,region);

//   uint8_t *mask         = data->mask + g*n_px;
   float   *local_decay  = this->local_decay + thread * n_meas;
   float   *w            = this->w + thread * n;

   double *alf_local     = this->alf_local + thread * nl;
   float  *lin_local     = this->lin_local + thread * l;

   int start = data->GetRegionPos(g,region) + px;
         
   float *y, *lin_params, *chi2, *alf, *I;
   int   *irf_idx;

   lin_params = this->lin_params + start * lmax;
   chi2       = this->chi2       + start;
   I          = this->I          + start;

   if (data->global_mode == MODE_PIXELWISE)
   {
      y       = this->y;
      irf_idx = this->irf_idx;

      alf = this->alf + start * nl; 

      s_thresh = data->GetRegionData(thread, g, region, px, adjust_buf, y, NULL, w, irf_idx, local_decay);
      data->DetermineAutoSampling(thread, local_decay, nl+1);
   }
   else
   {
      y       = this->y       + thread * s * n_meas;
      irf_idx = this->irf_idx + thread * s;

      alf     = this->alf        + nl * r_idx;
   
      s_thresh = data->GetRegionData(thread, g, region, 0, adjust_buf, y, I, w, irf_idx, local_decay);
   }



   int n_meas_res = data->GetResampleNumMeas(thread);
   
   SetNaN(alf, nl);
   SetNaN(lin_params, s_thresh*l);


   // Check for termination requestion and that we have at least one px to fit
   //-------------------------------
   if (s_thresh == 0 || status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;

   // Estimate lifetime from mean arrival time if requested
   //------------------------------
   if (estimate_initial_tau)
   {
      tau_ma = CalculateMeanArrivalTime(local_decay, 0);

      if (n_v == 1)
      {
         alf_local[0] = tau_ma;
      }
      else if (n_v > 1)
      {
         double min_tau  = 0.5*tau_ma;
         double max_tau  = 1.5*tau_ma;
         double tau_step = (max_tau - min_tau)/(n_v-1);

         for(int i=0; i<n_v; i++)
            alf_local[i] = max_tau-i*tau_step;
      }
   }
   else
   {
      for(int i=0; i<n_v; i++)
         alf_local[i] = tau_guess[n_fix+i];
   }



   // Assign initial guesses to nonlinear variables
   //------------------------------
   i=0;
   for(j=0; j<n_v; j++)
      alf_local[i++] = TransformRange(alf_local[j],tau_min[j+n_fix],tau_max[j+n_fix]);
   
   for(j=0; j<n_beta; j++)
      alf_local[i++] = fixed_beta[j];

   for(j=0; j<n_fret_v; j++)
      alf_local[i++] = E_guess[j+n_fret_fix];

   for(j=0; j<n_theta_v; j++)
      alf_local[i++] = TransformRange(theta_guess[j+n_theta_fix],0,1000000);

   if(fit_t0)
      alf_local[i++] = t0_guess;

   if(fit_offset == FIT_GLOBALLY)
      alf_local[i++] = offset_guess;

   if(fit_scatter == FIT_GLOBALLY)
      alf_local[i++] = scatter_guess;

   if(fit_tvb == FIT_GLOBALLY) 
      alf_local[i++] = tvb_guess;

   if(ref_reconvolution == FIT_GLOBALLY)
      alf_local[i++] = ref_lifetime_guess;


   // For maximum likihood set initial guesses for contributions 
   // to sum to maximum intensity, evenly distributed
   if(algorithm == ALG_ML)
   {
      double mx = 0;
      for(int j=0; j<n; j++)
      {
         if (y[j]>mx)
            mx = y[j]; 
      }

      for(int j=0; j<l; j++)
         alf_local[i++] = log(mx/l);
   }

   itmax = 100;
   
   if ((global_algorithm == MODE_GLOBAL_BINNING) && (s_thresh > 1)) // use global binning
   {
      s_thresh = 1;
      y = local_decay;
      irf_idx = NULL;
   }

   if (data->global_mode == MODE_PIXELWISE)
   {
      y = local_decay;
   }

   projectors[thread].Fit(s_thresh, n_meas_res, lmax, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, 
                          data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);

   if (calculate_errs)
      projectors[thread].CalculateErrors(alf_local,conf_lim);

   for(int i=0; i<nl; i++)
      alf[i] = alf_local[i];

   // Normalise to get beta/gamma/r and I0
   //--------------------------------------

   lin_idx = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   lin_params += lin_idx;

   if (polarisation_resolved)
   {
      for(int i=0; i<s_thresh; i++)
      {
         I0 = lin_params[0];

         for(int j=1; j<n_r+1; j++)
            lin_params[j-1] = lin_params[j] / I0;

         lin_params[n_r] = I0;

         lin_params += lmax;
      }
   }
   else
   {
      int n_j = fit_fret ? n_fret_group : n_exp_phi;

      for(int i=0; i<s_thresh; i++)
      {
         I0 = 0;
         for(int j=0; j<n_j; j++)
            I0 += lin_params[j];

         if (n_j > 1)
         {
            for (int j=0; j<n_j; j++)
               lin_params[j] = lin_params[j] / I0;
            lin_params[n_j] = I0;
         }



         lin_params += lmax;
      }
   }

   ierr[r_idx] = ierr_local;

   status->FinishedRegion(thread);

   return 0;
}



   /* WEIGHTING FOR REFERENCE FITTNG
   projectors[thread].Fit(s_thresh, n_meas_res, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   
   double F0 = 0;
   for(i=0; i<l; i++)
      F0 = lin_params[i];

   
   for(i=0; i<n; i++)
   {
      w[i] *= w[i];
      w[i] = 1/w[i];
   }
   add_irf(thread, irf_idx[0], w, n_r, &F0);
   for(i=0; i<n; i++)
   {
      w[i] = sqrt(1/w[i]);
   }

   projectors[thread].Fit(s_thresh, n_meas_res, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   */
