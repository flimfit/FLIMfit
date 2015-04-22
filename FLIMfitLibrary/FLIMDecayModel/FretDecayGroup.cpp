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

#include "FretDecayGroup.h"

#include <stdio.h>
#include <boost/lexical_cast.hpp>

using namespace std;

FretDecayGroup::FretDecayGroup(int n_donor_exponential, int n_fret_populations, bool include_donor_only) :
   MultiExponentialDecayGroup(n_donor_exponential, true),
   n_fret_populations(n_fret_populations),
   include_donor_only(include_donor_only)
{
   Validate();
}

void FretDecayGroup::Validate()
{
   ValidateMultiExponential();

   channel_factor_names.clear();
   channel_factor_names.push_back("Donor");
   if (include_acceptor)
      channel_factor_names.push_back("Acceptor");

   n_multiexp_parameters = n_nl_parameters;
   n_lin_components = n_fret_populations + include_donor_only;
   n_nl_parameters += n_fret_populations;

   vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };

   for (int i = 0; i < n_fret_populations; i++)
   {
      string name = "E_" + boost::lexical_cast<string>(i + 1);
      double initial_value = 0.25 + 0.5 * i / (n_fret_populations-1);


      auto p = make_shared<FittingParameter>(name, initial_value, fixed_or_global, FittedGlobally);
      parameters.push_back(p);
      E_parameters.push_back(p);
   }

   if (include_acceptor)
   {
      double initial_value = 1;
      A0_parameter = make_shared<FittingParameter>("A0", initial_value, fixed_or_global, FittedGlobally);
      parameters.push_back(A0_parameter);
   }


}

void FretDecayGroup::Init()
{
   fret_buffer.resize(n_fret_populations, 
      vector<ExponentialPrecomputationBuffer>(n_exponential,
        ExponentialPrecomputationBuffer(acq)));

   if (include_acceptor)
      acceptor_buffer = make_unique<ExponentialPrecomputationBuffer>(acq);
}


void FretDecayGroup::SetNumFretPopulations(int n_fret_populations_)
{
   n_fret_populations = n_fret_populations;
   Validate();
}

void FretDecayGroup::SetIncludeDonorOnly(bool include_donor_only_)
{
   include_donor_only = include_donor_only_;
   Validate();
}

void FretDecayGroup::SetIncludeAcceptor(bool include_acceptor_)
{
   include_acceptor = include_acceptor_;
   Validate();
}

const vector<double>& FretDecayGroup::GetChannelFactors(int index)
{
   if (index == 0)
      return channel_factors;
   else if (include_acceptor && index == 1)
      return acceptor_channel_factors;

   throw std::exception("Bad channel factor index");
}

void FretDecayGroup::SetChannelFactors(int index, const vector<double>& channel_factors_)
{
   if (index == 0)
      channel_factors = channel_factors_;
   else if (include_acceptor && index == 1)
      acceptor_channel_factors = channel_factors_;
   else
      throw std::exception("Bad channel factor index");
}



/*
   Set up matrix indicating which parmeters affect which column.
   Each row of the matrix corresponds to a variable
*/
int FretDecayGroup::SetupIncMatrix(int* inc, int& inc_row, int& inc_col)
{
   int n_fret_group = n_fret_populations + include_donor_only;
   
   // Set diagonal elements of incidence matrix for variable tau's   
   for (int i = 0; i<n_exponential; i++)
   {
      if (tau_parameters[i]->IsFittedGlobally())
      {
         for (int j = 0; j<n_fret_group; j++)
            inc[inc_row + (inc_col + j) * 12] = 1;
         inc_row++;
      }
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   for (int i = 0; i<n_exponential; i++)
   {
      if (beta_parameters[0]->IsFittedGlobally())
      {
         for (int j = 0; j<n_fret_group; j++)
            inc[inc_row + (inc_col + j) * 12] = 1;
         inc_row++;
      }
   }
   
   if (include_donor_only)
      inc_col++;

   // Set elements of incidence matrix for E derivatives
   for (int i = 0; i<n_fret_populations; i++)
   {
      if (E_parameters[i]->IsFittedGlobally())
      {
         inc[inc_row + (inc_col + i) * 12] = 1;
         inc_col++;
         inc_row++;
      }
   }

   // Set elements of incidence matrix for A0 and tauA derivatives
   if (include_acceptor)
   {
      if (A0_parameter->IsFittedGlobally())
      {
         for (int i = 0; i < n_fret_populations; i++)
            inc[inc_row + inc_col * 12] = 1;
         inc_row++;
      }
      if (tauA_parameter->IsFittedGlobally())
      {
         for (int i = 0; i < n_fret_populations; i++)
            inc[inc_row + inc_col * 12] = 1;
         inc_row++;
      }
   }

   inc_col += n_fret_populations;

   return 0;
}

int FretDecayGroup::SetVariables(const double* param_values)
{
   int idx = MultiExponentialDecayGroup::SetVariables(param_values);

   tau_fret.resize(n_fret_populations, vector<double>(n_exponential));
   E.resize(n_fret_populations);

   // Set tau's for FRET
   for (int i = 0; i<n_fret_populations; i++)
   {
      E[i][0] = E_parameters[i]->GetValue<double>(param_values, idx);

      for (int j = 0; j<n_exponential; j++)
      {
         E[i][j] = tau[j] / tau[0] * E[i][0];
         E[i][j] /= (1 - E[i][0] + E[i][j]);

         tau_fret[i][j] = tau[j] * (1 - E[i][j]);
         double rate = 1 / tau_fret[i][j];
         fret_buffer[i][j].Compute(rate, irf_idx, t0_shift, channel_factors, false);
      }
   }

   if (include_acceptor)
   {
      A0 = A0_parameter->GetValue<double>(param_values, idx);
      tauA = tauA_parameter->GetValue<double>(param_values, idx);

      acceptor_buffer->Compute(1 / tauA, irf_idx, t0_shift, acceptor_channel_factors, false);

      for (int i = 0; i < n_fret_populations; i++)
         for (int j = 0; j < n_exponential; j++)
            a_star[i][j] = tauA * (1 - E[i][j]) / (tauA - tau_fret[i][j]);
   }

   return idx;
}

int FretDecayGroup::GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx)
{
   int output_idx = MultiExponentialDecayGroup::GetNonlinearOutputs(nonlin_variables, output, nonlin_idx);

   for (int i = 0; i < n_fret_populations; i++)
      output[output_idx++] = E_parameters[i]->GetValue<float>(nonlin_variables, nonlin_idx);

   if (include_acceptor)
   {
      output[output_idx++] = A0_parameter->GetValue<float>(nonlin_variables, nonlin_idx);
      output[output_idx++] = tauA_parameter->GetValue<float>(nonlin_variables, nonlin_idx);
   }

   return output_idx;
}


int FretDecayGroup::GetLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   int output_idx = 0;

   int n_fret_group = include_donor_only + n_fret_populations;
   output_idx += NormaliseLinearParameters(lin_variables, n_fret_group, output + output_idx, lin_idx);

   return output_idx;
}

void FretDecayGroup::GetLinearOutputParamNames(vector<string>& names)
{
   names.push_back("I_0");

   if (include_donor_only)
      names.push_back("gamma_0");

   for (int i = 0; i < n_fret_populations; i++)
   {
      string name = "gamma_" + boost::lexical_cast<std::string>(i + 1);
      names.push_back(name);
   }
}


int FretDecayGroup::CalculateModel(double* a, int adim, vector<double>& kap)
{
   int col = 0;

   if (include_donor_only)
      col += AddDecayGroup(buffer, a + col*adim, adim, kap);

   for (int i = 0; i < fret_buffer.size(); i++)
   {
      AddDecayGroup(fret_buffer[i], a + col*adim, adim, kap);
      AddAcceptorContribution(i, A0, a + col*adim, adim, kap);

      col++;
   }

   return col;
}

void FretDecayGroup::AddAcceptorContribution(int i, double factor, double* a, int adim, vector<double>& kap)
{
   if (include_acceptor)
   {
      double a_start_sum = 0;
      for (int j = 0; j < n_exponential; j++)
      {
         fret_buffer[i][j].AddDecay(factor * beta[j] * a_star[i][j], reference_lifetime, a); // rise time
         a_start_sum += beta[j] * a_star[i][j];
      }

      acceptor_buffer->AddDecay(factor * a_start_sum, reference_lifetime, a);
   }
}

void FretDecayGroup::AddAcceptorDerivativeContribution(int i, std::function<double(int i, int j)> fact, double* b, int bdim, vector<double>& kap)
{
   if (include_acceptor)
   {
      double f_sum = 0;
      for (int j = 0; j < n_exponential; j++)
      {
         double f = fact(i, j);
         fret_buffer[i][j].AddDecay(f * beta[j], reference_lifetime, b); // rise time
         f_sum += f;
      }
      acceptor_buffer->AddDecay(f_sum, reference_lifetime, b);
   }
}


int FretDecayGroup::CalculateDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   for (int i = 0; i < n_exponential; i++)
   {
      col += AddLifetimeDerivative(i, b + col*bdim, bdim, kap);
      col += AddLifetimeDerivativesForFret(i, b + col*bdim, bdim, kap);
   }

   col += AddContributionDerivatives(b + col*bdim, bdim, kap);
   col += AddFretEfficiencyDerivatives(b + col*bdim, bdim, kap);

   if (include_acceptor)
   {
      col += AddAcceptorIntensityDerivatives(b + col*bdim, bdim, kap);
      col += AddAcceptorLifetimeDerivatives(b + col*bdim, bdim, kap);
   }

   return col;
}



int FretDecayGroup::AddLifetimeDerivativesForFret(int j, double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   int idx = 0;

   // d(fret)/d(tau)
   for (int i = 0; i<n_fret_populations; i++)
   {
      memset(b + idx, 0, bdim*sizeof(*b));

      double fact = beta[j] / (tau_fret[i][j] * tau[j]);

      if (include_acceptor)
         fact *= (1 + a_star[i][j]);
         
      fret_buffer[i][j].AddDerivative(fact, reference_lifetime, b + idx);

      auto acceptor_fact = [this](int i, int j) { return a_star[i][j] * a_star[i][j] / tauA; };
      AddAcceptorDerivativeContribution(i, acceptor_fact, b + idx, bdim, kap);

      col++;
      idx += bdim;
   }

   return col;
}

int FretDecayGroup::AddFretEfficiencyDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   int idx = 0;

   for (int i = 0; i<n_fret_populations; i++)
   {
      memset(b + idx, 0, bdim*sizeof(*b));

      for (int j = 0; j<n_exponential; j++)
      {
         double dE = E[i][j] / E[i][0];
         dE *= dE;
         dE *= tau[0] / tau[j];

         double fact = -beta[j] * tau[j] / (tau_fret[i][j] * tau_fret[i][j]) * dE;
         
         if (include_acceptor)
            fact *= (1 + a_star[i][j]);

         fret_buffer[i][j].AddDerivative(fact, reference_lifetime, b + idx);
      }

      auto fact = [this](int i, int j) { return -a_star[i][j] * a_star[i][j] / ((1-E[i][j])*(1-E[i][j])); };
      AddAcceptorDerivativeContribution(i, fact, b + idx, bdim, kap);

      col++;
      idx += bdim;
   }

   return col;
}

int FretDecayGroup::AddAcceptorIntensityDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   int idx = 0;

   for (int i = 0; i < n_fret_populations; i++)
   {
      memset(b + idx, 0, bdim*sizeof(*b));

      AddAcceptorContribution(i, 1.0, b + idx, bdim, kap);

      col++;
      idx += bdim;
   }

   return col;
}

int FretDecayGroup::AddAcceptorLifetimeDerivatives(double* b, int bdim, vector<double>& kap)
{
   int col = 0;
   int idx = 0;

   for (int i = 0; i < n_fret_populations; i++)
   {
      memset(b + idx, 0, bdim*sizeof(*b));

      double fact = 0;
      for (int j = 0; j < n_exponential; j++)
         fact += beta[j] * a_star[i][j];
      fact /= (tauA * tauA);
      
      acceptor_buffer->AddDerivative(fact, reference_lifetime, b + idx);

      for (int j = 0; j < n_exponential; j++)
      {
         fact = beta[j] * a_star[i][j] * a_star[i][j] * tau[j] / (tauA * tauA);
         acceptor_buffer->AddDecay(fact, reference_lifetime, b + idx);
         fret_buffer[i][j].AddDecay(-fact, reference_lifetime, b + idx);
      }

      auto acceptor_fact = [this](int i, int j) { return - a_star[i][j] * a_star[i][j] * tau[i] / (tauA * tauA); };
      AddAcceptorDerivativeContribution(i, acceptor_fact, b + idx, bdim, kap);

      col++;
      idx += bdim;
   }

   return col;
}
