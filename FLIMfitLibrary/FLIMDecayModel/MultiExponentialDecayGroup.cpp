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

#include <boost/lexical_cast.hpp>
using namespace std;


MultiExponentialDecayGroupPrivate::MultiExponentialDecayGroupPrivate(int n_exponential, bool contributions_global, const QString& name) :
   AbstractDecayGroup(name),
   n_exponential(n_exponential),
   contributions_global(contributions_global)
{
   channel_factor_names.push_back("Decay");

   setupParametersMultiExponential();
}

MultiExponentialDecayGroupPrivate::MultiExponentialDecayGroupPrivate(const MultiExponentialDecayGroupPrivate& obj) :
   AbstractDecayGroup(obj)
{
   n_exponential = obj.n_exponential;
   contributions_global = obj.contributions_global;
   tau_parameters = obj.tau_parameters;
   beta_parameters = obj.beta_parameters;
   channel_factors = obj.channel_factors;
}


void MultiExponentialDecayGroupPrivate::resizeLifetimeParameters(std::vector<std::shared_ptr<FittingParameter>>& params, int new_size, const std::string& name_prefix)
{
   vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };
   
   if (params.size() > new_size)
      params.resize(new_size);
   
   for (auto& p : params)
      parameters.push_back(p);

   if (params.size() < new_size)
   {
      size_t old_size = params.size();
      for (size_t i = old_size; i < new_size; i++)
      {
         string name = name_prefix + boost::lexical_cast<std::string>(i + 1);
         double initial_value = 3000 / (i + 1);

         auto p = make_shared<FittingParameter>(name, initial_value, fixed_or_global, Fixed);
         params.push_back(p);
         parameters.push_back(p);
      }
   }

}

void MultiExponentialDecayGroupPrivate::setupParametersMultiExponential()
{   
   vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };

   parameters.clear();

   resizeLifetimeParameters(tau_parameters, n_exponential, "tau_");

   if (contributions_global && (n_exponential > 1))
   {
      if (beta_parameters.size() > n_exponential)
      {
         beta_parameters.resize(n_exponential);
      }
      else
      {
         size_t old_size = beta_parameters.size();
         for (size_t i = old_size; i < n_exponential; i++)
         {
            string name = "beta_" + boost::lexical_cast<std::string>(i + 1);
            double initial_value = 1.0 / n_exponential;

            auto p = make_shared<FittingParameter>(name, initial_value, fixed_or_global, FittedGlobally);
            beta_parameters.push_back(p);
         }
      }
   }
   else
   {
      beta_parameters.clear();
   }

   for (auto p : beta_parameters)
      parameters.push_back(p);

   parametersChanged();
}

void MultiExponentialDecayGroupPrivate::init()
{
   n_lin_components = contributions_global ? 1 : n_exponential;

   n_nl_parameters = 0;
   for (auto& p : tau_parameters)
      n_nl_parameters += p->isFittedGlobally();
   
   // Reduce degrees of freedom
   if (!beta_parameters.empty())
   {
      for (auto& p : beta_parameters)
         p->setConstrained(false);

      for (auto it = beta_parameters.rbegin(); it != beta_parameters.rend(); it++)
      {
         if (!(*it)->isFixed())
         {
            (*it)->setConstrained();
            break;
         }
      }
   }

   for (auto& p : beta_parameters)
      n_nl_parameters += p->isFittedGlobally();

   fixed_beta = 0;
   n_beta_free = 0;
   for (auto& p : beta_parameters)
      if (p->isFixed())
         fixed_beta += p->initial_value;
      else
         n_beta_free++;

   buffer.clear();
   buffer.resize(n_exponential,
      ExponentialPrecomputationBuffer(dp));

   channel_factors.resize(dp->n_chan, 1);
}

void MultiExponentialDecayGroupPrivate::setNumExponential(int n_exponential_)
{
   n_exponential = n_exponential_;
   setupParametersMultiExponential();
}

void MultiExponentialDecayGroupPrivate::setContributionsGlobal(bool contributions_global_)
{
   contributions_global = contributions_global_;
   setupParametersMultiExponential();
}

const vector<double>& MultiExponentialDecayGroupPrivate::getChannelFactors(int index)
{
   if (index == 0)
      return channel_factors;

   throw std::runtime_error("Bad channel factor index");
}

void MultiExponentialDecayGroupPrivate::setChannelFactors(int index, const vector<double>& channel_factors_)
{
   if (index == 0)
      channel_factors = channel_factors_;
   else
      throw std::runtime_error("Bad channel factor index");
}



int MultiExponentialDecayGroupPrivate::setupIncMatrix(std::vector<int>& inc, int& inc_row, int& inc_col)
{
   // Set diagonal elements of incidence matrix for variable tau's   
      
   int cur_col = 0;

   for (int i = 0; i < n_exponential; i++)
   {
      if (tau_parameters[i]->isFittedGlobally())
      {
         inc[inc_row + (inc_col + cur_col) * 12] = 1;
         inc_row++;
      }

      if (!contributions_global)
         cur_col++;
   }

   if (contributions_global)
   {
      // Set diagonal elements of incidence matrix for variable beta's   
      for (int i = 0; i<n_exponential; i++)
      {
         if (beta_parameters[i]->isFittedGlobally())
         {
            inc[inc_row + inc_col * 12] = 1;
            inc_row++;
         }
      }
   }

   inc_col = contributions_global ? 1 : n_exponential;

   return 0;
}


int MultiExponentialDecayGroupPrivate::setVariables(const double* param_value)
{
   int idx = 0;

   // Get lifetimes
   tau.resize(n_exponential);
   for (int i = 0; i < n_exponential; i++)
   {
      tau[i] = tau_parameters[i]->getValue<double>(param_value, idx);
      tau[i] = tau[i] < 50.0 ? 50.0 : tau[i];
      buffer[i].Compute(1 / tau[i], irf_idx, t0_shift, channel_factors);
   }

   // Get contributions
   if (contributions_global)
   {
      beta_param_values = param_value + idx;
      beta.resize(n_exponential);
      if (n_exponential > 1)
         idx += getBeta(beta_parameters, fixed_beta, n_beta_free, param_value + idx, beta.data());
      else
         beta[0] = 1;
   }

   return idx;
}

int MultiExponentialDecayGroupPrivate::getNonlinearOutputs(float* param_values, float* output, int& param_idx)
{
   int output_idx = 0;

   for (int i = 0; i < n_exponential; i++)
      output[output_idx++] = tau_parameters[i]->getValue<float>(param_values, param_idx);

   if (contributions_global && n_exponential > 1)
   {
      getBeta(beta_parameters, fixed_beta, n_beta_free, param_values + param_idx, output + output_idx);
      output_idx += n_exponential;
   }

   return output_idx;
}

int MultiExponentialDecayGroupPrivate::getLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   int output_idx = 0;

   if (!contributions_global)
      output_idx += normaliseLinearParameters(lin_variables, n_exponential, output + output_idx, lin_idx);

   return output_idx;
}

void MultiExponentialDecayGroupPrivate::getLinearOutputParamNames(vector<string>& names)
{
   if (!contributions_global)
   {
      names.push_back("I_0");

      if (n_exponential > 1)
      {
         for (int i = 0; i < n_exponential; i++)
         {
            string name = "beta_" + boost::lexical_cast<std::string>(i + 1);
            names.push_back(name);
         }
      }
   }
}

int MultiExponentialDecayGroupPrivate::normaliseLinearParameters(float* lin_variables, int n, float* output, int& lin_idx)
{
   double I = 0;
   for (int i = 0; i < n; i++)
      I += lin_variables[i];

   int output_idx = 0;
   output[output_idx++] = (float) I;

   if (n > 1)
      for (int i = 0; i < n; i++)
         output[output_idx++] = (float) (lin_variables[lin_idx++] / I);

   return output_idx;
}


int MultiExponentialDecayGroupPrivate::calculateModel(double* a, int adim, vector<double>& kap, int bin_shift)
{
   int sz = contributions_global ? 1 : n_exponential;
   memset(a, 0, sz*adim*sizeof(*a));
   return addDecayGroup(buffer, a, adim, kap, bin_shift);
}

int MultiExponentialDecayGroupPrivate::calculateDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   for (int i = 0; i < n_exponential; i++)
      col += addLifetimeDerivative(i, b + col*bdim, bdim, kap);

   col += addContributionDerivatives(b + col*bdim, bdim, kap);
   return col;
}


int MultiExponentialDecayGroupPrivate::addDecayGroup(const vector<ExponentialPrecomputationBuffer>& buffers, double* a, int adim, vector<double>& kap, int bin_shift)
{
   int col = 0;
    
   int using_reference_reconvolution = dp->irf->type == Reference; // TODO: Clean this up

   if (using_reference_reconvolution && contributions_global)
      addIRF(irf_buf.data(), irf_idx, t0_shift, a, channel_factors);

   for (int j = 0; j < buffers.size(); j++)
   {
      // If we're doing delta-function reconvolution add contribution from reference
      if (using_reference_reconvolution && !contributions_global)
         addIRF(irf_buf.data(), irf_idx, t0_shift, a + col*adim, channel_factors);

      double factor = contributions_global ? beta[j] : 1;
      buffers[j].AddDecay(factor, reference_lifetime, a + col*adim, bin_shift);

      if (!contributions_global)
         col++;
   }

   if (contributions_global)
      col++;

   return col;
}


int MultiExponentialDecayGroupPrivate::addLifetimeDerivative(int idx, double* b, int bdim, vector<double>& kap)
{
   if (tau_parameters[idx]->isFittedGlobally())
   {
      memset(b, 0, bdim*sizeof(*b));

      double fact = 1 / (tau[idx] * tau[idx]); // TODO: *TransformRangeDerivative(wb.tau_buf[j], tau_min[j], tau_max[j]);
      fact *= contributions_global ? beta[idx] : 1;

      buffer[idx].AddDerivative(fact, reference_lifetime, b);

      return 1;
   }

   return 0;
}

int MultiExponentialDecayGroupPrivate::addContributionDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;

   int ji = 0;
   if (contributions_global)
   {
      for (int j = 0; j < n_exponential - 1; j++)
         if (!beta_parameters[j]->isFixed())
         {
            memset(b + col*bdim, 0, bdim * sizeof(*b));
            int ki = ji;
            for (int k = j; k < n_exponential; k++)
               if (!beta_parameters[k]->isFixed())
               {
                  double factor = beta_derv(n_beta_free, ji, ki, beta_param_values) * (1-fixed_beta);
                  buffer[k].AddDecay(factor, reference_lifetime, b + col*bdim);
                  ki++;
               }

            col++;
            ji++;
         }
   }

   return col;
}


// TODO: mean lifetimes
/*
void DecayModel::CalculateMeanLifetime(volatile float lin_params[], float tau[], volatile float mean_lifetimes[])
{
   if (calculate_mean_lifetimes)
   {
      float mean_tau = 0;
      float w_mean_tau = 0;

      for (int i = 0; i<n_fix; i++)
      {
         w_mean_tau += (float)(tau_guess[i] * tau_guess[i] * lin_params[i]);
         mean_tau += (float)(tau_guess[i] * lin_params[i]);
      }

      for (int i = 0; i<n_v; i++)
      {
         w_mean_tau += (float)(tau[i] * tau[i] * lin_params[i + n_fix]);
         mean_tau += (float)(tau[i] * lin_params[i + n_fix]);
      }

      w_mean_tau /= mean_tau;

      mean_lifetimes[0] = mean_tau;
      mean_lifetimes[1] = w_mean_tau;
   }

}
*/
