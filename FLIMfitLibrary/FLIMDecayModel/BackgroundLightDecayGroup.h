#pragma once
#include "AbstractDecayGroup.h"


class BackgroundLightDecayGroup : public AbstractDecayGroup
{
   Q_OBJECT

public:

   BackgroundLightDecayGroup();

   int setVariables(const double* variables);
   int calculateModel(double* a, int adim, vector<double>& kap);
   int calculateDerivatives(double* b, int bdim, vector<double>& kap);
   void addConstantContribution(float* a);

   int setupIncMatrix(std::vector<int>& inc, int& row, int& col);
   int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int getLinearOutputs(float* lin_variables, float* output, int& lin_idx);

   void getLinearOutputParamNames(vector<string>& names);
   int setParameters(double* parameters);

protected:

   const vector<string> names;
   void setupParameters();

   int addOffsetColumn(double* a, int adim, vector<double>& kap);
   int addScatterColumn(double* a, int adim, vector<double>& kap);
   int addTVBColumn(double* a, int adim, vector<double>& kap);
   int addGlobalBackgroundLightColumn(double* a, int adim, vector<double>& kap);

   int addOffsetDerivatives(double* b, int bdim, vector<double>& kap);
   int addScatterDerivatives(double* b, int bdim, vector<double>& kap);
   int addTVBDerivatives(double* b, int bdim, vector<double>& kap);

   vector<double> channel_factors;

   // RUNTIME VARIABLE PARAMETERS
   double offset = 0;
   double scatter = 0;
   double tvb = 0;
};

/*
class QBackgroundLightDecayGroup : public QAbstractDecayGroup, public BackgroundLightDecayGroup
{
   Q_OBJECT

public:

   QBackgroundLightDecayGroup(const QString& name = "Background Light", QObject* parent = 0) :
      QAbstractDecayGroup(name, parent) {};

signals:
   void Updated();
};
*/