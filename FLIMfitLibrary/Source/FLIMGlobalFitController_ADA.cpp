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

#include "ModelADA.h"
#include "DecayModel.h"
#include "ExponentialPrecomputationBuffer.h"
#include "IRFConvolution.h"

#include <cmath>
#include <algorithm>

using std::min;
using std::max;

/*
void DecayModel::SetupIncMatrix(int* inc)
{
   int i, j, n_exp_col, cur_col;

   // Set up incidence matrix
   //----------------------------------------------------------------------

   int inc_row = 0;   // each row represents a non-linear variable
   int inc_col = 0;   // each column represents a phi, eg. exp(...)

   // Set incidence matrix zero
   for(i=0; i<96; i++)
      inc[i] = 0;

      
   // Set inc for local offset if required
   // Independent of all variables
   if( fit_offset == FIT_LOCALLY )
      inc_col++;

   // Set inc for local scatter if required
   // Independent of all variables
   if( fit_scatter == FIT_LOCALLY )
      inc_col++;

   if( fit_tvb == FIT_LOCALLY )
      inc_col++;
            
   // Set diagonal elements of incidence matrix for variable tau's   
   n_exp_col = beta_global ? 1 : n_exp;
   cur_col = beta_global ? 0 : n_fix;
   for(i=n_fix; i<n_exp; i++)
   {
      if (decay_group[i] > cur_col)
         cur_col++;
      for(j=0; j<(n_pol_group*n_fret_group); j++)
         inc[inc_row + (inc_col+j*n_exp_phi+cur_col)*12] = 1;
      if (!beta_global)
         cur_col++;
      inc_row++;
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   cur_col = 0;
   for(i=0; i<n_beta; i++)
   {
      if (decay_group[i+1+cur_col] > cur_col)
         cur_col++;    
      for(j=0; j<(n_pol_group*n_fret_group); j++)
         inc[inc_row + (inc_col+j*n_exp_phi+cur_col)*12] = 1;
                        
      inc_row++;
   }

   // Variable Thetas
   for(i=0; i<n_theta_v; i++)
   {
      inc[inc_row+(inc_col+i+1+n_theta_fix)*12] = 1;
      inc_row++;
   }
         
   // Set elements of incidence matrix for E derivatives
   for(i=0; i<n_fret_v; i++)
   {
      for(j=0; j<n_exp_phi; j++)
         inc[inc_row+(inc_donor+n_fret_fix+inc_col+i*n_exp_phi+j)*12] = 1;
      inc_row++;
   }

   if (irf->ref_reconvolution == FIT_GLOBALLY)
   {
      // Set elements of inc for ref lifetime derivatives
      for(i=0; i<( n_pol_group * n_fret_group * n_exp_phi ); i++)
      {
         inc[inc_row+(inc_col+i)*12] = 1;
      }
      inc_row++;
   }

   if (fit_t0 == FIT)
   {
      for(i=0; i<( n_pol_group * n_fret_group * n_exp_phi ); i++)
      {
         inc[inc_row + i*12]++;
      }
      inc_row++;
   }

   inc_col += n_pol_group * n_fret_group * n_exp_phi;
     


   // Global offset, scatter and TVB are in col L+1

   if( fit_offset == FIT_GLOBALLY )
   {
      inc[inc_row + inc_col*12] = 1;
      inc_row++;
   }

   if( fit_scatter == FIT_GLOBALLY )
   {
      inc[inc_row + inc_col*12] = 1;
      inc_row++;
   }

   if( fit_tvb == FIT_GLOBALLY )
   {
      inc[inc_row + inc_col*12] = 1;
      inc_row++;
   }



}



double DecayModel::GetCurrentReferenceLifetime(const vector<double>& alf)
{
   double ref_lifetime;
   if (irf->ref_reconvolution == FIT_GLOBALLY)
      ref_lifetime = alf[alf_ref_idx];
   else
      ref_lifetime = irf->ref_lifetime_guess;
   return ref_lifetime;
}

double DecayModel::GetCurrentT0(const vector<double>& alf)
{
   double t0_shift;
   if (fit_t0 == FIT)
      t0_shift = alf[alf_t0_idx];
   else
      t0_shift = t0_guess;
   return t0_shift;
}
*/
/*
void DecayModel::GetCurrentLifetimes(Buffers& wb, const vector<double>& alf)
{
   // First get fixed lifetimes
   for (int j = 0; j<n_fix; j++)
      wb.tau_buf[j] = tau_guess[j];

   // Now get fitted lifetimes
   for (int j = 0; j<n_v; j++)
   {
      double buf = InverseTransformRange(alf[j], tau_min[j + n_fix], tau_max[j + n_fix]);
      wb.tau_buf[j + n_fix] = max(buf, 60.0);
   }
}

void DecayModel::GetCurrentContributions(Buffers& wb, const vector<double>& alf)
{
   // Set beta's
   if (fit_beta == FIT_GLOBALLY)
   {

      int group_start = 0;
      int group_end = 0;
      int d_idx = 0;

      for (int d = 0; d<n_decay_group; d++)
      {
         int n_group = 0;
         while (d_idx < n_exp && decay_group[d_idx] == d)
         {
            d_idx++;
            n_group++;
            group_end++;
         }
         alf2beta(n_group, alf.data() + alf_beta_idx + group_start - d, wb.beta_buf + group_start);

         group_start = group_end;

      }

   }
   else if (fit_beta == FIX)
   {
      for (int j = 0; j<n_exp; j++)
         wb.beta_buf[j] = fixed_beta[j];
   }
}
*/
/*
void DecayModel::GetCurrentRotationalCorrelationTimes(Buffers& wb, const vector<double>& alf)
{
   // First get fixed rotational correlation times
   for (int j = 0; j<n_theta_fix; j++)
      wb.theta_buf[j] = theta_guess[j];
   
   // Now get fitted rotational correlation times
   for (int j = 0; j<n_theta_v; j++)
   {
      double buf = InverseTransformRange(alf[alf_theta_idx + j], 0, 1000000);
      wb.theta_buf[j + n_theta_fix] = max(buf, 60.0);
   }
}
*/
/*
void DecayModel::CalculateCurrentFRETLifetimes(Buffers& wb, const vector<double>& alf)
{
   // Set tau's for FRET
   int idx = n_exp;
   for (int i = 0; i<n_fret; i++)
   {
      double E;
      if (i<n_fret_fix)
         E = E_guess[i];
      else
      {
         E = alf[alf_E_idx + i - n_fret_fix];
      }
      for (int j = 0; j<n_exp; j++)
      {
         double Ej = wb.tau_buf[j] / wb.tau_buf[0] * E;
         Ej = Ej / (1 - E + Ej);

         wb.tau_buf[idx++] = wb.tau_buf[j] * (1 - Ej);
      }
   }
}
*/

/*
int DecayModel::CalculateModel(Buffers& wb, vector<double>& a, int adim, vector<double>& b, int bdim, vector<double>& kap, const vector<double>& alf, int irf_idx, int isel)
{
   double ref_lifetime = GetCurrentReferenceLifetime(alf);
   double t0_shift = GetCurrentT0(alf);

   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   int getting_fit = false; //TODO

   switch (isel)
   {
   case 1:
   case 2:
   {

      int col = 0;

      for (int i = 0; i < decay_groups.size(); i++)
         col += decay_groups[i].CalculateModel(a.data() + col*adim, adim, kap);


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
         col += decay_groups[i].CalculateDerivatives(b.data() + col*bdim, bdim, kap);

      
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
      

      for (int i = 0; i < col*bdim; i++)
         b[i] *= photons_per_count;


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

   }
   }

   return 0;
}
*/

/*
int DecayModel::CalculateModel(Buffers& wb, vector<double>& a, int adim, vector<double>& b, int bdim, vector<double>& kap, const vector<double>& alf, int irf_idx, int isel)
{   
   double ref_lifetime = GetCurrentReferenceLifetime(alf);
   double t0_shift = GetCurrentT0(alf);
   
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   int getting_fit = false; //TODO

   switch(isel)
   {
      case 1:
      case 2:
      {

         int a_col = 0;

         // Constant columns - background light for local fitting
         AddOffsetColumn(a, adim, a_col);
         AddScatterColumn(a, adim, a_col, wb, irf_idx, t0_shift);
         AddTVBColumn(a, adim, a_col);



         wb.PrecomputeExponentials(alf, irf_idx, t0_shift);

         a_col += flim_model(wb, irf_idx, ref_lifetime, t0_shift, isel == 1, 0, a.data() + a_col*adim, adim);

         AddGlobalBackgroundLightColumn(a, adim, a_col, alf, wb, irf_idx, t0_shift);

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

         // Apply scaling to convert counts -> photons
         for (int i = 0; i < adim*(a_col + 1); i++)
            a[i] *= photons_per_count;

         if (isel == 2 || getting_fit)
            break;

      }
      case 3:
      {
         int col = 0;

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

         for (int i = 0; i < col*bdim; i++)
            b[i] *= photons_per_count;


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

      }
   }

   return 0;
}
*/
/*
void DecayModel::GetWeights(Buffers& wb, float* y, const vector<double>& a, const vector<double>& alf, float* lin_params, double* w, int irf_idx)
{

   int i, l_start;
   double F0, ref_lifetime;

   if ( irf->ref_reconvolution && lin_params != NULL)
   {
      if (irf->ref_reconvolution == FIT_GLOBALLY)
         ref_lifetime = alf[alf_ref_idx];
      else
         ref_lifetime = irf->ref_lifetime_guess;


      // Don't include stray light in weighting
      l_start = (fit_offset  == FIT_LOCALLY) + 
                (fit_scatter == FIT_LOCALLY) + 
                (fit_tvb     == FIT_LOCALLY);

      F0 = 0;
      for(i=l_start; i<l; i++)
         F0 = lin_params[i];
      
      for(i=0; i<n_meas; i++)
         w[i] /= ref_lifetime;

      AddIRF(wb.irf_buf, irf_idx, 0, w, n_r, &F0); // TODO: t0_shift?
     
      // Variance = (D + F0 * D_r);

   }

}

float* DecayModel::GetConstantAdjustment()
{
   return &adjust_buf[0];
}
*/