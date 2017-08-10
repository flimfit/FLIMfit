#include "PatternDecayGroup.h"


PatternDecayGroup::PatternDecayGroup(const std::vector<Pattern> pattern, const QString& name) :
   AbstractDecayGroup(name),
   pattern(pattern)
{
   std::vector<ParameterFittingType> fixed_or_local = { Fixed, FittedLocally };
   fit = std::make_shared<FittingParameter>("Pattern", 0, fixed_or_local, FittedLocally);
   parameters.push_back(fit);
}

PatternDecayGroup::PatternDecayGroup(const PatternDecayGroup& obj) :
   AbstractDecayGroup(obj)
{
   pattern = obj.pattern;
   fit = obj.fit;
   parameters.push_back(fit);
   init();
}

void PatternDecayGroup::init()
{
   n_lin_components = fit->isFittedLocally(); 
   n_nl_parameters = 0;

   ExponentialPrecomputationBuffer buffer(dp);

   decay.clear();
   decay.resize(dp->n_meas, 0.0);

   if (pattern.size() != dp->n_chan)
      throw(std::runtime_error("Incorrect number of channels in pattern"));

   std::vector<double> channel_factors(dp->n_chan);

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
   if (fit->isFixed())
      return 0;

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
   if (fit->isFittedLocally())
      return;

   float fact = fit->initial_value;

   for (int i = 0; i < dp->n_meas; i++)
      a[i] += fact * decay[i];
}

void PatternDecayGroup::setupIncMatrix(std::vector<int>& inc, int& row, int& col)
{
   if (fit->isFittedLocally())
      col++; // one column, no variables
}

int PatternDecayGroup::getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx)
{
   return 0;
}

int PatternDecayGroup::getLinearOutputs(float* lin_variables, float* output, int& lin_idx)
{
   if (fit->isFittedLocally())
      output[0] = lin_variables[lin_idx++];
   else
      output[0] = fit->initial_value;
   return 1;
}

std::vector<std::string> PatternDecayGroup::getNonlinearOutputParamNames()
{
   return {};
}

std::vector<std::string> PatternDecayGroup::getLinearOutputParamNames()
{
   return { "I_0" };
}

const std::vector<double>& PatternDecayGroup::getChannelFactors(int index)
{
   return channel_factors;
}

void PatternDecayGroup::setChannelFactors(int index, const std::vector<double>& channel_factors)
{
}