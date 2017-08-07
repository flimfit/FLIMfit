#include "PatternDecayGroup.h"


PatternDecayGroup::PatternDecayGroup(const std::vector<Pattern> pattern, const QString& name) :
   AbstractDecayGroup(name),
   pattern(pattern)
{
}

PatternDecayGroup::PatternDecayGroup(const PatternDecayGroup& obj) :
   AbstractDecayGroup(obj)
{
   pattern = obj.pattern;

   init();
}

void PatternDecayGroup::init()
{
   n_lin_components = 1; 
   n_nl_parameters = 0;

   ExponentialPrecomputationBuffer buffer(dp);

   decay.clear();
   decay.resize(dp->n_meas, 0.0);

   if (pattern.size() != dp->n_chan)
      throw(std::runtime_error("Incorrect number of channels in pattern"));

   vector<double> channel_factors(dp->n_chan);

   for (int i = 0; i < dp->n_chan; i++)
   {
      int n_exp = pattern[i].tau.size();

      for (int j = 0; j < dp->n_chan; j++)
         channel_factors[j] = (j == i);

      for (int j = 0; j < n_exp; j++)
      {
         buffer.compute(1 / pattern[i].tau[j], 0, 0, channel_factors);
         buffer.addDecay(pattern[i].beta[j], reference_lifetime, decay.data());
      }
   }

   for (int i = 0; i < dp->n_chan; i++)
   {
      for (int j = 0; j < dp->n_t; j++)
         decay[i*dp->n_t + j] += pattern[i].offset;
   }
}

int PatternDecayGroup::setVariables(const double* variables)
{
   return 0;
}

int PatternDecayGroup::calculateModel(double* a, int adim, double& kap, int bin_shift)
{
   for (int i = 0; i < dp->n_meas; i++)
      a[i] = decay[i];

   return 1;
}

int PatternDecayGroup::calculateDerivatives(double* b, int bdim, double kap_derv[])
{
   return 0;
}

void PatternDecayGroup::addConstantContribution(float* a)
{
   return;
}

void PatternDecayGroup::setupIncMatrix(std::vector<int>& inc, int& row, int& col)
{
   col++; // one column, no variables
}

int PatternDecayGroup::getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx)
{
   return 0;
}

int PatternDecayGroup::getLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   output[0] = lin_variables[lin_idx++];
   return 1;
}

void PatternDecayGroup::getNonlinearOutputParamNames(vector<string>& names)
{
}

void PatternDecayGroup::getLinearOutputParamNames(vector<string>& names)
{
   names.push_back("I0");
}

const vector<double>& PatternDecayGroup::getChannelFactors(int index)
{
   return channel_factors;
}

void PatternDecayGroup::setChannelFactors(int index, const vector<double>& channel_factors)
{
}