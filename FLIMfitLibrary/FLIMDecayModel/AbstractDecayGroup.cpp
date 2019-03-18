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

const char* FittingParameter::fitting_type_names[] = { "Fixed", "Fitted Locally", "Fitted Globally" };


int AbstractDecayGroup::getInitialVariables(std::vector<double>::iterator variables)
{
   int idx = 0;
   for (auto& p : parameters)
   {
      if (p->isFittedGlobally())
      {
         *(variables++) = p->getTransformedInitialValue();
         idx++;
      }
   }
   return idx;
}


std::vector<std::string> AbstractDecayGroup::getNonlinearOutputParamNames()
{
   std::vector<std::string> names;
   for (auto p : parameters)
      if (p->isFittedGlobally())
         names.push_back(p->name);
   return names;
}

void AbstractDecayGroup::setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp_)
{
   dp = dp_;

   if (dp)
      setNumChannels(dp->n_chan);
}

void AbstractDecayGroup::setNumChannels(int n_chan)
{
   // Make sure all the channel factors are the right size
   size_t n_channel_factors = getNumPotentialChannels();
   for (int i = 0; i < n_channel_factors; i++)
   { 
      auto v = getChannelFactors(i);
      if (v.empty())
         v.resize(n_chan, 1.0); // if no channels factors, set to 1's
      else
         v.resize(n_chan, 0.0); // if we're expanding, set others to 0's
      setChannelFactors(i, v);
   }
}

std::shared_ptr<FittingParameter> AbstractDecayGroup::getParameter(const std::string& param)
{
   for(auto& p : parameters)
      if (p->name == param)
         return p;

   throw std::runtime_error("Invalid parameter name");
}

void AbstractDecayGroup::normaliseChannelFactors(const std::vector<double>& channel_factors, std::vector<double>& norm_channel_factors)
{
   norm_channel_factors.resize(channel_factors.size());

   double factor_sum = 0;
   for (auto f : channel_factors)
      factor_sum += f;

   if (factor_sum == 0)
      throw std::runtime_error("Sum of channel factors was zero");

   for (int i = 0; i < channel_factors.size(); i++)
      norm_channel_factors[i] = channel_factors[i] / factor_sum;
}

void AbstractDecayGroup::init()
{
   last_parameters.resize(0);
   precompute_valid = false;

   init_();
}

int AbstractDecayGroup::setVariables(std::vector<double>::const_iterator variables)
{
   if (!last_parameters.empty())
   {
      bool variables_changed = false;
      for (int i = 0; i < last_parameters.size(); i++)
         variables_changed |= (last_parameters[i] != variables[i]);

      if (!variables_changed)
         return last_parameters.size();
   }

   precompute_valid = false;
   int n_variables = setVariables_(variables);

   last_parameters.resize(n_variables);
   std::copy_n(variables, n_variables, last_parameters.begin());
   return n_variables;
}

void AbstractDecayGroup::setIRFPosition(PixelIndex irf_idx_) 
{ 
   if (!dp->irf->arePositionsEquivalent(irf_idx_, irf_idx))
      precompute_valid = false;
   irf_idx = irf_idx_; 
}
void AbstractDecayGroup::setT0Shift(double t0_shift_) 
{ 
   if (t0_shift != t0_shift_)
      precompute_valid = false;
   t0_shift = t0_shift_;
}

void AbstractDecayGroup::setReferenceLifetime(double reference_lifetime_)
{ 
   if (reference_lifetime != reference_lifetime_)
      precompute_valid = false;
   reference_lifetime = reference_lifetime_; 
}

void AbstractDecayGroup::precompute()
{
   if (!precompute_valid)
      precompute_();
   precompute_valid = true;
}
