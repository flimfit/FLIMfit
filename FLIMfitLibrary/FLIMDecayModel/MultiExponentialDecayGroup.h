#pragma once 

#include "MultiExponentialDecayGroupPrivate.h"

class MultiExponentialDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:

   MultiExponentialDecayGroup(int n_exponential_ = 1, bool contributions_global_ = false, const QString& name = "Multi-Exponential Decay") :
      MultiExponentialDecayGroupPrivate(n_exponential_, contributions_global_, name)
   {
   }


   MultiExponentialDecayGroup(const MultiExponentialDecayGroup& obj) :
      MultiExponentialDecayGroupPrivate(obj)
   {
      setupParametersMultiExponential();
      init();
   }

   AbstractDecayGroup* clone() const { return new MultiExponentialDecayGroup(*this); }
   void init() { MultiExponentialDecayGroupPrivate::init(); }

   void setFitChannelFactors(bool fit_channel_factors_);

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(bool contributions_global MEMBER contributions_global WRITE setContributionsGlobal USER true);
   Q_PROPERTY(bool fit_channel_factors MEMBER n_exponential WRITE setFitChannelFactors USER true);

protected:

   bool fit_channel_factors = false;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;

};

template<class Archive>
void MultiExponentialDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<MultiExponentialDecayGroupPrivate>(*this);
   ar & tau_parameters;
   ar & beta_parameters;
   ar & n_exponential;
   ar & contributions_global;
   ar & channel_factors;
};

BOOST_CLASS_TRACKING(MultiExponentialDecayGroup, track_always)