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

#define _USE_MATH_DEFINES
#include <cmath>

#include "AnisotropyDecayGroup.h"

#include <stdio.h>
#include <boost/lexical_cast.hpp>

using namespace std;

AnisotropyDecayGroup::AnisotropyDecayGroup(int n_lifetime_exponential, int n_anisotropy_populations, bool include_r_inf) :
   MultiExponentialDecayGroupPrivate(n_lifetime_exponential, true, "Anisotropy Decay"),
   n_anisotropy_populations(n_anisotropy_populations),
   include_r_inf(include_r_inf)
{
   setupParameters();
}

AnisotropyDecayGroup::AnisotropyDecayGroup(const AnisotropyDecayGroup& obj) : 
   MultiExponentialDecayGroupPrivate(obj)
{
   n_anisotropy_populations = obj.n_anisotropy_populations;
   include_r_inf = obj.include_r_inf;
   theta_parameters = obj.theta_parameters;

   setupParameters();
   init();
}

void AnisotropyDecayGroup::init()
{
   MultiExponentialDecayGroupPrivate::init();

   n_lin_components = n_anisotropy_populations + include_r_inf + 1;
   n_nl_parameters += n_anisotropy_populations;

   anisotropy_buffer.resize(n_anisotropy_populations);
   for (int i = 0; i < n_anisotropy_populations; i++)
      anisotropy_buffer[i] = AbstractConvolver::make_vector(n_exponential, dp);

   setupChannelFactors();
}


void AnisotropyDecayGroup::setNumExponential(int n_exponential_)
{
   n_exponential = n_exponential_;
   setupParameters();
}

void AnisotropyDecayGroup::setNumAnisotropyPopulations(int n_anisotropy_populations_)
{
   n_anisotropy_populations = n_anisotropy_populations_;
   setupParameters();
}

void AnisotropyDecayGroup::setIncludeRInf(bool include_r_inf_)
{
   include_r_inf = include_r_inf_;
}


void AnisotropyDecayGroup::setupParameters()
{
   channel_factor_names.clear();
   setupParametersMultiExponential();
   resizeLifetimeParameters(theta_parameters, n_anisotropy_populations, "theta_");
}

int AnisotropyDecayGroup::setVariables(const_double_iterator param_value)
{
   int idx = MultiExponentialDecayGroupPrivate::setVariables(param_value);
    
   k_theta.resize(n_anisotropy_populations);

   for (int i = 0; i<n_anisotropy_populations; i++)
   {
      k_theta[i] = theta_parameters[i]->getTransformedValue<double>(param_value, idx);
      // TODO: constrain above 60ps

      for (int j = 0; j < n_exponential; j++)
      {
         double rate = k_decay[j] + k_theta[i];
         anisotropy_buffer[i][j]->compute(rate, irf_idx, t0_shift);
      }
   }

   return idx; 
}


/*
Set up matrix indicating which parmeters affect which column.
Each row of the matrix corresponds to a variable
*/
void AnisotropyDecayGroup::setupIncMatrix(std::vector<int>& inc, int& inc_row, int& inc_col)
{
   int n_anisotropy_group = n_anisotropy_populations + include_r_inf + 1;

   // Set diagonal elements of incidence matrix for variable tau's   
   for (auto& p : tau_parameters)
      if (p->isFittedGlobally())
      {
         for (int j = 0; j<n_anisotropy_group; j++)
            inc[inc_row + (inc_col + j) * MAX_VARIABLES] = 1;
         inc_row++;
      }

   // Set diagonal elements of incidence matrix for variable beta's   
   for (auto& p : beta_parameters)
      if (p->isFittedGlobally())
      {
         for (int j = 0; j<n_anisotropy_group; j++)
            inc[inc_row + (inc_col + j) * MAX_VARIABLES] = 1;
         inc_row++;
      }

   inc_col++;

   // Set elements of incidence matrix for theta derivatives
   for (int j=0; j<n_anisotropy_populations; j++)
      if (theta_parameters[j]->isFittedGlobally())
      {
         inc[inc_row + (inc_col + j) * MAX_VARIABLES] = 1;
         inc_row++;
      }

   inc_col += n_anisotropy_populations + include_r_inf;
}

int AnisotropyDecayGroup::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx)
{
   int output_idx = MultiExponentialDecayGroupPrivate::getNonlinearOutputs(nonlin_variables, output, nonlin_idx);

   for (int i = 0; i < n_anisotropy_populations; i++)
      output[output_idx++] = theta_parameters[i]->getValue<float>(nonlin_variables, nonlin_idx);

   return output_idx;
}

int AnisotropyDecayGroup::getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx)
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

std::vector<std::string> AnisotropyDecayGroup::getLinearOutputParamNames()
{
   std::vector<std::string> names;
   names.push_back("I_0");
   names.push_back("r_0");

   for (int i = 0; i < n_anisotropy_populations; i++)
   {
      string name = "r_" + boost::lexical_cast<std::string>(i + 1);
      names.push_back(name);
   }

   if (include_r_inf)
      names.push_back("r_inf");
   return names;
}


int AnisotropyDecayGroup::calculateModel(double_iterator a, int adim, double& kap)
{
   int col = 0;

   int n_anisotropy_group = n_anisotropy_populations + include_r_inf + 1;
   col += addDecayGroup(buffer, 1, a, adim, kap, ss_channel_factors);

   for (int i = 0; i < anisotropy_buffer.size(); i++)
      col += addDecayGroup(anisotropy_buffer[i], 1, a + adim * col, adim, kap, pol_channel_factors);

   if (include_r_inf)
      col += addDecayGroup(buffer, 1, a + adim * col, adim, kap, pol_channel_factors);

   return col;
}


int AnisotropyDecayGroup::calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   for (int i = 0; i < n_exponential; i++)
      if (tau_parameters[i]->isFittedGlobally())
      {
         col += addLifetimeDerivative(i, b + col * bdim, bdim, ss_channel_factors);
         col += addLifetimeDerivativesForAnisotropy(i, b + col * bdim, bdim, kap_derv[col]);
         if (include_r_inf)
            col += addLifetimeDerivative(i, b + col * bdim, bdim, pol_channel_factors);
         addLifetimeKappaDerivative(i, kap_derv);

      }

   col += addContributionDerivativesForAnisotropy(b + col*bdim, bdim, kap_derv);
   col += addRotationalCorrelationTimeDerivatives(b + col*bdim, bdim, &kap_derv[col]);

   return col;
}



int AnisotropyDecayGroup::addLifetimeDerivativesForAnisotropy(int j, double_iterator b, int bdim, double& kap_derv)
{
   int col = 0;
   for (int p = 0; p < n_anisotropy_populations; p++)
   {
      double fact = beta[j];
      anisotropy_buffer[p][j]->addDerivative(fact, pol_channel_factors, reference_lifetime, b + col * bdim);
      col++;
   }

   return col;
}

int AnisotropyDecayGroup::addContributionDerivativesForAnisotropy(double_iterator b, int bdim, double_iterator kap_derv)
{
   if (n_exponential < 2)
      return 0;

   int col = 0;
   int n_anisotropy_group = n_anisotropy_populations + include_r_inf + 1;;

   int ji = 0;
   for (int j = 0; j < n_exponential; j++)
      if (beta_parameters[j]->isFittedGlobally())
      {
         for (int i = 0; i < n_anisotropy_group; i++)
         {
            int qi = ji;
            for (int q = j; q < n_exponential; q++)
            {
               if (!beta_parameters[q]->isFixed())
               {
                  double factor = beta_derv(n_beta_free, ji, qi, beta_param_values) * (1 - fixed_beta);
                  if (i == 0)
                  {
                     buffer[q]->addDecay(factor, ss_channel_factors, reference_lifetime, b + col * bdim);
                  }
                  else if (i > 0)
                  {
                     int anisotropy_idx = i - 1;
                     anisotropy_buffer[anisotropy_idx][q]->addDecay(factor, pol_channel_factors, reference_lifetime, b + col * bdim);
                  }
                  qi++;
               }
            }
            col++;
         }
         kap_derv++;
         ji++;
      }

   return col;
}


int AnisotropyDecayGroup::addRotationalCorrelationTimeDerivatives(double_iterator b, int bdim, double kap_derv[])
{
   int col = 0;

   for (int p = 0; p<n_anisotropy_populations; p++)
   {
      if (theta_parameters[p]->isFittedGlobally())
      {
         for (int j = 0; j < n_exponential; j++)
         {
            double factor = beta[j];
            anisotropy_buffer[p][j]->addDerivative(factor, pol_channel_factors, reference_lifetime, b + col * bdim);
         }

         col++;
      }
   }

   return col;
}

// TODO: call this
void AnisotropyDecayGroup::setupChannelFactors()
{
   double g_factor = dp->irf->g_factor;
   double angle = dp->irf->polarisation_angle;
   int n_chan = dp->n_chan;

   double para = (3.0 * cos(angle) - 1.0) / 6.0;
   double perp = (g_factor * 3.0 * cos(angle * M_PI / 180 + M_PI * 0.5) - 1.0) / 6.0;

   auto& polarisation = dp->getPolarisation();

   ss_channel_factors = norm_channel_factors;
   pol_channel_factors = norm_channel_factors;

   for (int i = 0; i < n_chan; i++)
   {
      switch (polarisation[i])
      {
      case Unpolarised:
         ss_channel_factors[i] *= 2.0 / 3.0;
         pol_channel_factors[i] = 0;
         break;

      case Parallel:
         ss_channel_factors[i] *= 1.0 / 3.0;
         pol_channel_factors[i] *= para;
         break;

      case Perpendicular:
         ss_channel_factors[i] *= g_factor / 3.0;
         pol_channel_factors[i] *= perp;
         break;
      }
   }
   }