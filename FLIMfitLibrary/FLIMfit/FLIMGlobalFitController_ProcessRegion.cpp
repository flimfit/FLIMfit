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

#include "FitController.h"
#include "FLIMData.h"
#include "IRFConvolution.h"
#include "util.h"

#include <cmath>
#include <algorithm>

/*===============================================
  ProcessRegion
  ===============================================*/

void FitController::processRegion(int g, int region, int px, int thread)
{
   INIT_CONCURRENCY;

   int ierr_local = 0;

   FitResultsRegion region_results;
   std::shared_ptr<RegionData> local_region_data;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Processing Data");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if (data->global_scope == Pixelwise)
   {      
      local_region_data = region_data[0]->GetPixel(px);
      region_results = results->getPixel(g, region, px);
   }
   else
   {
      data->getRegionData(thread, g, region, region_data[thread], results, n_omp_thread);
      local_region_data = region_data[thread];

      region_results = results->getRegion(g, region);
   }
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   // Check for termination requestion and that we have at least one px to fit
   //-------------------------------
   if (local_region_data->GetSize() == 0 || reporter->shouldTerminate())
      return;
   
   int itmax = 100;
   int iter = 0; // used to use:status->iter[thread],
   double chi2 = 0; // used to use:
   
   fitters[thread]->fit(local_region_data, region_results, itmax, iter, ierr_local, chi2);
    
   if (calculate_errors)
   {
      fitters[thread]->calculateErrors(conf_interval);
      // TODO: get errors
   }
  
   n_fits_complete++;
   reporter->setProgress(static_cast<float>(n_fits_complete)/n_fits);
   
   return;
}


