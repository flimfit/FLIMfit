
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

using namespace std;

DecayModel::DecayModel() :
   reference_parameter("ref_lifetime", 100, { Fixed, FittedGlobally }, Fixed),
   t0_parameter("t0", 0, { Fixed, FittedGlobally }, Fixed)
{
   //decay_groups.emplace_back(new BackgroundLightDecayGroup(acq));
   //decay_groups.emplace_back(new MultiExponentialDecayGroup(acq, 2));
   //decay_groups.emplace_back(new FretDecayGroup(acq, 2, 2));

}

void DecayModel::Init(shared_ptr<AcquisitionParameters> acq)
{
   photons_per_count = static_cast<float>(1.0 / acq->counts_per_photon);
   SetupAdjust();
}


DecayModel::DecayModel(const DecayModel &obj) :
   acq(obj.acq),
   reference_parameter(obj.reference_parameter),
   t0_parameter(obj.t0_parameter)
{
   for (auto& g : obj.decay_groups)
      decay_groups.emplace_back(g->clone());

   photons_per_count = obj.photons_per_count;
   SetupAdjust();
}

void DecayModel::AddDecayGroup(shared_ptr<AbstractDecayGroup> group)
{
   decay_groups.push_back(group);
}


int DecayModel::GetNumColumns()
{
   int n_columns = 0;
   for (auto& group : decay_groups)
      n_columns += group->GetNumComponents();

   return n_columns;
}

int DecayModel::GetNumNonlinearVariables()
{
   int n_nonlinear = 0;
   for (auto& group : decay_groups)
      n_nonlinear += group->GetNumNonlinearParameters();

   n_nonlinear += reference_parameter.IsFittedGlobally();
   n_nonlinear += t0_parameter.IsFittedGlobally();

   return n_nonlinear;
}



double DecayModel::GetCurrentReferenceLifetime(const double* param_values, int& idx)
{
   if (acq->irf->type != Reference)
      return 0;

   return reference_parameter.GetValue<double>(param_values, idx);
}

double DecayModel::GetCurrentT0(const double* param_values, int& idx)
{
   if (acq->irf->type != Reference)
      return 0;

   return t0_parameter.GetValue<double>(param_values, idx);
}


void DecayModel::SetupAdjust()
{
   adjust_buf.resize(acq->n_meas);

   for (int i = 0; i < acq->n_meas; i++)
      adjust_buf[i] *= 0;

   for (auto& group : decay_groups)
      group->AddConstantContribution(adjust_buf.data()); // TODO: this only works for background ATM, which overwrites

   for (int i = 0; i < acq->n_meas; i++)
      adjust_buf[i] *= photons_per_count;
}

void DecayModel::GetOutputParamNames(vector<string>& param_names, int& n_nl_output_params)
{
   for (auto& group : decay_groups)
      group->GetNonlinearOutputParamNames(param_names);

   for (auto& group : decay_groups)
      group->GetLinearOutputParamNames(param_names);
}

void DecayModel::SetupIncMatrix(int *inc)
{
   int row = 0;
   int col = 0;
    
   for (auto& group : decay_groups)
      group->SetupIncMatrix(inc, row, col);
}

int DecayModel::GetNumDerivatives()
{
   vector<int> inc(96);

   SetupIncMatrix(inc.data());

   int n = 0;
   for (int i = 0; i < 96; i++)
      n += inc[i];

   return n;
}

int DecayModel::CalculateModel(vector<double>& a, int adim, vector<double>& b, int bdim, vector<double>& kap, const vector<double>& alf, int irf_idx, int isel)
{
   int idx = 0;

   const double* param_values = alf.data();

   double reference_lifetime = GetCurrentReferenceLifetime(param_values, idx);
   double t0_shift = GetCurrentT0(param_values, idx);

   double scale_fact[2] = {1, 0};

   int getting_fit = false; //TODO

   for (int i = 0; i < decay_groups.size(); i++)
   {
      decay_groups[i]->SetIRFPosition(irf_idx, t0_shift, reference_lifetime);
      idx += decay_groups[i]->SetVariables(param_values + idx);
   }


   switch (isel)
   {
   case 1:
   case 2:
   {

      int col = 0;

      for (int i = 0; i < decay_groups.size(); i++)
         col += decay_groups[i]->CalculateModel(a.data() + col*adim, adim, kap);


      /*
      MOVE THIS TO MULTIEXPONENTIAL MODEL
      if (constrain_nonlinear_parameters && kap.size() > 0)
      {
         kap[0] = 0;
         for (int i = 1; i < n_v; i++)
            kap[0] += kappa_spacer(alf[i], alf[i - 1]);
         for (int i = 0; i < n_v; i++)
            kap[0] += kappa_lim(alf[i]);
         for (int i = 0; i < n_theta_v; i++)
            kap[0] += kappa_lim(alf[alf_theta_idx + i]);
      }
      */

      // Apply scaling to convert counts -> photons
      for (int i = 0; i < adim*(col + 1); i++)
         a[i] *= photons_per_count;

      if (isel == 2 || getting_fit)
         break;

   }
   case 3:
   {
      int col = 0;

      for (int i = 0; i < decay_groups.size(); i++)
         col += decay_groups[i]->CalculateDerivatives(b.data() + col*bdim, bdim, kap);

      /*
      col += AddLifetimeDerivatives(wb, ref_lifetime, b.data() + col*bdim, bdim);
      col += AddContributionDerivatives(wb, ref_lifetime, b.data() + col*bdim, bdim);

      col += AddFRETEfficencyDerivatives(wb, ref_lifetime, b.data() + col*bdim, bdim);
      col += AddRotationalCorrelationTimeDerivatives(wb, ref_lifetime, b.data() + col*bdim, bdim);

      if (irf->ref_reconvolution == FIT_GLOBALLY)
      col += AddReferenceLifetimeDerivatives(wb, ref_lifetime, b.data() + col*bdim, bdim);

      if (fit_t0 == FIT)
      col += AddT0Derivatives(wb, irf_idx, ref_lifetime, t0_shift, b.data() + col*bdim, bdim);

      col += AddOffsetDerivatives(wb, b.data() + col*bdim, bdim);
      col += AddScatterDerivatives(wb, b.data() + col*bdim, bdim, irf_idx, t0_shift);
      col += AddTVBDerivatives(wb, b.data() + col*bdim, bdim);
      */

      for (int i = 0; i < col*bdim; i++)
         b[i] *= photons_per_count;

      /*
      MOVE TO MULTIEXPONENTIAL MODEL
      if (constrain_nonlinear_parameters && kap.size() != 0)
      {
         double *kap_derv = kap.data() + 1;

         for (int i = 0; i < nl; i++)
            kap_derv[i] = 0;

         for (int i = 0; i < n_v; i++)
         {
            kap_derv[i] = -kappa_lim(wb.tau_buf[n_fix + i]);
            if (i < n_v - 1)
               kap_derv[i] += kappa_spacer(wb.tau_buf[n_fix + i + 1], wb.tau_buf[n_fix + i]);
            if (i>0)
               kap_derv[i] -= kappa_spacer(wb.tau_buf[n_fix + i], wb.tau_buf[n_fix + i - 1]);
         }
         for (int i = 0; i < n_theta_v; i++)
         {
            kap_derv[alf_theta_idx + i] = -kappa_lim(wb.theta_buf[n_theta_fix + i]);
         }


      }
      */
   }
   }

   return 0;
}


int DecayModel::AddReferenceLifetimeDerivatives(double* b, int bdim, vector<double>& kap)
{
   //TODO
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



int DecayModel::AddT0Derivatives(double* b, int bdim, vector<double>& kap)
{
   // TODO
   /*
   if (fit_t0 != FIT)
      return 0;

   // Total number of columns 
   int n_col = n_fret_group * n_pol_group * n_exp_phi;


   //flim_model(wb, irf_idx, ref_lifetime, t0_shift, false, -1, b, bdim);

   for (int i = 0; i<bdim*n_col; i++)
      b[i] *= -1;

   //flim_model(wb, irf_idx, ref_lifetime, t0_shift, false, -1, b, bdim);

   double idt = 0.5 / irf->timebin_width;
   for (int i = 0; i<bdim*n_col; i++)
      b[i] *= idt;

   return n_col;
   */
   return 0;
}


void DecayModel::GetWeights(float* y, const vector<double>& a, const vector<double>& alf, float* lin_params, double* w, int irf_idx)
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




void DecayModel::GetInitialVariables(vector<double>& param, double mean_arrival_time)
{
   // TODO: set initial tau's based on mean arrival time

   int idx = 0;
   for (auto& g : decay_groups)
      idx += g->GetInitialVariables(param.data() + idx);

   if (reference_parameter.IsFittedGlobally())
      param[idx++] = reference_parameter.initial_value;
   if (t0_parameter.IsFittedGlobally())
      param[idx++] = t0_parameter.initial_value;

}


int DecayModel::GetNonlinearOutputs(float* nonlin_variables, float* outputs)
{
   int idx = 0;
   int nonlin_idx = 0;

   for (auto& g : decay_groups)
      idx += g->GetNonlinearOutputs(nonlin_variables, outputs + idx, nonlin_idx);

   return idx;
}

int DecayModel::GetLinearOutputs(float* lin_variables, float* outputs)
{
   int idx = 0;
   int lin_idx = 0;

   for (auto& g : decay_groups)
      idx += g->GetLinearOutputs(lin_variables, outputs + idx, lin_idx);

   return idx;
}