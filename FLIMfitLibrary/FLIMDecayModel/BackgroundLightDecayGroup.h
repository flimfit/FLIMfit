#pragma once
#include "AbstractDecayGroup.h"

class BackgroundLightDecayGroup : public AbstractDecayGroup
{
   Q_OBJECT

public:

   BackgroundLightDecayGroup();
   BackgroundLightDecayGroup(const BackgroundLightDecayGroup& obj);

   int setVariables(const double* variables);
   int calculateModel(double* a, int adim, double& kap, int bin_shift = 0);
   int calculateDerivatives(double* b, int bdim, double kap_derv[]);
   void addConstantContribution(float* a);

   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);
   int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int getLinearOutputs(float* lin_variables, float* output, int& lin_idx);

   std::vector<std::string> getLinearOutputParamNames();
   int setParameters(double* parameters);

   const std::vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const std::vector<double>& channel_factors);

   AbstractDecayGroup* clone() const { return new BackgroundLightDecayGroup(*this); }

protected:

   void init();

   const std::array<std::string, 3> names = { "offset", "scatter", "tvb" };
   void setupParameters();

   int addOffsetColumn(double* a, int adim, double& kap);
   int addScatterColumn(double* a, int adim, double& kap);
   int addTVBColumn(double* a, int adim, double& kap);
   int addGlobalBackgroundLightColumn(double* a, int adim, double& kap);

   int addOffsetDerivatives(double* b, int bdim, double& kap_derv);
   int addScatterDerivatives(double* b, int bdim, double& kap_derv);
   int addTVBDerivatives(double* b, int bdim, double& kap_derv);

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
