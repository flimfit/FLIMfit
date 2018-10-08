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
#include "ParameterConstraints.h"


#include <stdio.h>
#include <boost/lexical_cast.hpp>

KappaFactor::KappaFactor(int n) :
   n(n), f(n), p(n)
{
   if (n == 1)
   {
      f[0] = 1;
      p[0] = 1;
   }
   else
   {
      double logf0 = -5;
      double logf4 = std::log10(4);
      double dlogf = (logf4 - logf0) / n;

      double p0 = log(2.0 + sqrt(3.0)) / sqrt(3.0);
      for (int i = 0; i < n; i++)
      {
         double f0 = std::pow(10, i * dlogf + logf0);
         double f1 = std::pow(10, (i + 1) * dlogf + logf0);
         f[i] = 0.5 * (f0 + f1);

         p[i] = p0 * (sqrt(f1) - sqrt(f0));
         if (f0 >= 1.0)
            p[i] -= ((sqrt(f1)*log(sqrt(f1) + sqrt(f1 - 1)) - sqrt(f1 - 1)) -
            (sqrt(f0)*log(sqrt(f0) + sqrt(f0 - 1)) - sqrt(f0 - 1))) / sqrt(3.0);
      }
   }
}


FretDecayGroup::FretDecayGroup(int n_donor_exponential, int n_fret_populations, bool include_donor_only) :
   MultiExponentialDecayGroupPrivate(n_donor_exponential, true, "FRET Decay"),
   n_fret_populations(n_fret_populations),
   include_donor_only(include_donor_only),
   kappa_factor(n_kappa)
{   
   std::vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };
   std::vector<ParameterFittingType> fixed = { Fixed };
   A_parameter = std::make_shared<FittingParameter>("A", 1, 1, fixed, Fixed);
   Q_parameter = std::make_shared<FittingParameter>("Q", 1, 0, 4, 1, fixed_or_global, Fixed, TransformType::Exponential);
   Qsigma_parameter = std::make_shared<FittingParameter>("Qsigma", 0.1, 0, 4, 1, fixed_or_global, Fixed, TransformType::Exponential);
   setupParameters();
}

FretDecayGroup::FretDecayGroup(const FretDecayGroup& obj) : 
   MultiExponentialDecayGroupPrivate(obj),
   kappa_factor(n_kappa)
{
   n_fret_populations = obj.n_fret_populations;
   include_donor_only = obj.include_donor_only;
   include_acceptor = obj.include_acceptor;
   n_acceptor_exponential_requested = obj.n_acceptor_exponential_requested;
   n_acceptor_exponential = obj.n_acceptor_exponential;
   A_parameter = obj.A_parameter;
   Q_parameter = obj.Q_parameter;
   Qsigma_parameter = obj.Qsigma_parameter;
   tauA_parameters = obj.tauA_parameters;
   betaA_parameters = obj.betaA_parameters;
   tauT_parameters = obj.tauT_parameters;
   acceptor_channel_factors = obj.acceptor_channel_factors;
   use_static_model = obj.use_static_model;

   setupParameters();
   init();
}

void FretDecayGroup::setupParameters()
{
   setupParametersMultiExponential();

   parameters.push_back(A_parameter);
   resizeLifetimeParameters(tauT_parameters, n_fret_populations, "tauT_");

   n_acceptor_exponential = 0;
   if (include_acceptor)
   {
      n_acceptor_exponential = n_acceptor_exponential_requested;
      parameters.push_back(Q_parameter);
      parameters.push_back(Qsigma_parameter);

      resizeLifetimeParameters(tauA_parameters, n_acceptor_exponential, "tauA_", 4000);
      std::vector<ParameterFittingType> fixed = { Fixed };
      resizeContributionParameters(betaA_parameters, n_acceptor_exponential, "betaA_", fixed);
   }


   channel_factor_names.clear();
   channel_factor_names.push_back("Donor");
   if (include_acceptor)
      channel_factor_names.push_back("Acceptor");

   parametersChanged();
}

void FretDecayGroup::init()
{
   for (auto& b : betaA_parameters)
      if (b->isFittedGlobally())
         throw std::runtime_error("Fitting betaA parameters in FRET model not currently implemented");

   MultiExponentialDecayGroupPrivate::init();

   n_kappa = use_static_model ? 120 : 1;
   kappa_factor = KappaFactor(n_kappa);

   n_lin_components = n_fret_populations + include_donor_only;

   for (auto& p : tauT_parameters)
      n_nl_parameters += p->isFittedGlobally();
   
   if (include_acceptor)
   {
      n_nl_parameters += Q_parameter->isFittedGlobally();
      n_nl_parameters += Qsigma_parameter->isFittedGlobally();
      for (auto& p : tauA_parameters)
         n_nl_parameters += p->isFittedGlobally();
   }

   fret_buffer.clear();
   fret_buffer.resize(n_fret_populations);
   for (int i = 0; i < n_fret_populations; i++)
   {
      fret_buffer[i].resize(n_kappa);
      for (int j = 0; j < n_kappa; j++)
         fret_buffer[i][j] = AbstractConvolver::make_vector(n_exponential, dp);
   }
 
   if (include_acceptor)
   {
      acceptor_buffer = AbstractConvolver::make_vector(n_acceptor_exponential, dp);

      norm_acceptor_channel_factors.resize(dp->n_chan, 1);
      normaliseChannelFactors(acceptor_channel_factors, norm_acceptor_channel_factors);
   }
}

void FretDecayGroup::setNumExponential(int n_exponential_)
{
   n_exponential = n_exponential_;
   setupParameters();
}

void FretDecayGroup::setNumAcceptorExponential(int n_acceptor_exponential_)
{
   n_acceptor_exponential_requested = n_acceptor_exponential_;
   setupParameters();
}

void FretDecayGroup::setNumFretPopulations(int n_fret_populations_)
{
   n_fret_populations = n_fret_populations_;
   setupParameters();
}

void FretDecayGroup::setIncludeDonorOnly(bool include_donor_only_)
{
   include_donor_only = include_donor_only_;
   setupParameters();
}

void FretDecayGroup::setIncludeAcceptor(bool include_acceptor_)
{
   include_acceptor = include_acceptor_;
   setupParameters();
}

void FretDecayGroup::setUseStaticModel(bool use_static_model_)
{
   use_static_model = use_static_model_;
   setupParameters();
}


const std::vector<double>& FretDecayGroup::getChannelFactors(int index)
{
   if (index == 0)
      return channel_factors;
   else if (index == 1)
      return acceptor_channel_factors;

   throw std::runtime_error("Bad channel factor index");
}

void FretDecayGroup::setChannelFactors(int index, const std::vector<double>& channel_factors_)
{
   if (index == 0)
      channel_factors = channel_factors_;
   else if (index == 1)
      acceptor_channel_factors = channel_factors_;
   else
      throw std::runtime_error("Bad channel factor index");
}



/*
   Set up matrix indicating which parmeters affect which column.
   Each row of the matrix corresponds to a variable
*/
void FretDecayGroup::setupIncMatrix(std::vector<int>& inc, int& inc_row, int& inc_col)
{
   int n_fret_group = n_fret_populations + include_donor_only;
   int inc_col0 = inc_col;

   int* id = &inc[0];

   // Set diagonal elements of incidence matrix for variable tau's   
   for (int i = 0; i < n_exponential; i++)
   {
      if (tau_parameters[i]->isFittedGlobally())
      {
         for (int j = 0; j < n_fret_group; j++)
            inc[inc_row + (inc_col + j) * MAX_VARIABLES] = 1;
         inc_row++;
      }
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   if (n_exponential > 1)
      for (int i = 0; i < n_exponential; i++)
      {
         if (beta_parameters[i]->isFittedGlobally())
         {
            for (int j = 0; j < n_fret_group; j++)
               inc[inc_row + (inc_col + j) * MAX_VARIABLES] = 1;
            inc_row++;
         }
      }

   if (include_donor_only)
      inc_col++;

   // Set elements of incidence matrix for E derivatives
   for (int i = 0; i < n_fret_populations; i++)
   {
      if (tauT_parameters[i]->isFittedGlobally())
      {
         inc[inc_row + (inc_col + i) * MAX_VARIABLES] = 1;
         inc_row++;
      }
   }

   // Set elements of incidence matrix for Q 
   if (include_acceptor && Q_parameter->isFittedGlobally())
   {
      for (int i = include_donor_only; i < n_fret_group; i++)
         inc[inc_row + (inc_col0 + i) * MAX_VARIABLES] = 1;
      inc_row++;
   }

   // Elements for direct acceptor
   if (include_acceptor && Qsigma_parameter->isFittedGlobally())
   {
      for (int i = 0; i < n_fret_group; i++)
         inc[inc_row + (inc_col0 + i) * MAX_VARIABLES] = 1;
      inc_row++;
   }

   // Elements for tauA derivatives
   if (include_acceptor)
   {
      for (int j = 0; j < n_acceptor_exponential; j++)
      {
         if (tauA_parameters[j]->isFittedGlobally())
         {
            for (int i = 0; i < n_fret_group; i++)
               inc[inc_row + (inc_col0 + i) * MAX_VARIABLES] = 1;
            inc_row++;
         }
      }
   }

   inc_col += n_fret_populations;
}

int FretDecayGroup::setVariables(const_double_iterator param_values)
{
   int idx = MultiExponentialDecayGroupPrivate::setVariables(param_values);

   A = A_parameter->getInitialValue();

   // Set tau's for FRET
   k_transfer_0.resize(n_fret_populations);
   for (int i = 0; i<n_fret_populations; i++)
   {
      k_transfer_0[i] = tauT_parameters[i]->getTransformedValue<double>(param_values, idx);
      
      for (int k = 0; k < n_kappa; k++)
      {
         for (int j = 0; j<n_exponential; j++)
         {
            double rate = k_decay[j] + k_transfer(i, k);
            fret_buffer[i][k][j]->compute(rate, irf_idx, t0_shift);
         }
      }
   }

   if (include_acceptor)
   {
      k_A.resize(n_acceptor_exponential);
      betaA.resize(n_acceptor_exponential);
      
      Q = Q_parameter->getValue<double>(param_values, idx);
      Qsigma = Qsigma_parameter->getValue<double>(param_values, idx);

      for (int i = 0; i < n_acceptor_exponential; i++)
      {
         k_A[i] = tauA_parameters[i]->getTransformedValue<double>(param_values, idx);
         acceptor_buffer[i]->compute(k_A[i], irf_idx, t0_shift);
      }

      if (n_acceptor_exponential > 1)
         for (int i = 0; i < n_acceptor_exponential; i++)
            betaA[i] = betaA_parameters[i]->getValue<double>(param_values, idx);
      else
         betaA[0] = 1.0;
      }

   return idx;
}

double FretDecayGroup::a_star(int i, int k, int j, int m)
{
   double k_t = k_transfer(i, k);
   double a_star = k_t / (k_decay[j] + k_t - k_A[m]);

   // as (tau_DF - tauA) -> 0, a_star -> inf but terms involving a_star 
   // will cancel out so we return zero instead here to avoid an overflow
   return (abs(a_star) > 1e30) ? 0 : a_star;
}

double FretDecayGroup::k_transfer(int i, int k)
{
   return k_transfer_0[i] * kappa_factor.f[k];
}


int FretDecayGroup::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx)
{
   int output_idx = MultiExponentialDecayGroupPrivate::getNonlinearOutputs(nonlin_variables, output, nonlin_idx);

   output[output_idx++] = A_parameter->getValue<float>(nonlin_variables, nonlin_idx);

   float_iterator output_tauT = output + output_idx;
   for (int i = 0; i < n_fret_populations; i++)
      output[output_idx++] = tauT_parameters[i]->getValue<float>(nonlin_variables, nonlin_idx);

   if (include_acceptor)
   {
      output[output_idx++] = Q_parameter->getValue<float>(nonlin_variables, nonlin_idx);
      output[output_idx++] = Qsigma_parameter->getValue<float>(nonlin_variables, nonlin_idx);
      for(auto& p : tauA_parameters)
         output[output_idx++] = p->getValue<float>(nonlin_variables, nonlin_idx);
   }

   float_iterator tau = output;
   float_iterator beta = output + n_exponential;
   for (int i = 0; i < n_fret_populations; i++)
   {
      float E = 0;
      float tauDF2 = 0;
      float tauDF = 0;
      for (int j = 0; j < n_exponential; j++)
      {
         float b = (n_exponential > 1) ? beta[j] : 1; // we only have beta reported if n_exp > 1
         for (int k = 0; k < kappa_factor.n; k++)
         {
            float tauDFi = 1.0f / (1.0f / tau[j] + kappa_factor.f[k] / output_tauT[i]);
            float Ei = 1.0f - tauDFi / tau[j];
            E += Ei * b * kappa_factor.p[k];
            tauDF += tauDFi * b * kappa_factor.p[k];
            tauDF2 += tauDFi * tauDFi * b * kappa_factor.p[k];
         }
      }
      output[output_idx++] = E;
      output[output_idx++] = tauDF2 / tauDF;
   }

   return output_idx;
}


int FretDecayGroup::getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx)
{
   int output_idx = 0;

   int n_fret_group = include_donor_only + n_fret_populations;
   output_idx += normaliseLinearParameters(lin_variables, n_fret_group, output + output_idx, lin_idx);

   return output_idx;
}

std::vector<std::string> FretDecayGroup::getLinearOutputParamNames()
{
   std::vector<std::string> names;
   names.push_back("I_0");

   int n = n_fret_populations + include_donor_only;

   if (n > 1)
   {
      if (include_donor_only)
         names.push_back("gamma_0");

      if (n)
         for (int i = 0; i < n_fret_populations; i++)
         {
            std::string name = "gamma_" + boost::lexical_cast<std::string>(i + 1);
            names.push_back(name);
         }
   }
   return names;
}

std::vector<std::string> FretDecayGroup::getNonlinearOutputParamNames()
{
   auto names = AbstractDecayGroup::getNonlinearOutputParamNames();
   
   for (int i = 0; i < n_fret_populations; i++)
   {
      std::string E_name = "E_" + boost::lexical_cast<std::string>(i + 1);
      names.push_back(E_name);

      std::string tauDF_name = "tauDF_" + boost::lexical_cast<std::string>(i + 1);
      names.push_back(tauDF_name);
   }

   return names;
}


int FretDecayGroup::calculateModel(double_iterator a, int adim, double& kap)
{
   int col = 0;

   if (include_donor_only)
   {
      addDecayGroup(buffer, 1, a + col*adim, adim, kap);
      for (int m = 0; m < n_acceptor_exponential; m++)
         acceptor_buffer[m]->addDecay(Qsigma * betaA[m], norm_acceptor_channel_factors, reference_lifetime, a + col*adim);
      col++;
   }

   for (int i = 0; i < fret_buffer.size(); i++)
   {
      for(int k=0; k<n_kappa; k++)
         addDecayGroup(fret_buffer[i][k], kappa_factor.p[k], a + col*adim, adim, kap);
      
      addAcceptorContribution(i, Q, a + col * adim, adim, kap);
      for (int m = 0; m < n_acceptor_exponential; m++)
         acceptor_buffer[m]->addDecay(Qsigma * betaA[m], norm_acceptor_channel_factors, reference_lifetime, a + col*adim);
    
      //TODO: kap += kappaLim(tau_transfer[i]);
      col++;
   }

   for (int m = 0; m < n_acceptor_exponential; m++)
      kap += 0; // TOOD: kappaLim(1 / k_A[m]);

   // Scale for brightness
   for (int i = 0; i < col*adim; i++)
      a[i] *= A;

   return col;
}

void FretDecayGroup::addAcceptorContribution(int i, double factor, double_iterator a, int adim, double& kap)
{
   if (include_acceptor)
   {
      for (int j = 0; j < n_exponential; j++)
         for (int k = 0; k < n_kappa; k++)
         {
            double a_star_sum = 0;
            for (int m = 0; m < n_acceptor_exponential; m++)
               a_star_sum -= betaA[m] * a_star(i, k, j, m);
            fret_buffer[i][k][j]->addDecay(a_star_sum * factor * kappa_factor.p[k] * beta[j], norm_acceptor_channel_factors, reference_lifetime, a); // rise time
         }

      for (int m = 0; m < n_acceptor_exponential; m++)
      {
         double a_star_sum = 0;
         for (int j = 0; j < n_exponential; j++)
            for (int k = 0; k < n_kappa; k++)
               a_star_sum += kappa_factor.p[k] * beta[j] * a_star(i,k,j,m);
         acceptor_buffer[m]->addDecay(a_star_sum * factor * betaA[m], norm_acceptor_channel_factors, reference_lifetime, a);
      }
   }
}

void FretDecayGroup::addAcceptorDerivativeContribution(int i, int j, int k, int m, double fact, double_iterator b, int bdim, double& kap_derv)
{
   double f = fact * a_star(i, k, j, m);
   fret_buffer[i][k][j]->addDecay(-f, norm_acceptor_channel_factors, reference_lifetime, b); // rise time
   acceptor_buffer[m]->addDecay(f, norm_acceptor_channel_factors, reference_lifetime, b);
}


int FretDecayGroup::calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   for (int i = 0; i < n_exponential; i++)
   {
      if (tau_parameters[i]->isFittedGlobally())
      {
         if (include_donor_only)
            col += addLifetimeDerivative(i, b + col*bdim, bdim);
         col += addLifetimeDerivativesForFret(i, b + col*bdim, bdim, kap_derv);
         addLifetimeKappaDerivative(i, kap_derv);
      }
   }

   // TODO: if we add kappa here, need to sort out col -> iv referencing
   col += addContributionDerivativesForFret(b + col*bdim, bdim, kap_derv);
   col += addFretEfficiencyDerivatives(b + col*bdim, bdim, kap_derv);

   if (include_acceptor)
   {
      col += addAcceptorIntensityDerivatives(b + col*bdim, bdim, kap_derv);
      col += addDirectAcceptorDerivatives(b + col*bdim, bdim, kap_derv);
      col += addAcceptorLifetimeDerivatives(b + col*bdim, bdim, kap_derv);
   }

   // Scale for brightness
   for (int i = 0; i < col*bdim; i++)
      b[i] *= A;


   return col;
}



int FretDecayGroup::addLifetimeDerivativesForFret(int j, double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   int idx = 0;

   // d(fret)/d(tau)
   for (int i = 0; i<n_fret_populations; i++)
   {
      for (int k = 0; k < n_kappa; k++)
      {
         double fact_k = beta[j] * kappa_factor.p[k];

         fret_buffer[i][k][j]->addDerivative(fact_k, norm_channel_factors, reference_lifetime, b + idx);

         double a_star_sum = 0;
         for (int m = 0; m < n_acceptor_exponential; m++)
         {
            double acceptor_fact = Q * a_star(i, k, j, m) * fact_k * betaA[m];
            a_star_sum += acceptor_fact;
            addAcceptorDerivativeContribution(i, j, k, m, - acceptor_fact / k_transfer(i,k), b + idx, bdim, kap_derv[col]);
         }
         fret_buffer[i][k][j]->addDerivative(-a_star_sum, norm_acceptor_channel_factors, reference_lifetime, b + idx);

      }

      col++;
      idx += bdim;
   }

   return col;
}

int FretDecayGroup::addContributionDerivativesForFret(double_iterator b, int bdim, double_iterator& kap_derv)
{
   if (n_exponential < 2)
      return 0;

   int col = 0;
   int n_fret_group = n_fret_populations + include_donor_only;

   int ji = 0;
   for (int j = 0; j < n_exponential; j++)
      if (beta_parameters[j]->isFittedGlobally())
      {
         for (int i = 0; i < n_fret_group; i++)
         {
            int qi = ji;
            for (int q = j; q < n_exponential; q++)
               if (!beta_parameters[q]->isFixed())
               {
                  for (int k = 0; k < n_kappa; k++)
                  {
                     double factor = beta_derv(n_beta_free, ji, qi, beta_param_values) * (1 - fixed_beta);
                     if (i == 0 && k == 0 && include_donor_only)
                     {
                        buffer[q]->addDecay(factor, norm_channel_factors, reference_lifetime, b + col*bdim);
                     }
                     else if (i > 0 || !include_donor_only)
                     {
                        double factor_k = factor * kappa_factor.p[k];
                        int fret_idx = i - include_donor_only;
                        fret_buffer[fret_idx][k][q]->addDecay(factor_k, norm_channel_factors, reference_lifetime, b + col*bdim);
                        for (int m = 0; m < n_acceptor_exponential; m++)
                        {
                           double f = Q * factor_k * a_star(fret_idx, k, q, m) * betaA[m];
                           fret_buffer[fret_idx][k][q]->addDecay(-f, norm_acceptor_channel_factors, reference_lifetime, b + col * bdim); // rise time
                           acceptor_buffer[m]->addDecay(f, norm_acceptor_channel_factors, reference_lifetime, b + col * bdim);
                        }
                     }
                  }
                  qi++;
               }
            col++;
         }
         kap_derv++;
         ji++;
      }

   return col;
}

int FretDecayGroup::addFretEfficiencyDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   int idx = 0;

   for (int i = 0; i<n_fret_populations; i++)
   {
      if (tauT_parameters[i]->isFittedGlobally())
      {
         for (int k = 0; k < n_kappa; k++)
         {
            for (int j = 0; j < n_exponential; j++)
            {
               double k_t = k_transfer(i, k);
               double fact = beta[j] * kappa_factor.f[k] * kappa_factor.p[k];
               fret_buffer[i][k][j]->addDerivative(fact, norm_channel_factors, reference_lifetime, b + idx);

               double a_star_sum = 0;
               for (int m = 0; m < n_acceptor_exponential; m++)
               {
                  double f = fact * Q * a_star(i,k,j,m) * betaA[m];
                  a_star_sum += f;

                  double acceptor_fact = - f * (k_A[m] - k_decay[j]) / (k_t * k_t);
                  addAcceptorDerivativeContribution(i, j, k, m, acceptor_fact, b + idx, bdim, *kap_derv);
               }
               fret_buffer[i][k][j]->addDerivative(-a_star_sum, norm_acceptor_channel_factors, reference_lifetime, b + idx);

            }
         }

//         *kap_derv = -kappaLim(tau_transfer[i]);


         col++;
         idx += bdim;
         kap_derv++;
      }
   }

   return col;
}

int FretDecayGroup::addDirectAcceptorDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   int idx = 0;

   if (Qsigma_parameter->isFittedGlobally())
   {
      int n_fret_group = n_fret_populations + include_donor_only;
      for (int i = 0; i < n_fret_group; i++)
      {
         for(int m=0; m<n_acceptor_exponential; m++)
            acceptor_buffer[m]->addDecay(Qsigma * betaA[m], norm_acceptor_channel_factors, reference_lifetime, b + idx);

         col++;
         idx += bdim;
      }
      kap_derv++;
   }

   return col;
}


int FretDecayGroup::addAcceptorIntensityDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   int idx = 0;

   if (Q_parameter->isFittedGlobally())
   {
      for (int i = 0; i < n_fret_populations; i++)
      {
         addAcceptorContribution(i, Q, b + idx, bdim, kap_derv[col]);
         
         col++;
         idx += bdim;
      }
      kap_derv++;
   }

   return col;
}


int FretDecayGroup::addAcceptorLifetimeDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   int col = 0;
   int idx = 0;

   for(int m = 0; m<n_acceptor_exponential; m++)
      if (tauA_parameters[m]->isFittedGlobally())
      {
         if (include_donor_only)
         {
            acceptor_buffer[m]->addDerivative(betaA[m] * Qsigma, norm_acceptor_channel_factors, reference_lifetime, b + idx);

            col++;
            idx += bdim;
         }
         
         for (int i = 0; i < n_fret_populations; i++)
         {
            double acceptor_sum = 0;
            for (int j = 0; j < n_exponential; j++)
            {
               for (int k = 0; k < n_kappa; k++)
               {
                  double fact = betaA[m] * beta[j] * Q * a_star(i,k,j,m) * kappa_factor.p[k];
                  acceptor_sum += fact;

                  addAcceptorDerivativeContribution(i, j, k, m, fact / k_transfer(i,k), b + idx, bdim, *kap_derv);
               }
            }

            acceptor_buffer[m]->addDerivative(acceptor_sum, norm_acceptor_channel_factors, reference_lifetime, b + idx);
            acceptor_buffer[m]->addDerivative(betaA[m] * Qsigma, norm_acceptor_channel_factors, reference_lifetime, b + idx);

            col++;
            idx += bdim;

         }
         kap_derv++;
      }

   return col;
}
