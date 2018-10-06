#pragma once 

#include "MultiExponentialDecayGroupPrivate.h"

class MultiExponentialDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:

   MultiExponentialDecayGroup(int n_exponential_ = 1, bool contributions_global_ = false, const QString& name = "Multi-Exponential Decay");
   MultiExponentialDecayGroup(const MultiExponentialDecayGroup& obj);

   AbstractDecayGroup* clone() const { return new MultiExponentialDecayGroup(*this); }
   void init();

   void setNumChannels(int n_chan);

   virtual int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   virtual int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   virtual void setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   void setFitChannelFactors(bool fit_channel_factors_);

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(bool contributions_global MEMBER contributions_global WRITE setContributionsGlobal USER true);
   Q_PROPERTY(bool fit_channel_factors MEMBER fit_channel_factors WRITE setFitChannelFactors USER true);

protected:

   void setupParameters();
   int setVariables(const_double_iterator variables);

   bool fit_channel_factors = false;
   int n_chan = 1;
   std::vector<std::shared_ptr<FittingParameter>> channel_factor_parameters;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;

};

BOOST_CLASS_VERSION(MultiExponentialDecayGroup, 2)

template<class Archive>
void MultiExponentialDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<MultiExponentialDecayGroupPrivate>(*this);
   ar & tau_parameters;
   ar & beta_parameters;
   ar & n_exponential;
   ar & contributions_global;
   ar & channel_factors;
   if (version >= 2)
      ar & fit_channel_factors;
};

BOOST_CLASS_TRACKING(MultiExponentialDecayGroup, track_always)