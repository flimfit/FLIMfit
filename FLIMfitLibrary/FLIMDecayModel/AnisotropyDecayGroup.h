#pragma once
#include "MultiExponentialDecayGroupPrivate.h"


class AnisotropyDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:

   AnisotropyDecayGroup(int n_lifetime_exponential_ = 1, int n_anisotropy_populations_ = 1, bool include_r_inf = false);
   AnisotropyDecayGroup(const AnisotropyDecayGroup& obj);

   AbstractDecayGroup* clone() const { return new AnisotropyDecayGroup(*this); }

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(int n_anisotropy_populations MEMBER n_anisotropy_populations WRITE setNumAnisotropyPopulations USER true);
   Q_PROPERTY(bool include_r_inf MEMBER include_r_inf WRITE setIncludeRInf USER true);

   void setNumExponential(int n_exponential_);
   void setNumAnisotropyPopulations(int n_anisotropy_populations_);
   void setIncludeRInf(bool include_r_inf_);

   int setVariables(std::vector<double>::const_iterator variables);
   void precompute();
   int calculateModel(double_iterator a, int adim, double& kap);
   int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx);
   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   std::vector<std::string> getLinearOutputParamNames();

protected:

   void init();
   void setupParameters();
   int addLifetimeDerivativesForAnisotropy(int idx, double_iterator b, int bdim, double& kap);
   int addContributionDerivativesForAnisotropy(double_iterator b, int bdim, double_iterator& kap);
   int addRotationalCorrelationTimeDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);

   void setupChannelFactors();

   std::vector<std::shared_ptr<FittingParameter>> theta_parameters;

   int n_anisotropy_populations;
   bool include_r_inf;

   std::vector<double> k_theta;

   std::vector<std::vector<std::shared_ptr<AbstractConvolver>>> anisotropy_buffer;
   std::vector<double> ss_channel_factors;
   std::vector<double> pol_channel_factors;

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
};
