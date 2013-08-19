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
   model(model), data(data), calculate_errors(calculate_errors)
{
   n_px = data->n_masked_px;
   lmax = model->lmax;
   nl   = model->nl;

   pixelwise = (data->global_mode == MODE_PIXELWISE);

   GetParamNames();

   int alf_size;
   
   if (pixelwise)
      alf_size = n_px;
   else
      alf_size = data->n_regions_total;
   alf_size *= nl;

   int lin_size = n_px * lmax;

   n_aux = data->GetNumAuxillary();
   int aux_size = n_aux * n_px;


   lin_params   = new float[ lin_size ]; //ok
   chi2         = new float[ n_px ]; //ok
   aux_data     = new float[ aux_size ];

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

   SetNaN(alf,        alf_size );
   SetNaN(lin_params, lin_size );
   SetNaN(chi2,       n_px );
   SetNaN(aux_data,   aux_size );
   
   for(int i=0; i<data->n_regions_total; i++)
   {
      success[i] = 0;
      ierr[i] = 0;
   }

}

FitResults::~FitResults()
{
   ClearVariable(chi2);
   ClearVariable(alf);
   ClearVariable(alf_err_lower);
   ClearVariable(alf_err_upper);
   ClearVariable(lin_params);
   ClearVariable(ierr);
   ClearVariable(success);
}

const FitResultsRegion FitResults::GetRegion(int image, int region)
{
   return FitResultsRegion(this, image, region);
}

const FitResultsRegion FitResults::GetPixel(int image, int region, int pixel)
{
   return FitResultsRegion(this, image, region, pixel);
}


void FitResults::GetNonLinearParams(int image, int region, int pixel, vector<double>& params)
{
   int idx;
   if (pixelwise)
      idx = data->GetRegionPos(image, region) + pixel;
   else
      idx = data->GetRegionIndex(image, region);

   float* alf_local = alf + idx * nl; 

   params.reserve(nl);

   for(int i=0; i<nl; i++)
      params[i] = alf_local[i];
}

void FitResults::GetLinearParams(int image, int region, int pixel, vector<float>& params)
{
   int start = data->GetRegionPos(image, region) + pixel;
   float* lin_local = lin_params + start * lmax;

   params.reserve(lmax);
   DenormaliseLinearParams(lin_local, &params[0]);
}


float* FitResults::GetAuxDataPtr(int image, int region)
{
   int pos =  data->GetRegionPos(image,region);
   return aux_data + pos * n_aux;
}

void FitResults::GetPointers(int image, int region, int pixel, float*& non_linear_params, float*& linear_params, float*& chi2)
{

   int start = data->GetRegionPos(image, region) + pixel;

   int idx;
   if (pixelwise)
      idx = start;
   else
      idx = data->GetRegionIndex(image, region);

   non_linear_params = alf        + idx   * nl;
   linear_params     = lin_params + start * lmax;
   chi2              = this->chi2 + start;

}

void FitResults::SetFitStatus(int image, int region, int code)
{
   int r_idx = data->GetRegionIndex(image, region);

   if (pixelwise)
   {
      if (code >= 0)
      {
         success[r_idx] += 1;
         ierr[r_idx] += code;
      }
   }
   else
   {
      ierr[r_idx] = code;
      success[r_idx] = (float) min(0, code);
   }

}
/*
void FitResults::FitFinished(int image, int region, int pixel)
{

}

void FitResults::FitFinished(int image, int region)
{
   
}
*/

void FitResults::NormaliseLinearParams(volatile float lin_params[], volatile float norm_params[])
{
   #pragma omp parallel for
   for(int i=0; i<n_px; i++)
   {
      volatile float* lin_local = lin_params + lmax * i;
      volatile float* norm_local = norm_params + lmax * i;

      model->NormaliseLinearParams(lin_local, norm_local);
   }
}

void FitResults::DenormaliseLinearParams(volatile float norm_params[], volatile float lin_params[])
{
   #pragma omp parallel for
   for(int i=0; i<n_px; i++)
   {
      volatile float* lin_local = lin_params + lmax * i;
      volatile float* norm_local = norm_params + lmax * i;

      model->DenormaliseLinearParams(norm_local, lin_local);
   }
}

void FitResults::GetParamNames()
{
   model->GetOutputParamNames(param_names, n_nl_output_params);
   data->GetAuxParamNames(param_names);

   n_output_params = (int) param_names.size();

   param_names_ptr = new const char*[n_output_params];

   for(int i=0; i<n_output_params; i++)
      param_names_ptr[i] = param_names[i].c_str();
}




void FitResultsRegion::GetPointers(float*& linear_params, float*& non_linear_params, float*& chi2)
{
   results->GetPointers(image, region, pixel, non_linear_params, linear_params, chi2);
}

void FitResultsRegion::SetFitStatus(int code)
{
   results->SetFitStatus(image, region, code);
}
