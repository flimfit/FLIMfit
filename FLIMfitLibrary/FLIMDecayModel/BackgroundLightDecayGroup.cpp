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

#include "BackgroundLightDecayGroup.h"

#include <stdio.h>
#include <boost/lexical_cast.hpp>

using namespace std;

BackgroundLightDecayGroup::BackgroundLightDecayGroup() :
   AbstractDecayGroup("Background Contribution")
{
   n_lin_components = 0;
   n_nl_parameters = 0;

   std::vector<ParameterFittingType> any_type = { Fixed, FittedLocally }; // TODO support global fitting : , FittedGlobally};

   auto offset_param = make_shared<FittingParameter>("offset", 0, 1, any_type, Fixed);
   auto scatter_param = make_shared<FittingParameter>("scatter", 0, 1, any_type, Fixed);
   auto tvb_param = make_shared<FittingParameter>("tvb", 0, 1, any_type, Fixed);

   parameters.push_back(offset_param);
   parameters.push_back(scatter_param);
   parameters.push_back(tvb_param);

   channel_factor_names = { "Background" };
}

BackgroundLightDecayGroup::BackgroundLightDecayGroup(const BackgroundLightDecayGroup& obj) :
   AbstractDecayGroup(obj)
{
   parameters = obj.parameters;
}

void BackgroundLightDecayGroup::init()
{
   n_lin_components = 0;
   n_nl_parameters = 0;

   for (auto& p : parameters)
   {
      if (p->isFittedLocally())
         n_lin_components++;
      else if (p->isFittedGlobally())
         n_nl_parameters++;
   }

   channel_factors.resize(dp->n_chan, 1);
}

const std::vector<double>& BackgroundLightDecayGroup::getChannelFactors(int index)
{
   if (index == 0)
      return channel_factors;

   throw std::runtime_error("Bad channel factor index");
}

void BackgroundLightDecayGroup::setChannelFactors(int index, const std::vector<double>& channel_factors_)
{
   if (index == 0)
      channel_factors = channel_factors_;
   else
      throw std::runtime_error("Bad channel factor index");

}


int BackgroundLightDecayGroup::setVariables(const_double_iterator param_values)
{
   int idx = 0;

   if (parameters[0]->isFittedGlobally())
      offset = param_values[idx++];

   if (parameters[1]->isFittedGlobally())
      scatter = param_values[idx++];

   if (parameters[2]->isFittedGlobally())
      tvb = param_values[idx++];

   return idx;
}

void BackgroundLightDecayGroup::setupIncMatrix(std::vector<int>& inc, int& inc_row, int& inc_col)
{
   for (int i = 0; i < 3; i++)
   {
      if (parameters[i]->isFittedLocally())
         inc_col++;   
   }

   // TODO: setup LP1 column for global stray light
   /*
   for (int i = 0; i < 3; i++)
   {
      if (parameters[i]->isFittedGlobally())
      {
         inc[inc_row + inc_col * MAX_VARIABLES] = 1;
         inc_col++;
      }
   }
   */
}

int BackgroundLightDecayGroup::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx)
{
   int output_idx = 0;

   for (int i = 0; i < 3; i++)
      if (!(parameters[i]->isFittedLocally()))
         output[output_idx++] = parameters[i]->getValue<float>(nonlin_variables, nonlin_idx);

   return output_idx;
}

int BackgroundLightDecayGroup::getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx)
{
   int output_idx = 0;

   for (int i = 0; i < 3; i++)
      if (parameters[i]->isFittedLocally())
         output[output_idx++] = lin_variables[lin_idx++];

   return output_idx;
}


std::vector<std::string> BackgroundLightDecayGroup::getLinearOutputParamNames()
{
   std::vector<std::string> param_names;
   for (int i = 0; i < 3; i++)
      if (parameters[i]->isFittedLocally())
         param_names.push_back(names[i]);
   return param_names;
}

int BackgroundLightDecayGroup::calculateModel(double_iterator a, int adim, double& kap)
{
   // TODO: include bin shift

   int col = 0;
   
   col += addOffsetColumn(a + col*adim, adim, kap);
   col += addScatterColumn(a + col*adim, adim, kap);
   col += addTVBColumn(a + col*adim, adim, kap);
   
   return col;
}

int BackgroundLightDecayGroup::calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   
   col += addOffsetDerivatives(b + col*bdim, bdim, kap_derv[col]);
   col += addScatterDerivatives(b + col*bdim, bdim, kap_derv[col]);
   col += addTVBDerivatives(b + col*bdim, bdim, kap_derv[col]);

   return col;
}


void BackgroundLightDecayGroup::addConstantContribution(float_iterator a)
{
   float offset_adj = parameters[0]->isFixed() ? (float) parameters[0]->initial_value : 0.0f;
   float scatter_adj = parameters[1]->isFixed() ? (float) parameters[0]->initial_value : 0.0f;
   float tvb_adj = parameters[2]->isFixed() ? (float) parameters[0]->initial_value : 0.0f;
   
   if (scatter_adj != 0.0f)
      addIRF(irf_buf.begin(), 0, 0, a, channel_factors, scatter_adj); // TODO : irf_shift?

   for (int i = 0; i < dp->n_meas; i++)
      a[i] += offset_adj;

   if (!dp->tvb_profile.empty() && tvb_adj != 0.0f)
   {
      for (int i = 0; i < dp->n_meas; i++)
         a[i] += (float)(dp->tvb_profile[i] * tvb_adj);
   }
}

/*
Add a constant offset component to the matrix
*/
int BackgroundLightDecayGroup::addOffsetColumn(double_iterator a, int adim, double& kap)
{
   // set constant phi value for offset
   if (parameters[0]->isFittedLocally())
   {
      for (int k = 0; k<dp->n_meas; k++)
            a[k] = 1;

      return 1;
   }

   return 0;
}

/*
Add a Scatter (IRF) component to the matrix
Use the current IRF
*/
int BackgroundLightDecayGroup::addScatterColumn(double_iterator a, int adim, double& kap)
{
   // set constant phi value for scatterer
   if (parameters[1]->isFittedLocally())
   {
      std::fill_n(a, adim, 0);
      
      double scale_factor[2] = { 1.0, 0.0 };
      addIRF(irf_buf.begin(), irf_idx, t0_shift, a, channel_factors);
      
      return 1;
   }

   return 0;
}

/*
Add a TVB component to the matrix
*/
int BackgroundLightDecayGroup::addTVBColumn(double_iterator a, int adim, double& kap)
{
   if (parameters[1]->isFittedLocally() && !dp->tvb_profile.empty())
   {
      for (int k = 0; k<dp->n_meas; k++)
            a[k] += dp->tvb_profile[k];
      
      return 1;
   }

   return 0;
}

int BackgroundLightDecayGroup::addGlobalBackgroundLightColumn(double_iterator a, int adim, double& kap)
{
   // Set L+1 phi value (without associated beta), to include global offset/scatter

   std::fill_n(a, adim, 0);

   // Add scatter
   if (parameters[1]->isFittedGlobally())
   {
      double scale_factor[2] = { 1.0, 0.0 };
      addIRF(irf_buf.begin(), irf_idx, t0_shift, a, channel_factors);
      for (int i = 0; i<dp->n_meas; i++)
         a[i] *= scatter;
   }

   // Add offset
   if (parameters[0]->isFittedGlobally())
   {
      for (int k = 0; k<dp->n_meas; k++)
         a[k] += offset;
   }

   // Add tvb
   if (parameters[2]->isFittedGlobally() && !dp->tvb_profile.empty())
   {
      for (int k = 0; k<dp->n_meas; k++)
            a[k] += dp->tvb_profile[k] * tvb;
   }

   return 1;
}


int BackgroundLightDecayGroup::addOffsetDerivatives(double_iterator b, int bdim, double& kap_derv)
{
   // Set derivatives for offset 
   if (parameters[0]->isFittedGlobally())
   {
      for (int i = 0; i<dp->n_meas; i++)
         b[i] = 1;

      return 1;
   }

   return 0;
}

int BackgroundLightDecayGroup::addScatterDerivatives(double_iterator b, int bdim, double& kap_derv)
{
   // Set derivatives for scatter 
   if (parameters[1]->isFittedGlobally())
   {
      std::fill_n(b, bdim, 0);

      double scale_factor[2] = { 1.0, 0.0 };
      addIRF(irf_buf.begin(), irf_idx, t0_shift, b, channel_factors);

      return 1;
   }

   return 0;
}

int BackgroundLightDecayGroup::addTVBDerivatives(double_iterator b, int bdim, double& kap_derv)
{
   // Set derivatives for tvb 
   if (parameters[2]->isFittedGlobally())
   {
      for (int i = 0; i<dp->n_meas; i++)
         b[i] += dp->tvb_profile[i];

      return 1;
   }

   return 0;
}
