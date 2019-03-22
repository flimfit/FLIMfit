#pragma once
#include "AbstractBackgroundDecayGroup.h"
#include "AbstractConvolver.h"

class ScatterDecayGroup : public AbstractBackgroundDecayGroup
{
   Q_OBJECT

public:

   ScatterDecayGroup();

   ScatterDecayGroup* clone() const { return new ScatterDecayGroup(*this); }

protected:

   void init_();
   void precompute_();

   void addContribution(double scale, double_iterator a);

   // RUNTIME VARIABLE PARAMETERS
   std::shared_ptr<AbstractConvolver> convolver;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;
};

template<class Archive>
void ScatterDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractBackgroundDecayGroup>(*this);
};

BOOST_CLASS_TRACKING(ScatterDecayGroup, track_always)
