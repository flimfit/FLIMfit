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

#include "FitResults.h"
#include "FLIMData.h"
#include "util.h"

FitResults::FitResults(FitModel* model, FLIMData* data, int calculate_errors) :
   data(data), calculate_errors(calculate_errors)
{
   n_px = data->n_masked_px;
   lmax = model->lmax;

   int alf_size = (data->global_mode == MODE_PIXELWISE) ? data->n_masked_px : data->n_regions_total;
   alf_size *= model->nl;

   int lin_size = n_px * lmax;

   try
   {
      lin_params   = new float[ lin_size ]; //ok
      chi2         = new float[ n_px ]; //ok
      I            = new float[ n_px ];

      if (model->polarisation_resolved)
         r_ss      = new float[ n_px ];

      if (data->has_acceptor)
         acceptor  = new float[ n_px ];

      ierr         = new int[ n_px ];
      success      = new float[ n_px ];
      alf          = new float[ alf_size ]; //ok

      if (calculate_errors)
      {
         alf_err_lower = new float[ alf_size ];
         alf_err_upper = new float[ alf_size ];
      }
      else
      {
         alf_err_lower = NULL;
         alf_err_upper = NULL;
      }
      
      if (calculate_mean_lifetimes)
      {
         w_mean_tau   = new float[ n_px ];  
         mean_tau     = new float[ n_px ];  
      }
   }
   catch(std::exception e)
   {
      //error =  ERR_OUT_OF_MEMORY;
      //CleanupResults();
      //return;
   }

   SetNaN(alf,        alf_size );
   SetNaN(lin_params, lin_size );
   SetNaN(chi2,       n_px );
   SetNaN(I,          n_px );
   SetNaN(r_ss,       n_px );
   
   for(int i=0; i<data->n_regions_total; i++)
   {
      success[i] = 0;
      ierr[i] = 0;
   }



}

const FitResultsRegion FitResults::GetRegion(int image, int region)
{
   return FitResultsRegion(this, image, region);
}

const FitResultsRegion FitResults::GetPixel(int image, int region, int pixel)
{
   return FitResultsRegion(this, image, region, pixel);
}


void FitResults::GetAssociatedResults(int image, int region, float*& I_, float*& r_ss_, float*& acceptor_)
{
   int pos =  data->GetRegionPos(image,region);

   I_       = I        + pos;
   r_ss_    = r_ss     + pos;
   acceptor = acceptor + pos;
}




void FitResults::CalculateMeanLifetime()
{
   if (calculate_mean_lifetimes)
   {
      int lin_idx = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
      lin_params += lin_idx;

      #pragma omp parallel for
      for (int j=0; j<n_px; j++)
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




FitResults::~FitResults()
{
   ClearVariable(I);
   ClearVariable(chi2);
   ClearVariable(alf);
   ClearVariable(alf_err_lower);
   ClearVariable(alf_err_upper);
   ClearVariable(lin_params);
   ClearVariable(ierr);
   ClearVariable(success);
   ClearVariable(w_mean_tau);
   ClearVariable(mean_tau);
   ClearVariable(r_ss);
   ClearVariable(acceptor);
}