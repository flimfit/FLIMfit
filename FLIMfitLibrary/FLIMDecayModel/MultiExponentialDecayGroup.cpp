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

#include "MultiExponentialDecayGroup.h"
#include "ParameterConstraints.h"
#include "FittingParameter.h"
#include <boost/lexical_cast.hpp>

MultiExponentialDecayGroup::MultiExponentialDecayGroup(int n_exponential, bool contributions_global, const QString& name) :
   MultiExponentialDecayGroupPrivate(n_exponential, contributions_global, name)
{
   setupParameters();
}


MultiExponentialDecayGroup::MultiExponentialDecayGroup(const MultiExponentialDecayGroup& obj) :
   MultiExponentialDecayGroupPrivate(obj)
{
   fit_channel_factors = obj.fit_channel_factors;
   channel_factor_parameters = obj.channel_factor_parameters;
   n_chan = obj.n_chan;

   setupParameters();
   init();
}


void MultiExponentialDecayGroup::init_()
{
   MultiExponentialDecayGroupPrivate::init_();
   if (fit_channel_factors)
   {
      norm_channel_factors = channel_factors; // we don't normalise in this case
      for (auto& p : channel_factor_parameters)
         n_nl_parameters += p->isFittedGlobally();
   }
}

void MultiExponentialDecayGroup::setNumChannels(int n_chan_)
{
   n_chan = n_chan_;
   AbstractDecayGroup::setNumChannels(n_chan);
   setupParameters();
}


void MultiExponentialDecayGroup::setupParameters()
{
   setupParametersMultiExponential();

   if (fit_channel_factors)
   {
      channel_factor_parameters.resize(n_chan-1);
      std::vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };
      for (int i = 0; i < channel_factor_parameters.size(); i++)
      {
         if (!channel_factor_parameters[i])
         {
            std::string name = "ch_" + boost::lexical_cast<std::string>(i + 1);
            channel_factor_parameters[i] = std::make_shared<FittingParameter>(name, channel_factors[i+1], 0, 1, 1, fixed_or_global, FittedGlobally);            
         }
      }
   }

   for (auto& p : channel_factor_parameters)
      parameters.push_back(p);

   parametersChanged();
}

int MultiExponentialDecayGroup::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx)
{
   int output_idx = MultiExponentialDecayGroupPrivate::getNonlinearOutputs(nonlin_variables, output, nonlin_idx);

   for(auto& p : channel_factor_parameters)
      output[output_idx++] = p->getValue<float>(nonlin_variables, nonlin_idx);

   return output_idx;
}

void MultiExponentialDecayGroup::setupIncMatrix(std::vector<int>& inc, int& row, int& col)
{
   MultiExponentialDecayGroupPrivate::setupIncMatrix(inc, row, col);

   if (fit_channel_factors)
   {
      for(auto& p : channel_factor_parameters)
         if (p->isFittedGlobally())
         {
            for (int i = 0; i < col; i++)
               inc[row + i * MAX_VARIABLES] = 1;
            row++;
         }
   }
}

int MultiExponentialDecayGroup::setVariables_(std::vector<double>::const_iterator param_values)
{
   int idx = MultiExponentialDecayGroupPrivate::setVariables_(param_values);

   if (fit_channel_factors)
   {
      int ch = 1;
      for (auto& p : channel_factor_parameters)
         norm_channel_factors[ch++] = p->getValue<double>(param_values, idx);
   }
   return idx;
}

void MultiExponentialDecayGroup::setFitChannelFactors(bool fit_channel_factors_)
{
   fit_channel_factors = fit_channel_factors_;
   setupParameters();
}

int MultiExponentialDecayGroup::calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int idx = MultiExponentialDecayGroupPrivate::calculateDerivatives(b, bdim, kap_derv);

   if (fit_channel_factors)
   {
      double kap = 0;
      std::vector<double> diff_factors(dp->n_chan);
      for (int i = 0; i < channel_factor_parameters.size(); i++)
         if (channel_factor_parameters[i]->isFittedGlobally())
         {
            diff_factors[i] = 0;
            diff_factors[i + 1] = 1;

            int sz = contributions_global ? 1 : n_exponential;
            idx += addDecayGroup(buffer, 1, b + idx * bdim, bdim, kap, diff_factors);
         }
   }
   return idx;
}
