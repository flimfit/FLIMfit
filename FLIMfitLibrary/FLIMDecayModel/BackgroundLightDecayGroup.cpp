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

#include "AbstractDecayGroup.h"

#include <stdio.h>
#include <boost/lexical_cast.hpp>

using namespace std;

BackgroundLightDecayGroup::BackgroundLightDecayGroup(shared_ptr<AcquisitionParameters> acq) :
   AbstractDecayGroup(acq),
   names({ "offset", "scatter", "tvb" })
{
   n_lin_components = 0;
   n_nl_parameters = 0;

   vector<ParameterFittingType> any_type = { Fixed, FittedLocally, FittedGlobally };

   auto offset_param = make_shared<FittingParameter>("offset", 0, any_type, FittedGlobally);
   auto scatter_param = make_shared<FittingParameter>("offset", 0, any_type, FittedGlobally);
   auto tvb_param = make_shared<FittingParameter>("offset", 0, any_type, FittedGlobally);

   parameters.push_back(offset_param);
   parameters.push_back(scatter_param);
   parameters.push_back(tvb_param);
}

int BackgroundLightDecayGroup::SetVariables(const double* param_values)
{
   int idx = 0;

   if (parameters[0]->IsFittedGlobally())
      offset = param_values[idx++];

   if (parameters[1]->IsFittedGlobally())
      scatter = param_values[idx++];

   if (parameters[2]->IsFittedGlobally())
      tvb = param_values[idx++];

   return idx;
}

int BackgroundLightDecayGroup::SetupIncMatrix(int* inc, int& inc_row, int& inc_col)
{
   for (int i = 0; i < 3; i++)
   {
      if (parameters[i]->IsFittedLocally())
         inc_col++;   
   }

   // TODO: setup LP1 column for global stray light
   /*
   for (int i = 0; i < 3; i++)
   {
      if (parameters[i]->IsFittedGlobally())
      {
         inc[inc_row + inc_col * 12] = 1;
         inc_col++;
      }
   }
   */
   return 0;
}

int BackgroundLightDecayGroup::GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx)
{
   int output_idx = 0;

   for (int i = 0; i < 3; i++)
      if (parameters[i]->IsFittedGlobally())
         output[output_idx++] = nonlin_variables[nonlin_idx++];

   return output_idx;
}

int BackgroundLightDecayGroup::GetLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   int output_idx = 0;

   for (int i = 0; i < 3; i++)
      if (parameters[i]->IsFittedLocally())
         output[output_idx++] = lin_variables[lin_idx++];

   return output_idx;
}


void BackgroundLightDecayGroup::GetLinearOutputParamNames(vector<string>& names)
{
   for (int i = 0; i < 3; i++)
      if (parameters[i]->IsFittedGlobally())
         names.push_back(names[i]);
}


void BackgroundLightDecayGroup::AddConstantContribution(float* a)
{
   float offset_adj = parameters[0]->IsFixed() ? (float) parameters[0]->initial_value : 0.0f;
   float scatter_adj = parameters[1]->IsFixed() ? (float) parameters[0]->initial_value : 0.0f;
   float tvb_adj = parameters[2]->IsFixed() ? (float) parameters[0]->initial_value : 0.0f;
   
   double scale_fact[2] = { 1, 0 };

   AddIRF(irf_buf.data(), 0, 0, a, channel_factors, scale_fact); // TODO : irf_shift?
   
   for (int i = 0; i < acq->n_meas; i++)
      a[i] = a[i] * scatter_adj + offset_adj;

   if (!acq->tvb_profile.empty())
   {
      for (int i = 0; i < acq->n_meas; i++)
         a[i] += (float)(acq->tvb_profile[i] * tvb_adj);
   }
}

/*
Add a constant offset component to the matrix
*/
int BackgroundLightDecayGroup::AddOffsetColumn(double* a, int adim, vector<double>& kap)
{
   // set constant phi value for offset
   if (parameters[0]->fitting_type == FittedLocally)
   {
      for (int k = 0; k<acq->n_meas; k++)
            a[k] = 1;

      return 1;
   }

   return 0;
}

/*
Add a Scatter (IRF) component to the matrix
Use the current IRF
*/
int BackgroundLightDecayGroup::AddScatterColumn(double* a, int adim, vector<double>& kap)
{
   // set constant phi value for scatterer
   if (parameters[1]->fitting_type == FittedLocally)
   {
      memset(a, 0, adim*sizeof(*a));
      
      double scale_factor[2] = { 1.0, 0.0 };
      AddIRF(irf_buf.data(), irf_idx, t0_shift, a, channel_factors, scale_factor);
      
      return 1;
   }

   return 0;
}

/*
Add a TVB component to the matrix
*/
int BackgroundLightDecayGroup::AddTVBColumn(double* a, int adim, vector<double>& kap)
{
   if (parameters[1]->fitting_type == FittedLocally)
   {
      for (int k = 0; k<acq->n_meas; k++)
            a[k] += acq->tvb_profile[k];
      
      return 1;
   }

   return 0;
}

int BackgroundLightDecayGroup::AddGlobalBackgroundLightColumn(double* a, int adim, vector<double>& kap)
{
   // Set L+1 phi value (without associated beta), to include global offset/scatter

   memset(a, 0, adim*sizeof(*a));

   // Add scatter
   if (parameters[1]->IsFittedGlobally())
   {
      double scale_factor[2] = { 1.0, 0.0 };
      AddIRF(irf_buf.data(), irf_idx, t0_shift, a, channel_factors, scale_factor);
      for (int i = 0; i<acq->n_meas; i++)
         a[i] *= scatter;
   }

   // Add offset
   if (parameters[0]->IsFittedGlobally())
   {
      for (int k = 0; k<acq->n_meas; k++)
         a[k] += offset;
   }

   // Add tvb
   if (parameters[2]->IsFittedGlobally())
   {
      for (int k = 0; k<acq->n_meas; k++)
            a[k] += acq->tvb_profile[k] * tvb;
   }

   return 1;
}


int BackgroundLightDecayGroup::AddOffsetDerivatives(double* b, int bdim, vector<double>& kap)
{
   // Set derivatives for offset 
   if (parameters[0]->IsFittedGlobally())
   {
      for (int i = 0; i<acq->n_meas; i++)
         b[i] = 1;

      return 1;
   }

   return 0;
}

int BackgroundLightDecayGroup::AddScatterDerivatives(double* b, int bdim, vector<double>& kap)
{
   // Set derivatives for scatter 
   if (parameters[1]->IsFittedGlobally())
   {
      memset(b, 0, sizeof(*b)*bdim);

      double scale_factor[2] = { 1.0, 0.0 };
      AddIRF(irf_buf.data(), irf_idx, t0_shift, b, channel_factors, scale_factor);

      return 1;
   }

   return 0;
}

int BackgroundLightDecayGroup::AddTVBDerivatives(double b[], int bdim, vector<double>& kap)
{
   // Set derivatives for tvb 
   if (parameters[2]->IsFittedGlobally())
   {
      for (int i = 0; i<acq->n_meas; i++)
         b[i] += acq->tvb_profile[i];

      return 1;
   }

   return 0;
}
