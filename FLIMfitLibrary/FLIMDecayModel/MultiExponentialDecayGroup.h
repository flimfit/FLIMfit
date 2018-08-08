#pragma once 

#include "AbstractDecayGroup.h"
#include "IRFConvolution.h"
#include "AbstractConvolver.h"

template<typename it_alf, typename it_beta> // TODO: make this part of class
int getBeta(const std::vector<std::shared_ptr<FittingParameter>>& beta_parameters, double fixed_beta, int n_beta_free, it_alf alf, it_beta beta, it_beta beta_buf)
{
   int n_vars_used = 0;
   
   alf2beta(n_beta_free, alf, beta_buf);

   int idx = 0;
   for (int i = 0; i < beta_parameters.size(); i++)
   {
      if (!beta_parameters[i]->isFixed())
      {
         beta[i] = beta_buf[idx++] * (1 - fixed_beta);
         n_vars_used++;
      }
      else
      {
         beta[i] = beta_parameters[i]->initial_value;
      }
   }
   return std::max(n_beta_free-1, 0);
}
class MultiExponentialDecayGroupPrivate : public AbstractDecayGroup
{
   Q_OBJECT

public:

   MultiExponentialDecayGroupPrivate(int n_exponential_ = 1, bool contributions_global_ = false, const QString& name = "Multi-Exponential Decay");

   MultiExponentialDecayGroupPrivate(const MultiExponentialDecayGroupPrivate& obj);

   virtual void setNumExponential(int n_exponential);
   virtual void setContributionsGlobal(bool contributions_global);

   virtual const std::vector<double>& getChannelFactors(int index);
   virtual void setChannelFactors(int index, const std::vector<double>& channel_factors);

   virtual int setVariables(const_double_iterator variables);
   virtual int calculateModel(double* a, int adim, double& kap);
   virtual int calculateDerivatives(double* b, int bdim, double_iterator& kap_derv);
   virtual int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   virtual int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx);
   virtual void setupIncMatrix(std::vector<int>& inc, int& row, int& col);
   virtual std::vector<std::string> getLinearOutputParamNames();

protected:
  
   virtual void init();
   void setupParametersMultiExponential();

   void resizeLifetimeParameters(std::vector<std::shared_ptr<FittingParameter>>& params, int new_size, const std::string& name_prefix);

   int addDecayGroup(const std::vector<std::shared_ptr<AbstractConvolver>>& buffers, double factor, double* a, int adim, double& kap);
   int addLifetimeDerivative(int idx, double* b, int bdim);
   void addLifetimeKappaDerivative(int idx, double_iterator& kap_derv);
   int addContributionDerivatives(double* b, int bdim, double_iterator& kap_derv);
   int normaliseLinearParameters(float_iterator lin_variables, int n, float_iterator output, int& lin_idx);

   std::vector<std::shared_ptr<FittingParameter>> tau_parameters;
   std::vector<std::shared_ptr<FittingParameter>> beta_parameters;

   int n_exponential;
   bool contributions_global;

   std::vector<double> tau, tau_raw;
   std::vector<double> beta, beta_buf;
   std::vector<float> beta_buf_float;
   std::vector<std::shared_ptr<AbstractConvolver>> buffer;
   std::vector<double> channel_factors;
   std::vector<double> norm_channel_factors;

protected:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   const_double_iterator beta_param_values;
   int n_beta_free;
   double fixed_beta;
   friend class boost::serialization::access;
   
};

template<class Archive>
void MultiExponentialDecayGroupPrivate::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<AbstractDecayGroup>(*this);
   ar & tau_parameters;
   ar & beta_parameters;
   ar & n_exponential;
   ar & contributions_global;
   ar & channel_factors;
};

class MultiExponentialDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:

   MultiExponentialDecayGroup(int n_exponential_ = 1, bool contributions_global_ = false, const QString& name = "Multi-Exponential Decay") :
      MultiExponentialDecayGroupPrivate(n_exponential_, contributions_global_, name)
   {
   }


   MultiExponentialDecayGroup(const MultiExponentialDecayGroup& obj) :
      MultiExponentialDecayGroupPrivate(obj)
   {
      setupParametersMultiExponential();
      init();
   }

   AbstractDecayGroup* clone() const { return new MultiExponentialDecayGroup(*this); }
   void init() { MultiExponentialDecayGroupPrivate::init(); }

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(bool contributions_global MEMBER contributions_global WRITE setContributionsGlobal USER true);

protected:

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);

   friend class boost::serialization::access;

};

template<class Archive>
void MultiExponentialDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<MultiExponentialDecayGroupPrivate>(*this);
   ar & tau_parameters;
   ar & beta_parameters;
   ar & n_exponential;
   ar & contributions_global;
   ar & channel_factors;
};


BOOST_CLASS_TRACKING(MultiExponentialDecayGroupPrivate, track_always)
BOOST_CLASS_TRACKING(MultiExponentialDecayGroup, track_always)