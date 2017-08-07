#pragma once
#include "MultiExponentialDecayGroup.h"


class AnisotropyDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:
   
   AnisotropyDecayGroup(int n_lifetime_exponential_ = 1, int n_anisotropy_populations_ = 1, bool include_r_inf = true);
   AnisotropyDecayGroup(const AnisotropyDecayGroup& obj);

   AbstractDecayGroup* clone() const { return new AnisotropyDecayGroup(*this); }

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(int n_anisotropy_populations MEMBER n_anisotropy_populations WRITE setNumAnisotropyPopulations USER true);
   Q_PROPERTY(bool include_r_inf MEMBER include_r_inf WRITE setIncludeRInf USER true);

   void setNumExponential(int n_exponential_);
   void setNumAnisotropyPopulations(int n_anisotropy_populations_);
   void setIncludeRInf(bool include_r_inf_);

   int setVariables(const double* variables);
   int calculateModel(double* a, int adim, double& kap, int bin_shift = 0);
   int calculateDerivatives(double* b, int bdim, double kap_derv[]);
   int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int getLinearOutputs(float* lin_variables, float* output, int& lin_idx);
   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   void getLinearOutputParamNames(std::vector<std::string>& names);

protected:

   void setupParameters();
   
   int addLifetimeDerivativesForAnisotropy(int idx, double* b, int bdim, double& kap);
   int addRotationalCorrelationTimeDerivatives(double* b, int bdim, double kap_derv[]);

   void setupChannelFactors();

   std::vector<std::shared_ptr<FittingParameter>> theta_parameters;

   int n_anisotropy_populations;
   bool include_r_inf;
   
   std::vector<double> theta;

   std::vector<std::vector<ExponentialPrecomputationBuffer>> anisotropy_buffer;
   std::vector<std::vector<double>> channel_factors;
   
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
