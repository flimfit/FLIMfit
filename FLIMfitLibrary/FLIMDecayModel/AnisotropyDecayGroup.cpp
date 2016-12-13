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

#include "AnisotropyDecayGroup.h"

#include <stdio.h>
#include <boost/lexical_cast.hpp>

using namespace std;

AnisotropyDecayGroup::AnisotropyDecayGroup(int n_lifetime_exponential, int n_anisotropy_populations, bool include_r_inf) :
   MultiExponentialDecayGroupPrivate(n_lifetime_exponential, true, "Anisotropy Decay"),
   n_anisotropy_populations(n_anisotropy_populations),
   include_r_inf(include_r_inf)
{
   vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };

   for (int i = 0; i < n_anisotropy_populations; i++)
   {
      string name = "r_" + boost::lexical_cast<string>(i + 1);
      double initial_value = 1000 + 5000 * i / (n_anisotropy_populations - 1);

      auto p = make_shared<FittingParameter>(name, initial_value, fixed_or_global, FittedGlobally);
      parameters.push_back(p);
      theta_parameters.push_back(p);
   }

   // TODO: MOVE ALL TO INIT
   //n_lin_components = n_anisotropy_populations + include_r_inf + 1;
   //n_nl_parameters += n_anisotropy_populations;

   //anisotropy_buffer.resize(n_anisotropy_populations,
   //   vector<ExponentialPrecomputationBuffer>(n_exponential,
   //   ExponentialPrecomputationBuffer(acq))); 
}

int AnisotropyDecayGroup::setVariables(const double* param_value)
{
   int idx = MultiExponentialDecayGroupPrivate::setVariables(param_value);

   theta.resize(n_anisotropy_populations);

   for (int i = 0; i<n_anisotropy_populations; i++)
   {
      theta[i] = theta_parameters[i]->getValue<double>(param_value, idx);
      // TODO: constrain above 60ps

      for (int j = 0; j < n_exponential; j++)
      {
         double rate = 1 / tau[j] + 1 / theta[i];
         anisotropy_buffer[i][j].Compute(rate, irf_idx, t0_shift, channel_factors[i]); // TODO: check channel factors
      }
   }

   return idx; 
}


/*
Set up matrix indicating which parmeters affect which column.
Each row of the matrix corresponds to a variable
*/
int AnisotropyDecayGroup::setupIncMatrix(std::vector<int>& inc, int& inc_row, int& inc_col)
{
   int n_anisotropy_group = n_anisotropy_populations + include_r_inf + 1;

   // Set diagonal elements of incidence matrix for variable tau's   
   for (int i = 0; i<n_exponential; i++)
   {
      if (tau_parameters[i]->isFittedGlobally())
      {
         for (int j = 0; j<n_anisotropy_group; j++)
            inc[inc_row + (inc_col + j) * 12] = 1;
         inc_row++;
      }
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   for (int i = 0; i<n_exponential; i++)
   {
      if (beta_parameters[0]->isFittedGlobally())
      {
         for (int j = 0; j<n_anisotropy_group; j++)
            inc[inc_row + (inc_col + j) * 12] = 1;
         inc_row++;
      }
   }

   inc_col++;

   // Set elements of incidence matrix for theta derivatives
   for (int i = 0; i<n_anisotropy_populations; i++)
   {
      if (theta_parameters[i]->isFittedGlobally())
      {
         inc[inc_row + inc_col * 12] = 1;
         inc_col++;
         inc_row++;
      }
   }

   return 0;
}

int AnisotropyDecayGroup::getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx)
{
   int output_idx = MultiExponentialDecayGroupPrivate::getNonlinearOutputs(nonlin_variables, output, nonlin_idx);

   for (int i = 0; i < n_anisotropy_populations; i++)
      output[output_idx++] = theta_parameters[i]->getValue<float>(nonlin_variables, nonlin_idx);

   return output_idx;
}

int AnisotropyDecayGroup::getLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   int output_idx = 0;
   
   // Normalise r's

   double I0 = lin_variables[0];
   double r0 = 0.0;

   int n_r = n_anisotropy_populations + include_r_inf;

   for (int j = 1; j<n_r + 1; j++)
   {
      output[output_idx+j] = (float) (lin_variables[j] / I0);
      r0 += output[output_idx+j];
   }

   output[output_idx] = (float) r0;
   output_idx += (n_r + 1);

   output[output_idx] = (float) I0;

   return output_idx;
}

void AnisotropyDecayGroup::getLinearOutputParamNames(vector<string>& names)
{
   names.push_back("I_0");
   names.push_back("r_0");

   for (int i = 0; i < n_anisotropy_populations; i++)
   {
      string name = "r_" + boost::lexical_cast<std::string>(i + 1);
      names.push_back(name);
   }

   if (include_r_inf)
      names.push_back("r_inf");
}


int AnisotropyDecayGroup::calculateModel(double* a, int adim, vector<double>& kap)
{
   int col = 0;

   col += addDecayGroup(buffer, a, adim, kap);

   for (int i = 0; i < anisotropy_buffer.size(); i++)
      col += addDecayGroup(anisotropy_buffer[i], a, adim, kap);
   // TODO: channel factors need to be sorted here!!!
   return col;
}


int AnisotropyDecayGroup::calculateDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   for (int i = 0; i < n_exponential; i++)
   {
      col += addLifetimeDerivative(i, b + col*bdim, bdim, kap);
      col += addLifetimeDerivativesForAnisotropy(i, b + col*bdim, bdim, kap);
   }

   col += addContributionDerivatives(b + col*bdim, bdim, kap);
   col += addRotationalCorrelationTimeDerivatives(b + col*bdim, bdim, kap);

   return col;
}



int AnisotropyDecayGroup::addLifetimeDerivativesForAnisotropy(int idx, double* b, int bdim, vector<double>& kap)
{
   if (tau_parameters[idx]->isFittedGlobally())
   {
      memset(b, 0, bdim*sizeof(*b));

      for (int j = 0; j < n_anisotropy_populations; j++)
      {
         double fact = 1 / (tau[idx] * tau[idx]); // TODO: *TransformRangeDerivative(wb.tau_buf[j], tau_min[j], tau_max[j]);
         fact *= beta[idx];

         buffer[idx].AddDerivative(fact, reference_lifetime, b);
      }


      return 1;
   }

   return 0;
}

int AnisotropyDecayGroup::addRotationalCorrelationTimeDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;

   for (int p = 0; p<n_anisotropy_populations; p++)
   {
      if (theta_parameters[p]->isFittedGlobally())
      {
         memset(b + col*bdim, 0, bdim*sizeof(*b));

         for (int j = 0; j < n_exponential; j++)
         {
            double factor = beta[j] / theta[p] / theta[p]; // TODO: * TransformRangeDerivative(wb.theta_buf[p], 0, 1000000);
            anisotropy_buffer[p][j].AddDerivative(factor, reference_lifetime, b + col * bdim);
         }

         col++;
      }
   }

   return col;
}

// TODO: call this
void AnisotropyDecayGroup::setupChannelFactors()
{
   channel_factors.push_back({ 1.0 / 3.0, 1.0 / 3.0 });

   int n_pol_group = n_anisotropy_populations + include_r_inf;
   for (int i = 1; i < n_pol_group; i++)
      channel_factors.push_back({ 2.0 / 3.0, -1.0 / 3.0 });
}