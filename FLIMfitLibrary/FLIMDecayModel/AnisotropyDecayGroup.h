#pragma once
#include "MultiExponentialDecayGroup.h"


class AnisotropyDecayGroup : public MultiExponentialDecayGroup
{
public:
   
   AnisotropyDecayGroup(int n_lifetime_exponential_ = 1, int n_anisotropy_populations_ = 1, bool include_r_inf = true);
   void SetNumAnisotropyPopulations(int n_anisotropy_populations) {}; // TODO
   void SetIncludeRInf(bool include_r_inf) {};

   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   int GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int GetLinearOutputs(float* lin_variables, float* output, int& lin_idx);
   int SetupIncMatrix(int* inc, int& row, int& col);

   void GetNonlinearOutputParamNames(vector<string>& names);
   void GetLinearOutputParamNames(vector<string>& names);

protected:

   void Validate();
   
   int AddLifetimeDerivativesForAnisotropy(int idx, double* b, int bdim, vector<double>& kap);
   int AddRotationalCorrelationTimeDerivatives(double* b, int bdim, vector<double>& kap);

   void SetupChannelFactors();

   vector<shared_ptr<FittingParameter>> theta_parameters;

   int n_anisotropy_populations;
   bool include_r_inf;
   int n_multiexp_parameters;

   vector<double> theta;

   vector<vector<ExponentialPrecomputationBuffer>> anisotropy_buffer;
   vector<vector<double>> channel_factors;
};


class QAnisotropyDecayGroup : public QAbstractDecayGroup, public AnisotropyDecayGroup
{
   Q_OBJECT

public:

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE SetNumExponential USER true);
   Q_PROPERTY(int n_anisotropy_populations MEMBER n_anisotropy_populations WRITE SetNumAnisotropyPopulations USER true);
   Q_PROPERTY(bool include_r_inf MEMBER include_r_inf WRITE SetIncludeRInf USER true);
};