#pragma once

#include "AbstractDecayGroup.h"

class Pattern
{
public:

   Pattern(const std::vector<double>& params)
   {
      if (params.size() % 2 == 0)
         throw std::runtime_error("Params should take form tau_1 beta_1 ... tau_n beta_n offset");

      size_t n_exp = (params.size() - 1) / 2;
      tau.resize(n_exp);
      beta.resize(n_exp);

      for (int i = 0; i < n_exp; i++)
      {
         tau[i] = params[i * 2];
         beta[i] = params[i * 2 + 1];
      }

      offset = params[n_exp * 2];
   }

   Pattern(const std::vector<double>& tau, const std::vector<double>& beta, double offset) :
      tau(tau), beta(beta), offset(offset)
   {
      if (tau.size() != beta.size())
         throw std::runtime_error("Expected tau and beta to be the same size");
   }

   Pattern() {}

   std::vector<double> tau;
   std::vector<double> beta;
   double offset = 0;

private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;
};

template<class Archive>
void Pattern::serialize(Archive & ar, const unsigned int version)
{
   ar & tau;
   ar & beta;
   ar & offset;
};


class PatternDecayGroup : public AbstractDecayGroup
{
   Q_OBJECT

public:

   PatternDecayGroup(const std::vector<Pattern> pattern = {}, const QString& name = "Pattern");
   PatternDecayGroup(const PatternDecayGroup& obj);

   int calculateModel(double_iterator a, int adim, double& kap);
   int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   void addConstantContribution(double_iterator a);

   void setupIncMatrix(inc_matrix& inc, int& row, int& col);
   int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx);

   std::vector<std::string> getNonlinearOutputParamNames();
   std::vector<std::string> getLinearOutputParamNames();

   const std::vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const std::vector<double>& channel_factors);


   AbstractDecayGroup* clone() const { return new PatternDecayGroup(*this); }

protected:

   void init_();
   void precompute_();
   int setVariables_(std::vector<double>::const_iterator variables);

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;

   std::shared_ptr<FittingParameter> fit;

   std::vector<Pattern> pattern;
   std::vector<double> channel_factors;
   aligned_vector<double> decay;

   double last_t0;
};

template<class Archive>
void PatternDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractDecayGroup>(*this);
   ar & pattern;

   if (version >= 2)
      ar & fit;
};

BOOST_CLASS_TRACKING(PatternDecayGroup, track_always)
BOOST_CLASS_VERSION(PatternDecayGroup, 2)
