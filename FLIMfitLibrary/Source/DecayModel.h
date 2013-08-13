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

#ifndef _DECAYMODEL_H
#define _DECAYMODEL_H

#include "FitModel.h"
#include "ModelParameters.h"
#include "FlagDefinitions.h"
#include "InstrumentResponseFunction.h"

#include <cmath>
#include <vector>

using namespace std;

class DecayModel;

typedef void (* conv_func)(DecayModel *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c);
typedef void (* conv_deriv_func)(DecayModel *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);


class DecayModel : public FitModel,
                   public ModelParameters
{
public:

   DecayModel();
   ~DecayModel();

 
   void NormaliseLinearParams(volatile float lin_params[], volatile float norm_params[]);
   void DenormaliseLinearParams(volatile float norm_params[], volatile float lin_params[]);
   
   void ShiftIRF(double shift, double s_irf[]);


   void Init();

   int alf_t0_idx, alf_offset_idx, alf_scatter_idx, alf_E_idx, alf_beta_idx, alf_theta_idx, alf_tvb_idx, alf_ref_idx;

   void   SetupAdjust(int thread, float adjust[], float scatter_adj, float offset_adj, float tvb_adj);
   void   SetupIncMatrix(int* inc);
   int    CalculateModel(double *a, int adim, double *b, int bdim, double *kap, const double *alf, int irf_idx, int isel, int thread);
   void   GetWeights(float* y, double* a, const double *alf, float* lin_params, double* w, int irf_idx, int thread);
   float* GetConstantAdjustment();

   int ProcessNonLinearParams(float alf[], float alf_err_lower[], float alf_err_upper[], float param[], float err_lower[], float err_upper[]);
   float GetNonLinearParam(int param, float alf[]);


   void SetInitialParameters(double* params, double mean_arrival_time);

   int n_v;
   int n_chan, n_meas, n_pol_group;
   int n_theta_v;
   int n_r; 
   int n_exp_phi, n_fret_group, exp_buf_size, tau_start;
   int n_fret_v;

   bool use_kappa;
   bool beta_global;
   int n_beta;

   int eq_spaced_data;

   double* cur_alf;
   int     cur_irf_idx;


private:

   InstrumentResponseFunction irf;


   int n_decay_group;
   int* decay_group;
   int* decay_group_buf;

   int n_stray;

   int exp_dim;

   double *chan_fact;

   vector<int> irf_max;


   double *exp_buf;
   double *tau_buf;
   double *beta_buf;
   double *theta_buf;
   float  *adjust_buf;

   int ma_start;
   
   conv_func Convolve;
   conv_deriv_func ConvolveDerivative;

   int n_thread;

   void SetupDecayGroups();
   void SetupPolarisationChannelFactors();
   void AllocateBuffers();
   void CheckGateSpacing();
   void SetParameterIndices();
   void SetOutputParamNames();

   void CalculateParameterCounts();

   int DetermineMAStartPosition(int idx);
   double EstimateAverageLifetime(float decay[], int p);

   void CalculateIRFMax(int n_t, double t[]);


   void CalculateParameterCount();

   template <typename T>
   void add_irf(int thread, int irf_idx, T a[],int pol_group, double* scale_fact = NULL);




   void calculate_exponentials(int thread, int irf_idx, double tau[], double theta[]);
   int check_alf_mod(int thread, const double* new_alf, int irf_idx);

   int flim_model(int thread, int irf_idx, double tau[], double beta[], double theta[], double ref_lifetime, bool include_fixed, double a[], int adim);
   int ref_lifetime_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[], int bdim);
   int tau_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[], int bdim);
   int beta_derivatives(int thread, double tau[], const double alf[], double theta[], double ref_lifetime, double b[], int bdim);
   int theta_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[], int bdim);
   int E_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[], int bdim);
   int FMM_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[], int bdim);
   
   void add_decay(int thread, int tau_idx, int theta_idx, int fret_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double a[]);
   void add_derivative(int thread, int tau_idx, int theta_idx, int fret_group_idx,  double tau[], double theta[], double fact, double ref_lifetime, double b[]);



   friend void calc_exps(DecayModel *gc, int n_t, double t[], int total_n_exp, double tau[], int n_theta, double theta[], float exp_buf[]);

   friend void conv_irf_tcspc(DecayModel *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c);
   friend void conv_irf_timegate(DecayModel *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c);

   friend void conv_irf_deriv_tcspc(DecayModel *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);
   friend void conv_irf_deriv_timegate(DecayModel *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);

   friend void conv_irf_deriv_ref_tcspc(DecayModel *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);
   friend void conv_irf_deriv_ref_timegate(DecayModel *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);

   friend void conv_irf_ref(DecayModel *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double beta[], int dim, double a[], int add_components = 0, int inc_beta_fact = 0);
   friend void conv_irf_diff_ref(DecayModel *gc, int n_t, double t[], double exp_buf[], int n_tau, double tau[], double beta[], int dim, double b[], int inc_tau = 1);



};


template <typename T>
void DecayModel::add_irf(int thread, int irf_idx, T a[], int pol_group, double* scale_fact)
{

   double* lirf = this->irf_buf;
   
   if (image_irf)
   {
      lirf += irf_idx * n_irf * n_chan; 
   }
   else if (t0_image)
   {
      lirf += (thread + 1) * n_irf * n_chan;
      ShiftIRF(t0_image[irf_idx], lirf);
   }

   int idx = 0;
   int ii;
   for(int k=0; k<n_chan; k++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[k];
      for(int i=0; i<n_t; i++)
      {
         ii = (int) floor((t[i]-t_irf[0])/t_g);

         if (ii>=0 && ii<n_irf)
            a[idx] += (T) (lirf[k*n_irf+ii] * chan_fact[pol_group*n_chan+k] * scale);
         idx += resample_idx[i];
      }
      idx++;
   }
}


#endif