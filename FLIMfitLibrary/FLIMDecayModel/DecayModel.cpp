
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

DecayModel::DecayModel(shared_ptr<AcquisitionParameters> acq) :
   acq(acq),
   reference_parameter("ref_lifetime", 100, { Fixed, FittedGlobally }, Fixed),
   t0_parameter("t0", 0, { Fixed, FittedGlobally }, Fixed)
{
   decay_groups.push_back(make_unique<BackgroundLightDecayGroup>(acq));
   decay_groups.push_back(make_unique<MultiExponentialDecayGroup>(acq, 2));
   decay_groups.push_back(make_unique<FretDecayGroup>(acq, 2, 2));
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

int DecayModel::CalculateModel(vector<double>& a, int adim, vector<double>& b, int bdim, vector<double>& kap, const vector<double>& alf, int irf_idx, int isel)
{
   int idx = 0;

   const double* param_values = alf.data();

   double reference_lifetime = GetCurrentReferenceLifetime(param_values, idx);
   double t0_shift = GetCurrentT0(param_values, idx);

   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   int getting_fit = false; //TODO

   for (int i = 0; i < decay_groups.size(); i++)
      decay_groups[i]->SetIRFPosition(irf_idx, t0_shift, reference_lifetime);


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