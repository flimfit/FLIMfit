#pragma once
#include "MultiExponentialDecayGroup.h"


class AnisotropyDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:
   
   AnisotropyDecayGroup(int n_lifetime_exponential_ = 1, int n_anisotropy_populations_ = 1, bool include_r_inf = true);
   
   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(int n_anisotropy_populations MEMBER n_anisotropy_populations WRITE setNumAnisotropyPopulations USER true);
   Q_PROPERTY(bool include_r_inf MEMBER include_r_inf WRITE setIncludeRInf USER true);

   void setNumAnisotropyPopulations(int n_anisotropy_populations) {}; // TODO
   void setIncludeRInf(bool include_r_inf) {};

   int setVariables(const double* variables);
   int calculateModel(double* a, int adim, vector<double>& kap);
   int calculateDerivatives(double* b, int bdim, vector<double>& kap);
   int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int getLinearOutputs(float* lin_variables, float* output, int& lin_idx);
   int setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   void getLinearOutputParamNames(vector<string>& names);

protected:

   void setupParameters();
   
   int addLifetimeDerivativesForAnisotropy(int idx, double* b, int bdim, vector<double>& kap);
   int addRotationalCorrelationTimeDerivatives(double* b, int bdim, vector<double>& kap);

   void setupChannelFactors();

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