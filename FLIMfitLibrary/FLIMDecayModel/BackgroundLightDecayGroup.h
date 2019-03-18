#pragma once
#include "AbstractDecayGroup.h"

class BackgroundLightDecayGroup : public AbstractDecayGroup
{
   Q_OBJECT

public:

   BackgroundLightDecayGroup();
   BackgroundLightDecayGroup(const BackgroundLightDecayGroup& obj);

   int calculateModel(double_iterator a, int adim, double& kap);
   int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   void addConstantContribution(float_iterator a);

   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);
   int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx);

   std::vector<std::string> getLinearOutputParamNames();
   int setParameters(double_iterator parameters);

   const std::vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const std::vector<double>& channel_factors);

   AbstractDecayGroup* clone() const { return new BackgroundLightDecayGroup(*this); }

protected:

   
   const std::array<std::string, 3> names = { "offset", "scatter", "tvb" };
   void setupParameters();
   
   void init_();
   void precompute_();
   int setVariables_(std::vector<double>::const_iterator variables);

   int addOffsetColumn(double_iterator a, int adim, double& kap);
   int addScatterColumn(double_iterator a, int adim, double& kap);
   int addTVBColumn(double_iterator a, int adim, double& kap);
   int addGlobalBackgroundLightColumn(double_iterator a, int adim, double& kap);

   int addOffsetDerivatives(double_iterator b, int bdim, double& kap_derv);
   int addScatterDerivatives(double_iterator b, int bdim, double& kap_derv);
   int addTVBDerivatives(double_iterator b, int bdim, double& kap_derv);

   std::vector<double> channel_factors;

   // RUNTIME VARIABLE PARAMETERS
   double offset = 0;
   double scatter = 0;
   double tvb = 0;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;
};

template<class Archive>
void BackgroundLightDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractDecayGroup>(*this);
   ar & parameters;
   ar & channel_factors;
};

BOOST_CLASS_TRACKING(BackgroundLightDecayGroup, track_always)
