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


int AbstractDecayGroup::getInitialVariables(double* variables)
{
   // TODO: needs work for betas etc where there is not a 1:1 relationship
   int idx = 0;
   for (auto& p : parameters)
   {
      if (p->IsFittedGlobally())
         variables[idx++] = p->initial_value;
   }

    return idx;
}

void AbstractDecayGroup::setIRFPosition(int irf_idx_, double t0_shift_, double reference_lifetime_)
{
   irf_idx = irf_idx_;
   t0_shift = t0_shift_;
   reference_lifetime = reference_lifetime_;
}

void AbstractDecayGroup::getNonlinearOutputParamNames(vector<string>& names)
{
   for (auto p : parameters)
      names.push_back(p->name);
}

void AbstractDecayGroup::setTransformedDataParameters(shared_ptr<TransformedDataParameters> dp_)
{
   dp = dp_;

   if (!dp) return;

   // Make sure all the channel factors are the right size
   size_t n_channel_factors = getNumPotentialChannels();
   for (int i = 0; i < n_channel_factors; i++)
   { 
      auto v = getChannelFactors(i);
      v.resize(dp->n_chan, 1.0);
      setChannelFactors(i, v);
   }
}

