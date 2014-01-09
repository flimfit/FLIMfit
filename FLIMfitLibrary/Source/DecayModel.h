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

//#include "FitModel.h"
#include "ModelParameters.h"
#include "FlagDefinitions.h"
#include "InstrumentResponseFunction.h"
#include "AcquisitionParameters.h"

#include <cmath>
#include <vector>

#include <boost/shared_ptr.hpp>

using boost::shared_ptr;

using std::string;
using std::vector;

class DecayModel;
class DecayModelWorkingBuffers;

class DecayModel : public ModelParameters, 
                   public AcquisitionParameters
{
public:

   DecayModel(const ModelParameters& params, const AcquisitionParameters& acq, shared_ptr<InstrumentResponseFunction> irf);
   ~DecayModel();

   typedef DecayModelWorkingBuffers Buffers;

   void NormaliseLinearParams(volatile float lin_params[], float non_linear_params[], volatile float norm_params[]);
   void DenormaliseLinearParams(volatile float norm_params[], volatile float lin_params[]);

   void Init();

   int alf_t0_idx, alf_offset_idx, alf_scatter_idx, alf_E_idx, alf_beta_idx, alf_theta_idx, alf_tvb_idx, alf_ref_idx;

   void   SetupIncMatrix(int* inc);
   int    CalculateModel(Buffers& wb, double *a, int adim, double *b, int bdim, double *kap, const double *alf, int irf_idx, int isel);
   void   GetWeights(Buffers& wb, float* y, double* a, const double *alf, float* lin_params, double* w, int irf_idx);
   float* GetConstantAdjustment();

   int ProcessNonLinearParams(float alf[], float alf_err_lower[], float alf_err_upper[], float param[], float err_lower[], float err_upper[]);
   float GetNonLinearParam(int param, float alf[]);

   void GetOutputParamNames(vector<string>& param_names, int& n_nl_output_params);

   void SetInitialParameters(double* params, double mean_arrival_time);

   double EstimateAverageLifetime(float decay[], int data_type);


   

   int l; 
   int lmax;
   int nl;
          
   int p; 

   shared_ptr<InstrumentResponseFunction> irf;

   int n_v;
   int n_pol_group;
   int n_theta_v;
   int n_r; 
   int n_exp_phi, n_fret_group, exp_buf_size, tau_start;
   int n_fret_v;

   bool use_kappa;
   bool beta_global;
   int n_beta;

   int eq_spaced_data;

private:

   int init;

   int estimate_initial_tau;  // TODO: Best place for this?

   int calculate_mean_lifetimes;

   float photons_per_count;

   int* decay_group_buf;

   int n_stray;

   double *chan_fact;

   vector<float> adjust_buf;

   int n_irf;

   vector<int> irf_max;

   int ma_start;
  
   int n_thread;

   void SetupDecayGroups();
   void SetupPolarisationChannelFactors();
   void CheckGateSpacing();
   void SetParameterIndices();
   void SetupAdjust();

   void CalculateParameterCounts();
   
   void CalculateMeanLifetime(volatile float lin_params[], float non_linear_params[], volatile float mean_lifetimes[]);

   int DetermineMAStartPosition(int idx);

   void CalculateIRFMax();



   template <typename T>
   void add_irf(double* irf_buf, int irf_idx, double t0_shift, T a[], int pol_group, double* scale_fact = NULL);


   int flim_model(Buffers& wb, int irf_idx, double ref_lifetime, double t0_shift, bool include_fixed, int bin_shift, double a[], int adim);
   int ref_lifetime_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);
   int tau_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);
   int beta_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);
   int theta_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);
   int E_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);
   int FMM_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);
   int t0_derivatives(Buffers& wb, int irf_idx, double ref_lifetime, double t0_shift, double b[], int bdim);

   friend class DecayModelWorkingBuffers;

};


class DecayModelWorkingBuffers : public AcquisitionParameters
{
   friend class DecayModel;

public:
   DecayModelWorkingBuffers(shared_ptr<DecayModel> model);
   ~DecayModelWorkingBuffers();

   void add_decay(int tau_idx, int theta_idx, int fret_group_idx, double fact, double ref_lifetime, double a[], int bin_shift = 0);
   void add_derivative(int tau_idx, int theta_idx, int fret_group_idx, double fact, double ref_lifetime, double b[]);


private:

   shared_ptr<DecayModel> model;


   int n_irf;
   

   int n_exp;
   int exp_dim;


   int n_pol_group;
   int n_fret_group;

   int pulsetrain_correction;

   int* irf_max;

   shared_ptr<InstrumentResponseFunction> irf;

   void calculate_exponentials(int irf_idx, double t0_shift);
   int check_alf_mod(const double* new_alf, int irf_idx);

   void Convolve(double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, int bin_shift, double& c);
   void ConvolveDerivative(double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact_a, double ref_fact_b, double& c);


   int cur_irf_idx;

   double *exp_buf;
   double *tau_buf;
   double *beta_buf;
   double *theta_buf;
   double *irf_buf;
   double *cur_alf;

   bool first_eval;

};




// TODO: move this to InstrumentResponseFunction
template <typename T>
void DecayModel::add_irf(double* irf_buf, int irf_idx, double t0_shift, T a[], int pol_group, double* scale_fact)
{   
   double* lirf = irf->GetIRF(irf_idx, t0_shift, irf_buf);
   double t_irf0 = irf->GetT0();
   double dt_irf = irf->timebin_width;
   int n_irf = irf->n_irf;

   int idx = 0;
   int ii;
   for(int k=0; k<n_chan; k++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[k];
      for(int i=0; i<n_t; i++)
      {
         ii = (int) floor((t[i]-t_irf0)/dt_irf);

         if (ii>=0 && ii<n_irf)
            a[idx] += (T) (lirf[k*n_irf+ii] * chan_fact[pol_group*n_chan+k] * scale);
         idx++;
      }
   }
}


#endif