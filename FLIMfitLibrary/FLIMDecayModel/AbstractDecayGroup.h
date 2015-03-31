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

#include <memory>
using std::shared_ptr;
using std::unique_ptr;

#include "ExponentialPrecomputationBuffer.h"
#include "InstrumentResponseFunction.h"
#include "AcquisitionParameters.h"
#include "IRFConvolution.h"
#include "FittingParameter.h"

class AbstractDecayGroup
{
public:

   AbstractDecayGroup();
   AbstractDecayGroup(shared_ptr<AcquisitionParameters> acq);
   virtual ~AbstractDecayGroup() = 0;
   virtual unique_ptr<AbstractDecayGroup> clone() = 0;

   void Init();

   virtual int SetVariables(const double* variables) = 0;
   virtual int CalculateModel(double* a, int adim, vector<double>& kap) = 0;
   virtual int CalculateDerivatives(double* b, int bdim, vector<double>& kap) = 0;
   virtual void AddConstantContribution(float* a) {}

   virtual int SetupIncMatrix(int* inc, int& row, int& col) = 0;
   virtual int GetOutputs(double* nonlin_variables, double* lin_variables, float* outputs, int& nonlin_idx, int& lin_idx) = 0;

   int GetInitialVariables(double* variables)
   {
      // TODO: needs work for betas etc where there is not a 1:1 relationship
      int idx = 0;
      for (auto& p : parameters)
      {
         if (p->IsFittedGlobally())
            variables[idx++] = p->initial_value;
      }

      return idx;
   }


   void SetIRFPosition(int irf_idx_, double t0_shift_, double reference_lifetime_)
   {
      irf_idx = irf_idx_;
      t0_shift = t0_shift_;
      reference_lifetime = reference_lifetime_;
   }

   int GetNumComponents() { return n_lin_components; };
   int GetNumNonlinearParameters() { return n_nl_parameters; };

   template <typename T>
   void AddIRF(double* irf_buf, int irf_idx, double t0_shift, T a[], const vector<double>& channel_factor, double* scale_fact = NULL);

protected:

   shared_ptr<AcquisitionParameters> acq;

   bool constrain_nonlinear_parameters = true;

   int n_lin_components = 0;
   int n_nl_parameters = 0;
   
   vector<shared_ptr<FittingParameter>> parameters;
   vector<string> output_names;

   bool fit_t0 = false;

   // RUNTIME VARIABLE PARAMETERS
   int irf_idx = 0;
   double t0_shift = 0;
   double reference_lifetime;
   vector<double> irf_buf;
};

class BackgroundLightDecayGroup : public AbstractDecayGroup
{
public:

   BackgroundLightDecayGroup(shared_ptr<AcquisitionParameters> acq);
   unique_ptr<AbstractDecayGroup> clone() { return unique_ptr<AbstractDecayGroup>(new BackgroundLightDecayGroup(*this)); };
   
   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   void AddConstantContribution(float* a);

   int SetupIncMatrix(int* inc, int& row, int& col);
   int GetOutputs(double* nonlin_variables, double* lin_variables, float* outputs, int& nonlin_idx, int& lin_idx);

   int SetParameters(double* parameters);


protected:

   int AddOffsetColumn(double* a, int adim, vector<double>& kap);
   int AddScatterColumn(double* a, int adim, vector<double>& kap);
   int AddTVBColumn(double* a, int adim, vector<double>& kap);
   int AddGlobalBackgroundLightColumn(double* a, int adim, vector<double>& kap);

   int AddOffsetDerivatives(double* b, int bdim, vector<double>& kap);
   int AddScatterDerivatives(double* b, int bdim, vector<double>& kap);
   int AddTVBDerivatives(double* b, int bdim, vector<double>& kap);

   vector<double> channel_factors;

   // RUNTIME VARIABLE PARAMETERS
   double offset = 0;
   double scatter = 0;
   double tvb = 0;
};

class MultiExponentialDecayGroup : public AbstractDecayGroup
{
public:

   MultiExponentialDecayGroup(shared_ptr<AcquisitionParameters> acq, int n_exponential_ = 1, bool contributions_global_ = false);
   unique_ptr<AbstractDecayGroup> clone() { return unique_ptr<AbstractDecayGroup>(new MultiExponentialDecayGroup(*this)); };

   virtual int SetVariables(const double* variables);
   virtual int CalculateModel(double* a, int adim, vector<double>& kap);
   virtual int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   virtual int GetOutputs(double* nonlin_variables, double* lin_variables, float* output, int& nonlin_idx, int& lin_idx);
   virtual int SetupIncMatrix(int* inc, int& row, int& col);

protected:

   int AddDecayGroup(const vector<ExponentialPrecomputationBuffer>& buffers, double* a, int adim, vector<double>& kap);
   int AddLifetimeDerivative(int idx, double* b, int bdim, vector<double>& kap);
   int AddContributionDerivatives(double* b, int bdim, vector<double>& kap);
   int NormaliseLinearParameters(double* lin_variables, int n, float* output, int& lin_idx);

   vector<double> tau;
   vector<double> beta;
   vector<ExponentialPrecomputationBuffer> buffer;
   vector<double> channel_factors;

   vector<shared_ptr<FittingParameter>> tau_parameters;
   vector<shared_ptr<FittingParameter>> beta_parameters;


   int n_exponential;
   bool contributions_global;
};

class FretDecayGroup : public MultiExponentialDecayGroup
{
public:

   FretDecayGroup(shared_ptr<AcquisitionParameters> acq, int n_donor_exponential_ = 1, int n_fret_populations_ = 1, bool include_donor_only = true);
   unique_ptr<AbstractDecayGroup> clone() { return unique_ptr<AbstractDecayGroup>(new FretDecayGroup(*this)); };

   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   int GetOutputs(double* nonlin_variables, double* lin_variables, float* output, int& nonlin_idx, int& lin_idx);
   int SetupIncMatrix(int* inc, int& row, int& col);

private:

   int AddLifetimeDerivativesForFret(int idx, double* b, int bdim, vector<double>& kap);
   int AddFretEfficiencyDerivatives(double* b, int bdim, vector<double>& kap);

   vector<double> E;
   vector<vector<double>> tau_fret;

   vector<shared_ptr<FittingParameter>> E_parameters;

   vector<vector<ExponentialPrecomputationBuffer>> fret_buffer;
   vector<double> channel_factors;

   int n_fret_populations;
   bool include_donor_only;

   int n_multiexp_parameters;
};



class AnisotropyDecayGroup : public MultiExponentialDecayGroup
{
public:

   AnisotropyDecayGroup(shared_ptr<AcquisitionParameters> acq, int n_lifetime_exponential_ = 1, int n_anisotropy_populations_ = 1, bool include_r_inf = true);
   unique_ptr<AbstractDecayGroup> clone() { return unique_ptr<AbstractDecayGroup>(new AnisotropyDecayGroup(*this)); };

   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   int GetOutputs(double* nonlin_variables, double* lin_variables, float* output, int& nonlin_idx, int& lin_idx);
   int SetupIncMatrix(int* inc, int& row, int& col);


private:

   int AddLifetimeDerivativesForAnisotropy(int idx, double* b, int bdim, vector<double>& kap);
   int AddRotationalCorrelationTimeDerivatives(double* b, int bdim, vector<double>& kap);

   void SetupChannelFactors();

   vector<double> theta;

   vector<vector<ExponentialPrecomputationBuffer>> anisotropy_buffer;
   vector<vector<double>> channel_factors;

   vector<shared_ptr<FittingParameter>> theta_parameters;

   int n_anisotropy_populations;
   bool include_r_inf;

   int n_multiexp_parameters;
};



// TODO: move this to InstrumentResponseFunction
template <typename T>
void AbstractDecayGroup::AddIRF(double* irf_buf, int irf_idx, double t0_shift, T a[], const vector<double>& channel_factor, double* scale_fact)
{
   shared_ptr<InstrumentResponseFunction> irf = acq->irf;

   double* lirf = irf->GetIRF(irf_idx, t0_shift, irf_buf);
   double t_irf0 = irf->GetT0();
   double dt_irf = irf->timebin_width;
   int n_irf = irf->n_irf;

   int idx = 0;
   int ii;
   for (int k = 0; k<acq->n_chan; k++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[k];
      for (int i = 0; i<acq->n_t; i++)
      {
         ii = (int)floor((acq->t[i] - t_irf0) / dt_irf);

         if (ii >= 0 && ii<n_irf)
            a[idx] += (T)(lirf[k*n_irf + ii] * channel_factor[k] * scale); // TODO
         idx++;
      }
   }
}
