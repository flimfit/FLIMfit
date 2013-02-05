//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================

#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "IRFConvolution.h"
#include "util.h"

#include <cmath>
#include <algorithm>

using namespace std;

/*===============================================
  ProcessRegion
  ===============================================*/

int FLIMGlobalFitController::ProcessRegion(int g, int region, int px, int thread)
{
   int i, j, s_thresh, itmax;
   double ref = 0;
   double tau_ma;

   int ierr_local = 0;

    #ifdef _WINDOWS
      _ASSERT( _CrtCheckMemory( ) );
    #endif

   int r_idx = data->GetRegionIndex(g,region);

   float  *local_decay   = this->local_decay + thread * n_meas;
   float  *w             = this->w + thread * n_meas;

   double *alf_local     = this->alf_local + thread * nl;
   float  *lin_local     = this->lin_local + thread * l;

   int start = data->GetRegionPos(g,region) + px;

   float* lin_params = this->lin_params + start * lmax;
   float* chi2       = this->chi2       + start;
   float* I          = this->I          + start;
   float* r_ss       = this->r_ss       + start;
   float* acceptor   = this->acceptor   + start;
   float* w_mean_tau = this->w_mean_tau + start;
   float* mean_tau   = this->mean_tau   + start;


   float *y, *alf;
   int   *irf_idx;

   if (data->global_mode == MODE_PIXELWISE)
   {
      y       = this->y;
      irf_idx = this->irf_idx + px;
      alf     = this->alf + start * nl; 

      s_thresh = data->GetRegionData(thread, g, region, px, global_algorithm == MODE_GLOBAL_BINNING, adjust_buf, y, NULL, NULL, NULL, w, irf_idx, local_decay);
      data->DetermineAutoSampling(thread, local_decay, nl+1);
   }
   else
   {
      y       = this->y       + thread * s * n_meas;
      irf_idx = this->irf_idx + thread * s;
      alf     = this->alf     + nl * r_idx;
   
      s_thresh = data->GetRegionData(thread, g, region, 0, global_algorithm == MODE_GLOBAL_BINNING, adjust_buf, y, I, r_ss, acceptor, w, irf_idx, local_decay);
   }


   int n_meas_res = data->GetResampleNumMeas(thread);

   // Check for termination requestion and that we have at least one px to fit
   //-------------------------------
   if (s_thresh == 0 || status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;

   // Estimate lifetime from mean arrival time if requested
   //------------------------------
   if (estimate_initial_tau)
   {
      tau_ma = EstimateAverageLifetime(local_decay, 0);

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

   if(fit_beta == FIT_GLOBALLY)
      for(int j=0; j<n_exp-1; j++)
         if (decay_group_buf[j+1] == decay_group_buf[j])
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



   if (data->global_mode == MODE_PIXELWISE)
   {
      y = local_decay;
   }

   projectors[thread].Fit(s_thresh, n_meas_res, lmax, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, 
                          data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   
   //if (global_algorithm == MODE_GLOBAL_BINNING)
   //{
   //   projectors.GetLinearParams(s_thresh, y, alf_local, lin_params)
   //}
   
   if (calculate_errs)
      projectors[thread].CalculateErrors(alf_local,conf_lim);

   for(int i=0; i<nl; i++)
      alf[i] = (float) alf_local[i];

   // Normalise to get beta/gamma/r and I0
   //--------------------------------------
   NormaliseLinearParams(s_thresh,lin_params,lin_params);
  
   CalculateMeanLifetime(s_thresh, lin_params, alf, mean_tau, w_mean_tau);

   if (data->global_mode == MODE_PIXELWISE)
   {
      if (ierr_local >= 0)
      {
         success[r_idx] += 1;
         ierr[r_idx] += ierr_local;
      }
   }
   else
   {
      ierr[r_idx] = ierr_local;
      success[r_idx] = (float) minn(0, ierr_local);
   }
  
   status->FinishedRegion(thread);

   //_ASSERT( _CrtCheckMemory( ) );

   return 0;
}



void FLIMGlobalFitController::CalculateMeanLifetime(int s, float lin_params[], float alf[], float mean_tau[], float w_mean_tau[])
{
   int lin_idx = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   lin_params += lin_idx;

   if (calculate_mean_lifetimes)
   {
      for (int j=0; j<s; j++)
      {
         w_mean_tau[j] = 0;
         mean_tau[j]   = 0;
      }

      for (int i=0; i<n_fix; i++)
         for (int j=0; j<s; j++)
         {
            w_mean_tau[j] += (float) (tau_guess[i] * tau_guess[i] * lin_params[i+lmax*j]);
            mean_tau[j]   += (float) (               tau_guess[i] * lin_params[i+lmax*j]); 
         }

      for (int i=0; i<n_v; i++)
         for (int j=0; j<s; j++)
         {
            w_mean_tau[j] += (float) (alf[i] * alf[i] * lin_params[i+n_fix+lmax*j]);
            mean_tau[j]   += (float) (         alf[i] * lin_params[i+n_fix+lmax*j]); 
         }
     
      for (int j=0; j<s; j++)
         w_mean_tau[j] /= mean_tau[j];

   }
}



void FLIMGlobalFitController::NormaliseLinearParams(int s, volatile float lin_params[], volatile float norm_params[])
{
   float I0, r0;

   int lin_idx = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   lin_params += lin_idx;
   norm_params += lin_idx;

   if (polarisation_resolved)
   {
      for(int i=0; i<s; i++)
      {
         I0 = lin_params[0];
         r0 = 0;


         for(int j=1; j<n_r+1; j++)
         {
            norm_params[j] = lin_params[j] / I0;
            r0 += norm_params[j];
         }

         norm_params[0]     = r0;
         norm_params[n_r+1] = I0;

         norm_params += lmax;
         lin_params  += lmax;
      }
   }
   else
   {
      int n_j = fit_fret ? n_fret_group : n_exp_phi;

      for(int i=0; i<s; i++)
      {
         I0 = 0;
         for(int j=0; j<n_j; j++)
            I0 += lin_params[j];

         if (n_j > 1)
         {
            for (int j=0; j<n_j; j++)
               norm_params[j] = lin_params[j] / I0;
            norm_params[n_j] = I0;
         }

         lin_params += lmax;
         norm_params += lmax;
      }
   }
}

void FLIMGlobalFitController::DenormaliseLinearParams(int s, volatile float norm_params[], volatile float lin_params[])
{
   float I0;

   int lin_idx = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   
   for(int i=0; i<lin_idx; i++)
      lin_params[i] = norm_params[i];

   lin_params += lin_idx;
   norm_params += lin_idx;

   if (polarisation_resolved)
   {
      for(int i=0; i<s; i++)
      {
         I0 = norm_params[n_r+1];

         lin_params[0] = I0;
         
         for(int j=1; j<n_r+1; j++)
            lin_params[j] = norm_params[j] * I0;

         
         norm_params += lmax;
         lin_params += lmax;
      }
   }
   else
   {
      int n_j = fit_fret ? n_fret_group : n_exp_phi;

      for(int i=0; i<s; i++)
      {
         I0 = norm_params[n_j];

         if (n_j > 1)
            for (int j=0; j<n_j; j++)
               lin_params[j] = norm_params[j] * I0;
         else
            lin_params[0] = norm_params[0];
             
         lin_params += lmax;
         norm_params += lmax;
      }
   }
}

