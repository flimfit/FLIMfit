#pragma once

#include "MultiExponentialDecayGroup.h"
#include <functional>

class FretDecayGroup : public MultiExponentialDecayGroupPrivate
{
   Q_OBJECT

public:

   FretDecayGroup(int n_donor_exponential_ = 1, int n_fret_populations_ = 1, bool include_donor_only = false);
   FretDecayGroup(const FretDecayGroup& obj);

   AbstractDecayGroup* clone() const { return new FretDecayGroup(*this); }

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(int n_fret_populations MEMBER n_fret_populations WRITE setNumFretPopulations USER true);
   Q_PROPERTY(bool include_donor_only MEMBER include_donor_only WRITE setIncludeDonorOnly USER true);
   Q_PROPERTY(bool include_acceptor MEMBER include_acceptor WRITE setIncludeAcceptor USER true);
   
   void setNumExponential(int n_exponential_);
   void setNumFretPopulations(int n_fret_populations_);
   void setIncludeDonorOnly(bool include_donor_only_);
   void setIncludeAcceptor(bool include_acceptor_);

   const std::vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const std::vector<double>& channel_factors);


   int setVariables(const double* variables);
   int calculateModel(double* a, int adim, double& kap, int bin_shift = 0);
   int calculateDerivatives(double* b, int bdim, double kap_derv[]);

   int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int getLinearOutputs(float* lin_variables, float* output, int& lin_idx);

   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   void getLinearOutputParamNames(std::vector<std::string>& names);
   void getNonlinearOutputParamNames(std::vector<std::string>& names);

protected:

   void setupParameters();
   void init();

   int addLifetimeDerivativesForFret(int idx, double* b, int bdim, double kap_derv[]);
   int addFretEfficiencyDerivatives(double* b, int bdim, double kap_derv[]);
   int addAcceptorIntensityDerivatives(double* b, int bdim, double kap_derv[]);
   int addAcceptorLifetimeDerivatives(double* b, int bdim, double kap_derv[]);
   int addDirectAcceptorDerivatives(double* b, int bdim, double kap_derv[]);

   void addAcceptorContribution(int i, double factor, double* a, int adim, double& kap, int bin_shift = 0);
   void addAcceptorDerivativeContribution(int i, int j, double fact, double* b, int bdim, double& kap_derv);

   std::vector<std::shared_ptr<FittingParameter>> tauT_parameters;
   std::shared_ptr<FittingParameter> Q_parameter;
   std::shared_ptr<FittingParameter> Qsigma_parameter;
   std::shared_ptr<FittingParameter> tauA_parameter;

   int n_fret_populations = 1;
   bool include_donor_only = true;
   bool include_acceptor = true;
   
   std::vector<std::vector<double>> a_star;
   std::vector<double> tau_transfer;
   std::vector<std::vector<double>> tau_fret;
   double Q;
   double Qsigma;
   double tauA;

   std::vector<std::vector<ExponentialPrecomputationBuffer>> fret_buffer;
   std::vector<std::vector<ExponentialPrecomputationBuffer>> acceptor_fret_buffer;
   std::unique_ptr<ExponentialPrecomputationBuffer> acceptor_buffer;
   std::vector<double> acceptor_channel_factors;

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
   ar & tauA_parameter;
   ar & n_fret_populations;
   ar & include_donor_only;
   ar & include_acceptor;
   ar & acceptor_channel_factors;
};
