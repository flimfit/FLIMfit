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

#include <stdio.h>
#include <boost/lexical_cast.hpp>

using namespace std;

FretDecayGroup::FretDecayGroup(int n_donor_exponential, int n_fret_populations, bool include_donor_only) :
   MultiExponentialDecayGroup(n_donor_exponential, true),
   n_fret_populations(n_fret_populations),
   include_donor_only(include_donor_only)
{
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

   fret_buffer.resize(n_fret_populations, 
      vector<ExponentialPrecomputationBuffer>(n_exponential,
         ExponentialPrecomputationBuffer(acq)));
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
         inc[inc_row + inc_col * 12] = 1;
         inc_col++;
         inc_row++;
      }
   }

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
      E[i] = E_parameters[i]->GetValue<double>(param_values, idx);

      for (int j = 0; j<n_exponential; j++)
      {
         double Ej = tau[j] / tau[0] * E[i];
         Ej = Ej / (1 - E[i] + Ej);

         tau_fret[i][j] = tau[j] * (1 - Ej);
         fret_buffer[i][j].Compute(1 / tau_fret[i][j], irf_idx, t0_shift, channel_factors, false);
      }
   }

   return idx;
}

int FretDecayGroup::GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx)
{
   int output_idx = MultiExponentialDecayGroup::GetNonlinearOutputs(nonlin_variables, output, nonlin_idx);

   for (int i = 0; i < n_fret_populations; i++)
      output[output_idx++] = E_parameters[i]->GetValue<float>(nonlin_variables, nonlin_idx);

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
      col += AddDecayGroup(buffer, a, adim, kap);

   for (int i = 0; i < fret_buffer.size(); i++)
      col += AddDecayGroup(fret_buffer[i], a, adim, kap);

   return col;
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
      //*TransformRangeDerivative(wb.tau_buf[j], tau_min[j], tau_max[j]); TODO

      fret_buffer[i][j].AddDerivative(fact, reference_lifetime, b + idx);

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
         double Ej = tau[j] / tau[0] * E[i];

         double dE = Ej / E[i];
         dE *= dE;
         dE *= tau[0] / tau[j];

         double fact = -beta[j] * tau[j] / (tau_fret[i][j] * tau_fret[i][j]) * dE;
         fret_buffer[i][j].AddDerivative(fact, reference_lifetime, b + idx);
      }

      col++;
      idx += bdim;
   }

   return col;
}
