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

/*
   float  *local_decay     = this->local_decay + thread * n_meas;
   double *alf_local       = this->alf_local + thread * nl * 3;
   double *err_lower_local = this->alf_local + thread * nl * 3 +   nl;
   double *err_upper_local = this->alf_local + thread * nl * 3 + 2*nl;
*/

   int start = data->GetRegionPos(g,region) + px;
/*
   float* lin_params = this->lin_params + start * lmax;
   float* chi2       = this->chi2       + start;
   float* I          = this->I          + start;
   float* r_ss       = this->r_ss       + start;
   float* acceptor   = this->acceptor   + start;
   float* w_mean_tau = this->w_mean_tau + start;
   float* mean_tau   = this->mean_tau   + start;
   */

   float *y, *alf, *alf_err_lower, *alf_err_upper;
   int   *irf_idx;

   FitResultsRegion region_results;
   RegionData local_region_data;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Processing Data");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if (data->global_mode == MODE_PIXELWISE)
   {
      // TODO: Get sub region (??)
      
      s_thresh = 1;

      local_region_data = region_data[thread].GetPixel(px);

      region_results = results->GetPixel(g, region, px);
   }
   else
   {


      data->GetRegionData(thread, g, region, region_data[thread], *results, n_omp_thread);
      local_region_data = region_data[thread];

      region_results = results->GetRegion(g, region);
   }
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   // Check for termination requestion and that we have at least one px to fit
   //-------------------------------
   if (s_thresh == 0 || status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;
   


   itmax = 100;


   if (global_algorithm == MODE_GLOBAL_BINNING)
      local_region_data = local_region_data.GetBinnedRegion();

   // TODO: propogate n_meas_res through region data.... or just remove autoresampling?

   projectors[thread].Fit(local_region_data, region_results, thread, itmax, status->iter[thread], ierr_local, status->chi2[thread]);
   //TODO: get alf

   // If we're fitting globally using global binning now retrieve the linear parameters
   if (data->global_mode != MODE_PIXELWISE && global_algorithm == MODE_GLOBAL_BINNING)
      projectors[thread].GetLinearParams(region_data[thread]);
   
   if (calculate_errors)
   {

      projectors[thread].CalculateErrors(conf_interval);

      // TODO: get errors
   }

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Processing Results");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   // Normalise to get beta/gamma/r and I0 and determine mean lifetimes
   //--------------------------------------
   //NormaliseLinearParams(s_thresh, lin_params, lin_params);
   //CalculateMeanLifetime(s_thresh, lin_params, alf, mean_tau, w_mean_tau);

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


