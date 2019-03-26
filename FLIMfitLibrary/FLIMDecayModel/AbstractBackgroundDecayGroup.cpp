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

#include "AbstractBackgroundDecayGroup.h"
#include "FittingParameter.h"

#include <stdio.h>
#include <boost/algorithm/string.hpp>

using namespace std;

AbstractBackgroundDecayGroup::AbstractBackgroundDecayGroup(const QString& name_) :
   AbstractDecayGroup(name_),
   name(name_.toStdString())
{
   n_lin_components = 0;
   n_nl_parameters = 0;

   std::vector<ParameterFittingType> any_type = { Fixed, FittedLocally, FittedGlobally};

   scale_param = make_shared<FittingParameter>(boost::algorithm::to_lower_copy(name), 0, 1, any_type, Fixed);
   parameters.push_back(scale_param);

   channel_factor_names = { name };
}

AbstractBackgroundDecayGroup::AbstractBackgroundDecayGroup(const AbstractBackgroundDecayGroup& obj) :
   AbstractDecayGroup(obj)
{
   parameters = obj.parameters;
   scale_param = obj.scale_param;
   channel_factors = obj.channel_factors;

   init();
}

void AbstractBackgroundDecayGroup::init_()
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

const std::vector<double>& AbstractBackgroundDecayGroup::getChannelFactors(int index)
{
   if (index == 0)
      return channel_factors;

   throw std::runtime_error("Bad channel factor index");
}

void AbstractBackgroundDecayGroup::setChannelFactors(int index, const std::vector<double>& channel_factors_)
{
   if (index == 0)
      channel_factors = channel_factors_;
   else
      throw std::runtime_error("Bad channel factor index");

}


int AbstractBackgroundDecayGroup::setVariables_(std::vector<double>::const_iterator param_values)
{   
   if (scale_param->isFittedGlobally())
   {
      scale = *param_values;
      return 1;
   }
   return 0;
}


void AbstractBackgroundDecayGroup::setupIncMatrix(inc_matrix& inc, int& inc_row, int& inc_col)
{
   if (scale_param->isFittedLocally())
      inc_col++;   

   if (scale_param->isFittedGlobally())
   {
      inc(inc_row,inc.nc()-1) = 1;
      inc_row++;
   }
}

int AbstractBackgroundDecayGroup::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx)
{
   if (scale_param->isFittedGlobally())
   {
      *output = scale_param->getValue<float>(nonlin_variables, nonlin_idx);
      return 1;   
   }
   return 0;
}

int AbstractBackgroundDecayGroup::getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx)
{
   if (scale_param->isFittedLocally())
   {
      *output = lin_variables[lin_idx++];
      return 1;   
   }
   return 0;
}


std::vector<std::string> AbstractBackgroundDecayGroup::getLinearOutputParamNames()
{
   if (scale_param->isFittedLocally())
      return { scale_param->name };
   else
      return {};
}

int AbstractBackgroundDecayGroup::calculateModel(double_iterator a, int adim, double& kap)
{
   if (scale_param->isFittedLocally())
   {
      addContribution(1.0, a);
      return 1;
   }
   return 0;
}

int AbstractBackgroundDecayGroup::calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   if (scale_param->isFittedGlobally())
   {
      addContribution(1.0, b);
      kap_derv++;
      return 1;
   }
   return 0;
}

void AbstractBackgroundDecayGroup::addConstantContribution(double_iterator a)
{
   double scale_ = 0;
   if (scale_param->isFixed())
      scale_ = scale_param->getInitialValue();

   if (scale_ != 0.0)
      addContribution(scale_, a);
}


void AbstractBackgroundDecayGroup::addUnscaledContribution(double_iterator a)
{
   if (scale_param->isFittedGlobally())
      addContribution(scale, a);
}