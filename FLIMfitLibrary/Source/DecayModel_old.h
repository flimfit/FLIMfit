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

#pragma once

//#include "FitModel.h"
#include "InstrumentResponseFunction.h"
#include "AcquisitionParameters.h"
#include "AbstractDecayGroup.h"

#include <cmath>
#include <vector>

#include <boost/shared_ptr.hpp>

using boost::shared_ptr;

using std::string;
using std::vector;

class DecayModel;
class DecayModelWorkingBuffers;
class ExponentialPrecomputationBuffer;

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
   int    CalculateModel(Buffers& wb, vector<double>& a, int adim, vector<double>& b, int bdim, vector<double>& kap, const vector<double>& alf, int irf_idx, int isel);
   void   GetWeights(Buffers& wb, float* y, const vector<double>& a, const vector<double>& alf, float* lin_params, double* w, int irf_idx);
   float* GetConstantAdjustment();

   int ProcessNonLinearParams(float alf[], float alf_err_lower[], float alf_err_upper[], float param[], float err_lower[], float err_upper[]);
   float GetNonLinearParam(int param, float alf[]);

   void GetOutputParamNames(vector<string>& param_names, int& n_nl_output_params);

   void SetInitialParameters(vector<double>& params, double mean_arrival_time);

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

   bool constrain_nonlinear_parameters;
   bool beta_global;
   int n_beta;

   int eq_spaced_data;

private:

   vector<AbstractDecayGroup> decay_groups;


   int init;

   int estimate_initial_tau;  // TODO: Best place for this?

   int calculate_mean_lifetimes;

   float photons_per_count;

   int* decay_group_buf;

   int n_stray;

   vector<vector<double>> channel_factor;

   vector<float> adjust_buf;

   int n_irf;

   vector<int> irf_max;

   int ma_start;
  
   int n_thread;

   void SetupDecayGroups();
   void SetupPolarisationChannelFactors();
   void SetParameterIndices();
   void SetupAdjust();

   void CalculateParameterCounts();
   
   void CalculateMeanLifetime(volatile float lin_params[], float non_linear_params[], volatile float mean_lifetimes[]);

   int DetermineMAStartPosition(int idx);

   void CalculateIRFMax();

   double GetCurrentReferenceLifetime(const vector<double>& alf);
   double GetCurrentT0(const vector<double>& alf);
   
   
   int AddT0Derivatives(Buffers& wb, int irf_idx, double ref_lifetime, double t0_shift, double b[], int bdim);
   int AddReferenceLifetimeDerivatives(Buffers& wb, double ref_lifetime, double b[], int bdim);


   friend class DecayModelWorkingBuffers;
   friend class ExponentialPrecomputationBuffer;

};

