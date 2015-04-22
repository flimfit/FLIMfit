#pragma once
#include "AbstractDecayGroup.h"


class BackgroundLightDecayGroup : public AbstractDecayGroup
{
public:

   BackgroundLightDecayGroup();

   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);
   void AddConstantContribution(float* a);

   int SetupIncMatrix(int* inc, int& row, int& col);
   int GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int GetLinearOutputs(float* lin_variables, float* output, int& lin_idx);

   void GetLinearOutputParamNames(vector<string>& names);
   int SetParameters(double* parameters);

protected:

   const vector<string> names;
   void Validate();

   int AddOffsetColumn(double* a, int adim, vector<double>& kap);
   int AddScatterColumn(double* a, int adim, vector<double>& kap);
   int AddTVBColumn(double* a, int adim, vector<double>& kap);
   int AddGlobalBackgroundLightColumn(double* a, int adim, vector<double>& kap);

   int AddOffsetDerivatives(double* b, int bdim, vector<double>& kap);
   int AddScatterDerivatives(double* b, int bdim, vector<double>& kap);
   int AddTVBDerivatives(double* b, int bdim, vector<double>& kap);

   vector<double> channel_factors;

   // RUNTIME VARIABLE PARAMETERS
   double offset = 0;
   double scatter = 0;
   double tvb = 0;
};

class QBackgroundLightDecayGroup : public QAbstractDecayGroup, public BackgroundLightDecayGroup
{
   Q_OBJECT

public:

   QBackgroundLightDecayGroup(const QString& name = "Background Light", QObject* parent = 0) :
      QAbstractDecayGroup(name, parent) {};

signals:
   void Updated();
};
