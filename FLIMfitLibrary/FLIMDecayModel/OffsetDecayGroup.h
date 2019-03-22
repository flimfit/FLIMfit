#pragma once
#include "AbstractBackgroundDecayGroup.h"
#include "AbstractConvolver.h"

class OffsetDecayGroup : public AbstractBackgroundDecayGroup
{
   Q_OBJECT

public:

   OffsetDecayGroup();

   OffsetDecayGroup* clone() const { return new OffsetDecayGroup(*this); }

protected:

   void precompute_() {};

   void addContribution(double scale, double_iterator a);

   // RUNTIME VARIABLE PARAMETERS
   std::shared_ptr<AbstractConvolver> convolver;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;
};

template<class Archive>
void OffsetDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractBackgroundDecayGroup>(*this);
};

BOOST_CLASS_TRACKING(OffsetDecayGroup, track_always)
