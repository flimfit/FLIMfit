#pragma once
#include "AbstractDecayGroup.h"
#include "AbstractConvolver.h"

class AbstractBackgroundDecayGroup : public AbstractDecayGroup
{
   Q_OBJECT

public:

   AbstractBackgroundDecayGroup(const QString& name);
   AbstractBackgroundDecayGroup(const AbstractBackgroundDecayGroup& obj);

   int calculateModel(double_iterator a, int adim, double& kap);
   int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   void addConstantContribution(double_iterator a);
   void addUnscaledContribution(double_iterator a);

   void setupIncMatrix(inc_matrix& inc, int& row, int& col);
   int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx);

   std::vector<std::string> getLinearOutputParamNames();
   int setParameters(double_iterator parameters);

   const std::vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const std::vector<double>& channel_factors);

protected:

   std::string name;

   void setupParameters();
   
   virtual void init_();
   int setVariables_(std::vector<double>::const_iterator variables);

   virtual void addContribution(double scale, double_iterator a) = 0;
   
   std::shared_ptr<FittingParameter> scale_param;

   std::vector<double> channel_factors;

   // RUNTIME VARIABLE PARAMETERS
   double scale = 0;
 
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;
};

template<class Archive>
void AbstractBackgroundDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractDecayGroup>(*this);
   ar & name;
   ar & scale_param;
   ar & channel_factors;
};

BOOST_CLASS_TRACKING(AbstractBackgroundDecayGroup, track_always)
