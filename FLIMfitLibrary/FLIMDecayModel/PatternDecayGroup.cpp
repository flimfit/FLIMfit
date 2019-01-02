#include "PatternDecayGroup.h"


PatternDecayGroup::PatternDecayGroup(const std::vector<Pattern> pattern, const QString& name) :
   AbstractDecayGroup(name),
   pattern(pattern)
{
   std::vector<ParameterFittingType> fixed_or_local = { Fixed, FittedLocally };
   fit = std::make_shared<FittingParameter>("Pattern", 0, 1, fixed_or_local, FittedLocally);
   parameters.push_back(fit);
   last_t0 = std::numeric_limits<double>::infinity();
}

PatternDecayGroup::PatternDecayGroup(const PatternDecayGroup& obj) :
   AbstractDecayGroup(obj)
{
   pattern = obj.pattern;
   fit = obj.fit;
   parameters.push_back(fit);
   last_t0 = std::numeric_limits<double>::infinity();
   init();
}

void PatternDecayGroup::init()
{
   n_lin_components = fit->isFittedLocally();
   n_nl_parameters = 0;

   if (pattern.size() != dp->n_chan)
      throw(std::runtime_error("Incorrect number of channels in pattern"));
}

void PatternDecayGroup::precompute()
{
   decay.clear();
   decay.resize(dp->n_meas, 0.0);

   auto buffer = AbstractConvolver::make(dp);
   std::vector<double> channel_factors(dp->n_chan);

   for (int i = 0; i < dp->n_chan; i++)
   {
      int n_exp = (int) pattern[i].tau.size();

      for (int j = 0; j < dp->n_chan; j++)
         channel_factors[j] = (j == i);

      for (int j = 0; j < n_exp; j++)
      {
         buffer->compute(1 / pattern[i].tau[j], irf_idx, t0_shift, reference_lifetime);
         buffer->addDecay(pattern[i].beta[j], channel_factors, decay.begin());
      }
   }

   for (int i = 0; i < dp->n_chan; i++)
   {
      for (int j = 0; j < dp->n_t; j++)
         decay[i*dp->n_t + j] += pattern[i].offset;
   }
}

int PatternDecayGroup::setVariables(const_double_iterator variables)
{
   return 0;
}

int PatternDecayGroup::calculateModel(double_iterator a, int adim, double& kap)
{
   if (fit->isFixed())
      return 0;

   precompute();

   for (int i = 0; i < dp->n_meas; i++)
      a[i] = decay[i];

   return 1;
}

int PatternDecayGroup::calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv)
{
   return 0;
}

void PatternDecayGroup::addConstantContribution(float_iterator a)
{
   if (fit->isFittedLocally())
      return;

   precompute();

   float fact = fit->getInitialValue();

   for (int i = 0; i < dp->n_meas; i++)
      a[i] += fact * decay[i];
}

void PatternDecayGroup::setupIncMatrix(std::vector<int>& inc, int& row, int& col)
{
   if (fit->isFittedLocally()) 
      col++; // one column, no variables
}

int PatternDecayGroup::getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx)
{
   return 0;
}

int PatternDecayGroup::getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx)
{
   if (fit->isFittedLocally())
      output[0] = lin_variables[lin_idx++];
   else
      output[0] = fit->getInitialValue();
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