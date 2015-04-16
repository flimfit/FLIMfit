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

/*===============================================
  ProcessRegion
  ===============================================*/

int FLIMGlobalFitController::ProcessRegion(int g, int region, int px, int thread)
{
   INIT_CONCURRENCY;

   int ierr_local = 0;

   _ASSERT( _CrtCheckMemory( ) );

   FitResultsRegion region_results;
   RegionData local_region_data;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Processing Data");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if (data->global_mode == MODE_PIXELWISE)
   {      
      local_region_data = region_data[0].GetPixel(px);
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
   if (local_region_data.GetSize() == 0 || status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;
   
   int itmax = 100;
   projectors[thread].Fit(local_region_data, region_results, itmax, status->iter[thread], ierr_local, status->chi2[thread]);
    
   if (calculate_errors)
   {
      projectors[thread].CalculateErrors(conf_interval);
      // TODO: get errors
   }
  
   status->FinishedRegion(thread);

   _ASSERT( _CrtCheckMemory( ) );

   return 0;
}


