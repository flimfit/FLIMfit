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

#include "DecayModel.h"
#include <iostream>
#include <algorithm>

using namespace std;

DecayModel::DecayModel()
{
   std::vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };
   std::vector<ParameterFittingType> fixed = { Fixed };
   reference_parameter = std::make_shared<FittingParameter>("ref_lifetime", 100, 1e-3, fixed, Fixed);
   t0_parameter = std::make_shared<FittingParameter>("t0", 0, 1, fixed_or_global, Fixed);

   parameters = { t0_parameter };
}

DecayModel::DecayModel(const DecayModel &obj) :
   reference_parameter(obj.reference_parameter),
   t0_parameter(obj.t0_parameter),
   photons_per_count(obj.photons_per_count),
   channel_factor(obj.channel_factor),
   use_spectral_correction(obj.use_spectral_correction),
   spectral_correction(obj.spectral_correction),
   zernike_order(obj.zernike_order),
   n_derivatives(obj.n_derivatives)
{
   setTransformedDataParameters(obj.dp);
   for (auto& g : obj.decay_groups)
      decay_groups.emplace_back(g->clone());

   init();
}


void DecayModel::setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp_)
{
   dp = dp_;
   for (auto g : decay_groups)
      g->setTransformedDataParameters(dp);

   if (!dp) return;

   n_chan = dp->n_chan;
   spectral_correction.resize(dp->n_chan - 1);
   setupSpectralCorrection();

   photons_per_count = static_cast<float>(1.0 / dp->counts_per_photon);
}

void DecayModel::setupSpectralCorrection()
{
   parameters = { t0_parameter };

   if (use_spectral_correction)
   {
      int ns = max(0, n_chan - 1);
      spectral_correction.resize(ns);
      for (int c = 0; c < spectral_correction.size(); c++)
      {
         if (!spectral_correction[c])
            spectral_correction[c] = std::make_shared<Aberration>(c + 1, zernike_order);

         if (dp)
            spectral_correction[c]->setTransformedDataParameters(dp);

         auto& s_params = spectral_correction[c]->getParameters();
         parameters.insert(parameters.end(), s_params.begin(), s_params.end());
      }
   }
   else
   {
      spectral_correction.clear();
   }
}

void DecayModel::setUseSpectralCorrection(bool use_spectral_correction_)
{ 
   use_spectral_correction = use_spectral_correction_; 
   setupSpectralCorrection();
}

void DecayModel::setZernikeOrder(int zernike_order_)
{ 
   zernike_order = zernike_order_;
   for (auto& s : spectral_correction)
      s->setOrder(zernike_order);
   setupSpectralCorrection();
}



void DecayModel::setNumChannels(int n_chan_)
{
   n_chan = n_chan_;

   if (dp) return;

   setupSpectralCorrection();

   for (auto g : decay_groups)
      g->setNumChannels(n_chan);
}

void DecayModel::init()
{
   if (dp->irf == nullptr)
      throw std::runtime_error("No IRF loaded");
   
   if (dp->n_chan != dp->irf->getNumChan())
      throw std::runtime_error("IRF must have the same number of channels as the data");
   
   last_variables.clear();

   for (auto g : decay_groups)
      g->init();
   
   setupAdjust();
}


void DecayModel::addDecayGroup(std::shared_ptr<AbstractDecayGroup> group)
{
   group->setTransformedDataParameters(dp);
   decay_groups.push_back(group);
}

void DecayModel::decayGroupUpdated()
{
//   emit Updated();
}


int DecayModel::getNumColumns()
{
   int n_columns = 0;
   for (auto& group : decay_groups)
      n_columns += group->getNumComponents();

   return n_columns;
}

int DecayModel::getNumNonlinearVariables()
{
   int n_nonlinear = 0;
   for (auto& group : decay_groups)
      n_nonlinear += group->getNumNonlinearParameters();

   n_nonlinear += std::count_if(parameters.begin(), parameters.end(), 
      [](auto& p) { return p->isFittedGlobally(); });

   return n_nonlinear;
}


double DecayModel::getCurrentReferenceLifetime(const_double_iterator& param_values, int& idx)
{
   if (dp->irf->type != Reference)
      return 0;

   return reference_parameter->getValue<double>(param_values, idx);
}


void DecayModel::setupAdjust()
{
   adjust_buf.resize(dp->n_meas);

   for (int i = 0; i < dp->n_meas; i++)
      adjust_buf[i] = 0;

   for (auto& group : decay_groups)
      group->addConstantContribution(adjust_buf.begin());

   for (int i = 0; i < dp->n_meas; i++)
      adjust_buf[i] *= photons_per_count;
}

void DecayModel::getOutputParamNames(std::vector<std::string>& param_names, std::vector<int>& param_group, int& n_nl_output_params, int& n_lin_output_params)
{
   for (auto& p : parameters)
      if (p->isFittedGlobally())
      {
         param_names.push_back(p->name);
         param_group.push_back(0);
      }

   for (int i=0; i<decay_groups.size(); i++)
   {
      std::string prefix = "G" + std::to_string(i+1) + "_";
      auto group_param_names = decay_groups[i]->getNonlinearOutputParamNames();
      for (auto& name : group_param_names)
      {
         param_names.push_back(prefix + name);
         param_group.push_back(i+1);
      }
   }
      
   n_nl_output_params = (int) param_names.size();

   for (int i = 0; i<decay_groups.size(); i++)
   {
      std::string prefix = "G" + std::to_string(i+1) + "_";
      auto group_param_names = decay_groups[i]->getLinearOutputParamNames();
      for (auto& name : group_param_names)
      {
         param_names.push_back(prefix + name);
         param_group.push_back(i + 1);
      }
   }

   n_lin_output_params = (int) param_names.size() - n_nl_output_params;

}

/*
Set up matrix indicating which parmeters affect which column.
Each row of the matrix corresponds to a variable
*/
void DecayModel::setupIncMatrix(std::vector<int>& inc)
{
   // Clear inc and ensure correct size
   inc.resize(INC_ENTRIES);
   std::fill(inc.begin(), inc.end(), 0);

   // Set up inc matrix for groups in buffer
   int g_row = 0, col = 0;
   std::vector<int> group_inc(INC_ENTRIES, 0);
   for (auto& group : decay_groups)
      group->setupIncMatrix(group_inc, g_row, col);

   // Setup t0 and spectral correction parameters which affect each column

   int row = 0;
   if (t0_parameter->isFittedGlobally())
   {
      for (int i = 0; i<col; i++)
         inc[row + i * MAX_VARIABLES] = 1;
      row++;
   }

   for (auto& s : spectral_correction)
      s->setupIncMatrix(inc, row, col);

   // Copy entries from group inc matrix into main inc matrix
   for (int r = 0; r < g_row; r++)
      for (int c = 0; c < col; c++)
         inc[(r + row) + c * MAX_VARIABLES] = group_inc[r + c * MAX_VARIABLES];

   n_derivatives = std::count(inc.begin(), inc.end(), 1);
}

int DecayModel::getNumDerivatives()
{
   if (n_derivatives == -1)
      throw std::runtime_error("Please setup inc matrix before requesting number of derivatives");
   return n_derivatives;
}

bool DecayModel::isSpatiallyVariant()
{
   return use_spectral_correction && (zernike_order > 1);
}

void DecayModel::setVariables(const std::vector<double>& alf)
{
   auto param_values = alf.begin();

   int getting_fit = false; //TODO 

   int idx = 0;
   reference_lifetime = getCurrentReferenceLifetime(param_values, idx);
   t0_shift = t0_parameter->getValue<double>(param_values, idx);

   for (auto& s : spectral_correction)
      idx += s->setVariables(param_values + idx);

   // Disable caching for now
   last_variables.clear();
   last_variables.resize(decay_groups.size());

   for (int i = 0; i < decay_groups.size(); i++)
   {
      decay_groups[i]->setT0Shift(t0_shift);
      decay_groups[i]->setReferenceLifetime(reference_lifetime);

      int n_var = -1;
      if (!last_variables[i].empty())
      {
         n_var = (int) last_variables[i].size();
         for (int j = 0; j < n_var; j++)
            if (last_variables[i][j] != alf[idx + j])
               n_var = -1;
      }
      if (n_var == -1)
      {
         n_var = decay_groups[i]->setVariables(param_values + idx);
         last_variables[i].resize(n_var);
         std::copy_n(param_values + idx, n_var, last_variables[i].begin());
      }
      idx += n_var;

      decay_groups[i]->precompute();
   }

}

int DecayModel::calculateModel(double_iterator a, int adim, double_iterator kap, int irf_idx)
{
   int idx = 0;
   int col = 0;

   size_t n_cols = getNumColumns();
   std::fill_n(a, n_cols * adim, 0);

   for (int i = 0; i < decay_groups.size(); i++)
   {
      decay_groups[i]->setIRFPosition(irf_idx);
      col += decay_groups[i]->calculateModel(a + col * adim, adim, kap[0]);
   }

   // Apply scaling to convert counts -> photons
   for (int i = 0; i < adim*(col + 1); i++)
      a[i] *= photons_per_count;
 
   int x = irf_idx % dp->n_x;
   int y = irf_idx / dp->n_x;

   for (auto& s : spectral_correction)
      s->apply(x, y, a, adim, col + 1);

   return col;
}

int DecayModel::calculateDerivatives(double_iterator b, int bdim, const_double_iterator a, int adim, int n_col, double_iterator kap, int irf_idx)
{
   int col = 0;
   int var = 0;

   std::fill_n(b, n_derivatives * bdim, 0);

   double_iterator kap_derv = kap + 1; // TODO tidy this a bit

   /*
   if (irf->ref_reconvolution == FIT_GLOBALLY)
   col += AddReferenceLifetimeDerivatives(wb, ref_lifetime, b.data() + col*bdim, bdim);
   */

   if (t0_parameter->isFittedGlobally())
      col += addT0Derivatives(b + col*bdim, bdim, kap_derv);

   int x = irf_idx % dp->n_x;
   int y = irf_idx / dp->n_x;
   for (auto& s : spectral_correction)
      col += s->calculateDerivatives(x, y, a, adim, n_col, b + col * bdim, bdim);

   int model_col = col;

   for (int i = 0; i < decay_groups.size(); i++)
      col += decay_groups[i]->calculateDerivatives(b + col*bdim, bdim, kap_derv);

   for (auto& s : spectral_correction)
      s->apply(x, y, b + bdim * model_col, bdim, col - model_col);

   for (int i = model_col*bdim; i < col*bdim; i++)
      b[i] *= photons_per_count;

   return col;
}


int DecayModel::addT0Derivatives(double_iterator b, int bdim, std::vector<double>::iterator& kap_derv)
{
   // Compute numerical derivatives for t0

   double kap = 0;
   double dt = 10;

   // Add decay shifted by one bin
   int col = 0;
   for (int i = 0; i < decay_groups.size(); i++)
   {
      decay_groups[i]->setT0Shift(t0_shift + dt);
      decay_groups[i]->precompute();
      col += decay_groups[i]->calculateModel(b + col * bdim, bdim, kap);
   }

   // Make negative
   for (int i = 0; i<bdim*col; i++)
      b[i] *= -1;

   // Add decay shifted the other way
   col = 0;
   for (int i = 0; i < decay_groups.size(); i++)
   {
      decay_groups[i]->setT0Shift(t0_shift);
      decay_groups[i]->precompute();
      col += decay_groups[i]->calculateModel(b + col * bdim, bdim, kap);

   }

   for (int i = 0; i<bdim*col; i++)
      b[i] /= -dt;

   return col;
}


int DecayModel::addReferenceLifetimeDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   //TODO - reference lifetime derivatives
   /*
   double fact;

   int n_col = n_pol_group * (beta_global ? 1 : n_exp);
   for (int i = 0; i<n_col; i++)
      memset(b + i*bdim, 0, bdim*sizeof(*b));

   for (int p = 0; p<n_pol_group; p++)
   {
      for (int g = 0; g<n_fret_group; g++)
      {
         int idx = (g + p*n_fret_group)*bdim;
         int cur_decay_group = 0;

         for (int j = 0; j<n_exp; j++)
         {
            if (beta_global && decay_group[j] > cur_decay_group)
            {
               idx += bdim;
               cur_decay_group++;
            }

            fact = -1 / (ref_lifetime * ref_lifetime);
            fact *= beta_global ? wb.beta_buf[j] : 1;

            //wb.add_decay(j, p, g, fact, 0, b+idx);

            if (!beta_global)
               idx += bdim;
         }
      }
   }

   return n_col;
   */

   return 0;
}


void DecayModel::getWeights(float_iterator y, float_iterator a, const std::vector<double>& alf, float_iterator lin_params, double_iterator w, int irf_idx)
{
   return;

   // TODO - finish this
   /*

   int i, l_start;
   double F0, ref_lifetime;
   
   if (irf->ref_reconvolution && lin_params != NULL)
   {
      if (irf->ref_reconvolution == FIT_GLOBALLY)
         ref_lifetime = alf[alf_ref_idx];
      else
         ref_lifetime = irf->ref_lifetime_guess;


      // Don't include stray light in weighting
      l_start = (fit_offset == FIT_LOCALLY) +
         (fit_scatter == FIT_LOCALLY) +
         (fit_tvb == FIT_LOCALLY);

      F0 = 0;
      for (i = l_start; i<l; i++)
         F0 = lin_params[i];

      for (i = 0; i<n_meas; i++)
         w[i] /= ref_lifetime;

      AddIRF(irf_buf.data(), irf_idx, 0, w, n_r, &F0); // TODO: t0_shift?

      // Variance = (D + F0 * D_r);

   }
   */
}




void DecayModel::getInitialVariables(std::vector<double>& param, double mean_arrival_time)
{
   auto cur_param = param.begin();

   int idx = 0;
   for (auto& p : parameters)
      if (p->isFittedGlobally())
         param[idx++] = p->getTransformedInitialValue();

   for (auto& g : decay_groups)
      idx += g->getInitialVariables(param.begin()+idx);
}


int DecayModel::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator outputs)
{
   int idx = 0;
   int nonlin_idx = 0;

   for (auto& p : parameters)
      if (p->isFittedGlobally())
         outputs[idx++] = nonlin_variables[nonlin_idx++];


   for (auto& g : decay_groups)
      idx += g->getNonlinearOutputs(nonlin_variables, outputs + idx, nonlin_idx);

   return idx;
}

int DecayModel::getLinearOutputs(float_iterator lin_variables, float_iterator outputs)
{
   int idx = 0;
   int lin_idx = 0;

   for (auto& g : decay_groups)
      idx += g->getLinearOutputs(lin_variables, outputs + idx, lin_idx);

   return idx;
}

const std::vector<std::shared_ptr<FittingParameter>> DecayModel::getAllParameters()
{
   auto params = parameters;

   for (auto& g : decay_groups)
   {
      auto& group_params = g->getParameters();
      for (auto& p : group_params)
         params.push_back(p);
   }

   return params;
}



void DecayModel::getParameterIntensityIndices(std::vector<size_t>& linear, std::vector<size_t>& nonlinear)
{
   linear.clear();
   nonlinear.clear();

   for (auto& p : parameters)
      if (p->isFittedGlobally())
         nonlinear.push_back(-1); 

   size_t n_linear = 0;
   for (auto& g : decay_groups)
   {
      size_t n_group_nonlinear = g->getNonlinearOutputParamNames().size();
      size_t n_group_linear = g->getLinearOutputParamNames().size();

      for (size_t i = 0; i<n_group_nonlinear; i++)
         nonlinear.push_back(n_linear);
      for (size_t i = 0; i<n_group_linear; i++)
         linear.push_back(n_linear);

      n_linear += n_group_linear;
   }
}


/*
* Based on fortran77 subroutine CHKDER by
* Burton S. Garbow, Kenneth E. Hillstrom, Jorge J. More
* Argonne National Laboratory. MINPACK project. March 1980.
*/
void DecayModel::validateDerivatives()
{
   double factor = 100;
   double epsmch = std::numeric_limits<double>::epsilon();
   double eps = sqrt(epsmch);
   double epsf = factor*epsmch;
   double epslog = log10(eps);

   std::vector<int> inc(INC_ENTRIES);
   setupIncMatrix(inc);

   int n_nonlinear = getNumNonlinearVariables();
   int n_cols = getNumColumns();
   int n_der = getNumDerivatives();

   int dim = dp->n_meas;

   aligned_vector<double> a(dim * (n_cols + 1));
   aligned_vector<double> ap(dim * (n_cols + 1)); 
   aligned_vector<double> b(dim*n_der);
   std::vector<double> err(dim);
   std::vector<double> bobs(dim);
   std::vector<double> kap(1+n_nonlinear+100);

   std::vector<double> alf(n_nonlinear);
   getInitialVariables(alf, 2000);
   
   setVariables(alf);
   int n_col_real = calculateModel(a.begin(), dim, kap.begin(), 0);
   int n_der_real = calculateDerivatives(b.begin(), dim, a.begin(), dim, n_col_real, kap.begin(), 0);

   if (n_col_real != n_cols)
      throw std::runtime_error("Incorrect number of columns in model");
   if (n_der_real != n_der)
      throw std::runtime_error("Incorrect number of derivatives in model");

   std::vector<std::string> names;
   for (auto& p : parameters)
      if (p->isFittedGlobally())
         names.push_back(p->name);
   for (auto& g : decay_groups)
      for (auto& p : g->getParameters())
         if (p->isFittedGlobally())
            names.push_back(p->name);

   bool pass = true;
   int m = 0;
   for (int i = 0; i < n_nonlinear; i++)
      for (int j = 0; j < n_cols; j++)
      {
         if (inc[i + j * MAX_VARIABLES])
         {
            std::vector<double> alf_p(alf);

            double temp = eps * abs(alf[i]);
            if (temp == 0.0) temp = eps;
            alf_p[i] += temp;

            setVariables(alf_p);
            calculateModel(ap.begin(), dim, kap.begin(), 0);

            double_iterator fvec = a.begin() + dim * j;
            double_iterator fvecp = ap.begin() + dim * j;
            double_iterator fjac = b.begin() + dim * m;

            for (int k = 0; k<dim; ++k)
               err[k] = 0.0;

            double alf_t = abs(alf[i]);
            if (alf_t == 0.0) alf_t = 1.0;

            for (int k = 0; k<dim; ++k)
               err[k] += alf_t * fjac[k];

            for (int k = 0; k<dim; ++k)
            {
               bobs[k] = (fvecp[k] - fvec[k]) / (eps * alf_t);

               temp = 1.0;
               if (fvec[k] != 0.0 && fvecp[k] != 0.0 && fabs(fvecp[k] - fvec[k]) >= epsf*fabs(fvec[k]))
                  temp = eps*fabs((fvecp[k] - fvec[k]) / eps - err[k]) / (fabs(fvec[k]) + fabs(fvecp[k]));
               err[k] = 1.0;
               if (temp>epsmch && temp<eps)
                  err[k] = (log10(temp) - epslog) / epslog;
               if (temp >= eps) 
                  err[k] = 0.0;
               if (err[k] == 0.0 && ((fvec[k] - fvecp[k]) == 0.0))
                  err[k] = 1.0;
            }

            double mean_err = 0.0;
            for (int k = 0; k < dim; k++)
               mean_err += err[k];
            mean_err /= dim;

            if (mean_err < 0.5)
            {
               std::cout << "Variable: " << i << " (" << names[i] << "), Column: " << j << "\n";
               std::cout << "   Mean err : " << mean_err << "\n";
               std::cout << "   *********************************\n";
               pass = false;
            }

            m++;
         }
      }

   if (!pass)
      throw std::runtime_error("Problem with derivatives detected!");

}