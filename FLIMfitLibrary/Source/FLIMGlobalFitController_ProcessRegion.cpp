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
   INIT_CONCURRENCY;

   int i, j, s_thresh, itmax;
   double tau_ma;

   int ierr_local = 0;

   _ASSERT( _CrtCheckMemory( ) );

   int r_idx = data->GetRegionIndex(g,region);

   float  *local_decay     = this->local_decay + thread * n_meas;
/*
   double *alf_local       = this->alf_local + thread * nl * 3;
   double *err_lower_local = this->alf_local + thread * nl * 3 +   nl;
   double *err_upper_local = this->alf_local + thread * nl * 3 + 2*nl;
*/

   int start = data->GetRegionPos(g,region) + px;

   float* lin_params = this->lin_params + start * lmax;
   float* chi2       = this->chi2       + start;
   float* I          = this->I          + start;
   float* r_ss       = this->r_ss       + start;
   float* acceptor   = this->acceptor   + start;
   float* w_mean_tau = this->w_mean_tau + start;
   float* mean_tau   = this->mean_tau   + start;


   float *y, *alf, *alf_err_lower, *alf_err_upper;
   int   *irf_idx;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Processing Data");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if (data->global_mode == MODE_PIXELWISE)
   {
      y             = this->y             + px * n_meas;
      irf_idx       = this->irf_idx       + px;
      alf           = this->alf           + start * nl; 
      alf_err_lower = this->alf_err_lower + start * nl; 
      alf_err_upper = this->alf_err_upper + start * nl; 

      memcpy(local_decay,y,n_meas*sizeof(float));
      data->DetermineAutoSampling(thread, local_decay, nl+1);
      s_thresh = 1;
   }
   else
   {
      y             = this->y             + thread * y_dim * n_meas;
      irf_idx       = this->irf_idx       + thread * y_dim;
      alf           = this->alf           + nl * r_idx;
      alf_err_lower = this->alf_err_lower + nl * r_idx; 
      alf_err_upper = this->alf_err_upper + nl * r_idx; 

      s_thresh = data->GetRegionData(thread, g, region, 0, y, I, r_ss, acceptor, irf_idx, local_decay, n_omp_thread);
   }
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   int n_meas_res = data->GetResampleNumMeas(thread);

   // Check for termination requestion and that we have at least one px to fit
   //-------------------------------
   if (s_thresh == 0 || status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;
   


   itmax = 100;


   float* y_fit;
   int   s_fit;
   if (global_algorithm == MODE_GLOBAL_BINNING)
   {
      s_fit = 1;
      y_fit = local_decay;
   }
   else
   {
      s_fit = s_thresh;
      y_fit = y;
   }

   projectors[thread].Fit(s_fit, n_meas_res, lmax, y_fit, local_decay, irf_idx, lin_params, chi2, thread, itmax, 
                          photons_per_count, status->iter[thread], ierr_local, status->chi2[thread]);
   //TODO: get alf

   // If we're fitting globally using global binning now retrieve the linear parameters
   if (data->global_mode != MODE_PIXELWISE && global_algorithm == MODE_GLOBAL_BINNING)
      projectors[thread].GetLinearParams(s_thresh, y);
   
   if (calculate_errors)
   {

      projectors[thread].CalculateErrors(conf_interval);

      // TODO: get errors

      for(int i=0; i<nl; i++)
      {
         alf_err_lower[i] = (float) err_lower_local[i];
         alf_err_upper[i] = (float) err_upper_local[i];
      }
   }

   for(int i=0; i<nl; i++)
      alf[i] = (float) alf_local[i];

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Processing Results");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   // Normalise to get beta/gamma/r and I0 and determine mean lifetimes
   //--------------------------------------
   NormaliseLinearParams(s_thresh, lin_params, lin_params);
   CalculateMeanLifetime(s_thresh, lin_params, alf, mean_tau, w_mean_tau);

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
      success[r_idx] = (float) min(0, ierr_local);
   }
  
   status->FinishedRegion(thread);

   _ASSERT( _CrtCheckMemory( ) );

   return 0;
}



void FLIMGlobalFitController::CalculateMeanLifetime(int s, float lin_params[], float alf[], float mean_tau[], float w_mean_tau[])
{
   if (calculate_mean_lifetimes)
   {
      int lin_idx = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
      lin_params += lin_idx;

      #pragma omp parallel for
      for (int j=0; j<s; j++)
      {
         w_mean_tau[j] = 0;
         mean_tau[j]   = 0;

         for (int i=0; i<n_fix; i++)
         {
            w_mean_tau[j] += (float) (tau_guess[i] * tau_guess[i] * lin_params[i+lmax*j]);
            mean_tau[j]   += (float) (               tau_guess[i] * lin_params[i+lmax*j]);
         }

         for (int i=0; i<n_v; i++)
         {
            w_mean_tau[j] += (float) (alf[i] * alf[i] * lin_params[i+n_fix+lmax*j]);
            mean_tau[j]   += (float) (         alf[i] * lin_params[i+n_fix+lmax*j]); 
         }

         w_mean_tau[j] /= mean_tau[j];
      }
    
   }
}



void FLIMGlobalFitController::NormaliseLinearParams(int s, volatile float lin_params[], volatile float norm_params[])
{
   int n_stray = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   
   if (polarisation_resolved)
   {
      #pragma omp parallel for
      for(int i=0; i<s; i++)
      {
         volatile float* lin_local = lin_params + lmax * i;
         volatile float* norm_local = norm_params + lmax * i;

         for(int j=0; j<n_stray; j++)
            norm_local[j] = lin_local[j];

         lin_local  += n_stray;
         norm_local += n_stray;

         float I0 = lin_local[0];
         float r0 = 0;

         for(int j=1; j<n_r+1; j++)
         {
            norm_local[j] = lin_local[j] / I0;
            r0 += norm_local[j];
         }

         norm_local[0]     = r0;
         norm_local[n_r+1] = I0;

      }
   }
   else
   {
      int n_j = fit_fret ? n_fret_group : n_exp_phi;

      #pragma omp parallel for
      for(int i=0; i<s; i++)
      {
         volatile float* lin_local = lin_params + lmax * i;
         volatile float* norm_local = norm_params + lmax * i;

         for(int j=0; j<n_stray; j++)
            norm_local[j] = lin_local[j]; 

         lin_local  += n_stray;
         norm_local += n_stray;

         float I0 = 0;
         for(int j=0; j<n_j; j++)
            I0 += lin_local[j];

         if (n_j > 1)
         {
            for (int j=0; j<n_j; j++)
               norm_local[j] = lin_local[j] / I0;
            norm_local[n_j] = I0; 
         }

      }
   }
}

void FLIMGlobalFitController::DenormaliseLinearParams(int s, volatile float norm_params[], volatile float lin_params[])
{
   float I0;

   int n_stray = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   
   for(int i=0; i<n_stray; i++)
      lin_params[i] = norm_params[i]; 

   lin_params += n_stray;
   norm_params += n_stray;

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

