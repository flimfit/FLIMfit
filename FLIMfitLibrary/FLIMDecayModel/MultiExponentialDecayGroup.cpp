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

#include <boost/lexical_cast.hpp>
using namespace std;

MultiExponentialDecayGroup::MultiExponentialDecayGroup(shared_ptr<AcquisitionParameters> acq, int n_exponential, bool contributions_global) :
   AbstractDecayGroup(acq),
   n_exponential(n_exponential),
   contributions_global(contributions_global)
{
   channel_factors.resize(acq->n_chan, 1);

   if (contributions_global)
   {
      n_lin_components = 1;
      n_nl_parameters = 2 * n_exponential - 1;
   }
   else
   {
      n_lin_components = n_exponential;
      n_nl_parameters = n_exponential;
   }

   vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };
   
   for (int i = 0; i < n_exponential; i++)
   {
      string name = "tau_" + boost::lexical_cast<std::string>(i + 1);
      double initial_value = 5000.0 / (i + 1);

      auto p = make_shared<FittingParameter>(name, initial_value, fixed_or_global, FittedGlobally);
      parameters.push_back(p);
      tau_parameters.push_back(p);
   }

   if (contributions_global)
   {
      for (int i = 0; i < n_exponential; i++)
      {
         string name = "beta_" + boost::lexical_cast<std::string>(i + 1);
         double initial_value = 1.0 / n_exponential;

         auto p = make_shared<FittingParameter>(name, initial_value, fixed_or_global, FittedGlobally);
         parameters.push_back(p);
         beta_parameters.push_back(p);
      }
   }

   buffer.resize(n_exponential,
      ExponentialPrecomputationBuffer(acq));

}

int MultiExponentialDecayGroup::SetupIncMatrix(int* inc, int& inc_row, int& inc_col)
{
   // Set diagonal elements of incidence matrix for variable tau's   
   int n_exp_col = contributions_global ? 1 : n_exponential;
      
   int cur_col = 0;

   for (int i = 0; i<n_exponential; i++)
   {
      if (tau_parameters[i]->IsFittedGlobally())
         inc[inc_row + (inc_col + cur_col) * 12] = 1;
      
   if (!contributions_global)
         cur_col++;
      inc_row++;
   }

   if (contributions_global)
   {
      // Set diagonal elements of incidence matrix for variable beta's   
      for (int i = 0; i<n_exponential; i++)
      {
         inc[inc_row + inc_col * 12] = 1;
         inc_row++;
      }
   }

   return 0;
}


int MultiExponentialDecayGroup::SetVariables(const double* param_value)
{
   int idx = 0;

   // Get lifetimes
   tau.resize(n_exponential);
   for (int i = 0; i < n_exponential; i++)
   {
      tau[i] = tau_parameters[i]->GetValue<double>(param_value, idx);
      buffer[i].Compute(1 / tau[i], irf_idx, t0_shift, channel_factors, fit_t0);
   }

   // Get contributions
   if (contributions_global)
   {
      beta.resize(n_exponential);
      alf2beta(n_exponential, param_value + idx, beta.data());
   }

   return idx;
}

int MultiExponentialDecayGroup::GetNonlinearOutputs(float* param_values, float* output, int& param_idx)
{
   int output_idx = 0;

   for (int i = 0; i < n_exponential; i++)
      output[output_idx++] = tau_parameters[i]->GetValue<float>(param_values, param_idx);

   if (contributions_global)
   {
      int j = 0;
      for (int i = 0; i < n_exponential; i++)
      {
         if (beta_parameters[0]->IsFixed())
            output[output_idx++] = (float)beta_parameters[i]->initial_value;
         else
            output[output_idx++] = (float)alf2beta(n_exponential, param_values + param_idx, j++); // TODO: need to use no of free betas
      }
   }

   return output_idx;
}

int MultiExponentialDecayGroup::GetLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   int output_idx = 0;

   if (!contributions_global)
      output_idx += NormaliseLinearParameters(lin_variables, n_exponential, output + output_idx, lin_idx);

   return output_idx;
}

void MultiExponentialDecayGroup::GetLinearOutputParamNames(vector<string>& names)
{
   if (!contributions_global)
   {
      names.push_back("I_0");

      for (int i = 0; i < n_exponential; i++)
      {
         string name = "beta_" + boost::lexical_cast<std::string>(i + 1);
         names.push_back(name);
      }
   }
}

int MultiExponentialDecayGroup::NormaliseLinearParameters(float* lin_variables, int n, float* output, int& lin_idx)
{
   double I = 0;
   for (int i = 0; i < n; i++)
      I += lin_variables[i];

   int output_idx = 0;
   output[output_idx++] = (float) I;
   for (int i = 0; i < n; i++)
      output[output_idx++] = (float) (lin_variables[lin_idx++] / I);

   return output_idx;
}


int MultiExponentialDecayGroup::CalculateModel(double* a, int adim, vector<double>& kap)
{
   return AddDecayGroup(buffer, a, adim, kap);
}

int MultiExponentialDecayGroup::CalculateDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   for (int i = 0; i < n_exponential; i++)
      col += AddLifetimeDerivative(i, b + col*bdim, bdim, kap);

   col += AddContributionDerivatives(b + col*bdim, bdim, kap);
   return col;
}


int MultiExponentialDecayGroup::AddDecayGroup(const vector<ExponentialPrecomputationBuffer>& buffers, double* a, int adim, vector<double>& kap)
{
   int col = 0;
    
   int using_reference_reconvolution = acq->irf->type == Reference; // TODO: Clean this up

   if (using_reference_reconvolution && contributions_global)
      AddIRF(irf_buf.data(), irf_idx, t0_shift, a, channel_factors);

   for (int j = 0; j < buffers.size(); j++)
   {
      // If we're doing delta-function reconvolution add contribution from reference
      if (using_reference_reconvolution && !contributions_global)
         AddIRF(irf_buf.data(), irf_idx, t0_shift, a + col*adim, channel_factors);

      double factor = contributions_global ? beta[j] : 1;
      buffers[j].AddDecay(factor, reference_lifetime, a + col*adim);

      if (!contributions_global)
         col++;
   }

   return col;
}


int MultiExponentialDecayGroup::AddLifetimeDerivative(int idx, double* b, int bdim, vector<double>& kap)
{
   if (tau_parameters[idx]->IsFittedGlobally())
   {
      memset(b, 0, bdim*sizeof(*b));

      double fact = 1 / (tau[idx] * tau[idx]); // TODO: *TransformRangeDerivative(wb.tau_buf[j], tau_min[j], tau_max[j]);
      fact *= contributions_global ? beta[idx] : 1;

      buffer[idx].AddDerivative(fact, reference_lifetime, b);

      return 1;
   }

   return 0;
}

int MultiExponentialDecayGroup::AddContributionDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;

   if (contributions_global) // TODO: allow these to be fixed
   {
      for (int j = 0; j < n_exponential - 1; j++)
      {
         memset(b + col*bdim, 0, bdim*sizeof(*b));

         for (int k = j; k < n_exponential; k++)
         {
            double factor = beta_derv(n_exponential, j, k, beta.data());
            buffer[k].AddDecay(factor, reference_lifetime, b + col*bdim);
         }

         col++;
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
