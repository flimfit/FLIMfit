#pragma once

#include "MultiExponentialDecayGroup.h"
#include <functional>

class KappaFactor
{
public:

   KappaFactor(int n = 1) : 
      n(n), f(n), p(n)
   {
      if (n == 1)
      {
         f[0] = 1;
         p[0] = 1;
      }
      else
      {
         double sump = 0;
         double df = 4.0 / n;
         double p0 = log(2.0 + sqrt(3.0)) / sqrt(3.0);
         for (int i = 0; i < n; i++)
         {
            double f0 = i * df;
            double f1 = f0 + df;
            f[i] = f0 + 0.5 * df;
            
            p[i] = p0 * (sqrt(f1) - sqrt(f0));
            if (f0 >= 1.0)
               p[i] -= ((sqrt(f1)*log(sqrt(f1)+sqrt(f1-1))-sqrt(f1-1)) - 
                       (sqrt(f0)*log(sqrt(f0)+sqrt(f0-1))-sqrt(f0-1))) / sqrt(3.0);       

            sump += p[i];
         }         
      }
   }

   int size() { return n; }

   std::vector<double> f;
   std::vector<double> p;
   int n;
};


class FretDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:

   FretDecayGroup(int n_donor_exponential_ = 1, int n_fret_populations_ = 1, bool include_donor_only = false);
   FretDecayGroup(const FretDecayGroup& obj);

   AbstractDecayGroup* clone() const { return new FretDecayGroup(*this); }

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(int n_acceptor_exponential MEMBER n_acceptor_exponential WRITE setNumAcceptorExponential USER true);
   Q_PROPERTY(int n_fret_populations MEMBER n_fret_populations WRITE setNumFretPopulations USER true);
   Q_PROPERTY(bool include_donor_only MEMBER include_donor_only WRITE setIncludeDonorOnly USER true);
   Q_PROPERTY(bool include_acceptor MEMBER include_acceptor WRITE setIncludeAcceptor USER true);
   Q_PROPERTY(bool use_static_model MEMBER use_static_model WRITE setUseStaticModel USER true);

   void setNumExponential(int n_exponential_);
   void setNumAcceptorExponential(int n_acceptor_exponential_);
   void setNumFretPopulations(int n_fret_populations_);
   void setIncludeDonorOnly(bool include_donor_only_);
   void setIncludeAcceptor(bool include_acceptor_);
   void setUseStaticModel(bool use_static_model_);

   void setContributionsGlobal(bool contributions_global) {}; // contributions must be global

   const std::vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const std::vector<double>& channel_factors);

   int setVariables(const_double_iterator variables);
   int calculateModel(double_iterator a, int adim, double& kap);
   int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);

   int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx);
   int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx);

   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   std::vector<std::string> getLinearOutputParamNames();
   std::vector<std::string> getNonlinearOutputParamNames();

protected:

   void setupParameters();
   void init();

   int addLifetimeDerivativesForFret(int idx, double_iterator b, int bdim, double_iterator& kap_derv);
   int addContributionDerivativesForFret(double_iterator b, int bdim, double_iterator& kap_derv);
   int addFretEfficiencyDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   int addAcceptorIntensityDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   int addAcceptorLifetimeDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   int addDirectAcceptorDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);

   void addAcceptorContribution(int i, double factor, double_iterator a, int adim, double& kap);
   void addAcceptorDerivativeContribution(int i, int j, int k, int m, double fact, double_iterator b, int bdim, double& kap_derv);

   std::vector<std::shared_ptr<FittingParameter>> tauT_parameters;
   std::shared_ptr<FittingParameter> A_parameter;
   std::shared_ptr<FittingParameter> Q_parameter;
   std::shared_ptr<FittingParameter> Qsigma_parameter;
   std::vector<std::shared_ptr<FittingParameter>> tauA_parameters;
   std::vector<std::shared_ptr<FittingParameter>> betaA_parameters;

   double a_star(int i, int k, int j, int m);
   double k_transfer(int i, int k);

   std::vector<double> acceptor_channel_factors;
   std::vector<double> norm_acceptor_channel_factors;

   int n_acceptor_exponential_requested = 1;
   int n_acceptor_exponential = 1;
   int n_fret_populations = 1;
   bool include_donor_only = true;
   bool include_acceptor = true;
   bool use_static_model = true;
   
   double A;
   double Q;
   double Qsigma;
   
   std::vector<double> k_transfer_0;
   std::vector<double> k_A;
   std::vector<double> betaA;

   std::vector<std::vector<std::vector<std::shared_ptr<AbstractConvolver>>>> fret_buffer;
   std::vector<std::shared_ptr<AbstractConvolver>> acceptor_buffer;

   int n_kappa = 1;
   KappaFactor kappa_factor;

protected:
   int getNumPotentialChannels() { return 2; }
   
private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};

template<class Archive>
void FretDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<MultiExponentialDecayGroupPrivate>(*this);
   ar & tauT_parameters;
   ar & Q_parameter;
   ar & Qsigma_parameter;

   if (version >= 3)
   {
      ar & tauA_parameters;
   } 
   else
   {
      std::shared_ptr<FittingParameter> t;
      ar & t;
      tauA_parameters = { t };
   }

   ar & n_fret_populations;
   ar & include_donor_only;
   ar & include_acceptor;
   ar & acceptor_channel_factors;

   if (version >= 2)
      ar & A_parameter;

   setupParameters();
};

BOOST_CLASS_VERSION(FretDecayGroup, 3)