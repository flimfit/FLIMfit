#pragma once
#include "MultiExponentialDecayGroup.h"


class AnisotropyDecayGroup : public MultiExponentialDecayGroup
{
   Q_OBJECT

public:
   
   AnisotropyDecayGroup(int n_lifetime_exponential_ = 1, int n_anisotropy_populations_ = 1, bool include_r_inf = true);
   
   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE SetNumExponential USER true);
   Q_PROPERTY(int n_anisotropy_populations MEMBER n_anisotropy_populations WRITE SetNumAnisotropyPopulations USER true);
   Q_PROPERTY(bool include_r_inf MEMBER include_r_inf WRITE SetIncludeRInf USER true);

   void SetNumAnisotropyPopulations(int n_anisotropy_populations) {}; // TODO
   void SetIncludeRInf(bool include_r_inf) {};

   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   int GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int GetLinearOutputs(float* lin_variables, float* output, int& lin_idx);
   int SetupIncMatrix(int* inc, int& row, int& col);

   void GetLinearOutputParamNames(vector<string>& names);

protected:

   void SetupParameters();
   
   int AddLifetimeDerivativesForAnisotropy(int idx, double* b, int bdim, vector<double>& kap);
   int AddRotationalCorrelationTimeDerivatives(double* b, int bdim, vector<double>& kap);

   void SetupChannelFactors();

   vector<shared_ptr<FittingParameter>> theta_parameters;

   int n_anisotropy_populations;
   bool include_r_inf;
   
   vector<double> theta;

   vector<vector<ExponentialPrecomputationBuffer>> anisotropy_buffer;
   vector<vector<double>> channel_factors;
   
private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};

template<class Archive>
void AnisotropyDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractDecayGroup>(*this);
   ar & theta_parameters;
   ar & n_anisotropy_populations;
   ar & include_r_inf;
   ar & channel_factors;
};

/*
class QAnisotropyDecayGroup : virtual public QAbstractDecayGroup, virtual public AnisotropyDecayGroup
{
   Q_OBJECT

public:

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE SetNumExponential USER true);
   Q_PROPERTY(int n_anisotropy_populations MEMBER n_anisotropy_populations WRITE SetNumAnisotropyPopulations USER true);
   Q_PROPERTY(bool include_r_inf MEMBER include_r_inf WRITE SetIncludeRInf USER true);

private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};

template<class Archive>
void QAnisotropyDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AnisotropyDecayGroup>(*this);
};
*/