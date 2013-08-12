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
#include "util.h"

FitResults::FitResults(FitModel* model, FLIMData* data, int calculate_errors) :
   data(data), calculate_errors(calculate_errors)
{
   int alf_size = (data->global_mode == MODE_PIXELWISE) ? data->n_masked_px : data->n_regions_total;
   alf_size *= model->nl;

   int lin_size = data->n_masked_px * model->lmax;

   try
   {
      lin_params   = new float[ lin_size ]; //ok
      chi2         = new float[ data->n_masked_px ]; //ok
      I            = new float[ data->n_masked_px ];

      if (model->polarisation_resolved)
         r_ss      = new float[ data->n_masked_px ];

      if (data->has_acceptor)
         acceptor  = new float[ data->n_masked_px ];

      ierr         = new int[ data->n_regions_total ];
      success      = new float[ data->n_regions_total ];
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
         w_mean_tau   = new float[ data->n_masked_px ];  
         mean_tau     = new float[ data->n_masked_px ];  
      }
   }
   catch(std::exception e)
   {
      //error =  ERR_OUT_OF_MEMORY;
      //CleanupResults();
      //return;
   }

   SetNaN(alf, alf_size );
   SetNaN(chi2, data->n_masked_px );
   SetNaN(I, data->n_masked_px );
   SetNaN(r_ss, data->n_masked_px );
   SetNaN(lin_params, lin_size);

   for(int i=0; i<data->n_regions_total; i++)
   {
      success[i] = 0;
      ierr[i] = 0;
   }



}

void FitResults::GetAssociatedResults(int im, float*& r, float*& I_, float*& r_ss_, float*& acceptor_)
{
   int pos =  data->GetRegionPos(im,r);

   I_       = I        + pos;
   r_ss_    = r_ss     + pos;
   acceptor = acceptor + pos;
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