#pragma once

#include "MultiExponentialDecayGroup.h"
#include <functional>

class FretDecayGroup : public MultiExponentialDecayGroup
{
   Q_OBJECT

public:

   FretDecayGroup(int n_donor_exponential_ = 1, int n_fret_populations_ = 1, bool include_donor_only = false);
   
   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE setNumExponential USER true);
   Q_PROPERTY(int n_fret_populations MEMBER n_fret_populations WRITE setNumFretPopulations USER true);
   Q_PROPERTY(bool include_donor_only MEMBER include_donor_only WRITE setIncludeDonorOnly USER true);
   Q_PROPERTY(bool include_acceptor MEMBER include_acceptor WRITE setIncludeAcceptor USER true);
   
   void setNumFretPopulations(int n_fret_populations_);
   void setIncludeDonorOnly(bool include_donor_only_);
   void setIncludeAcceptor(bool include_acceptor_);

   const vector<double>& getChannelFactors(int index);
   void setChannelFactors(int index, const vector<double>& channel_factors);


   int setVariables(const double* variables);
   int calculateModel(double* a, int adim, vector<double>& kap);
   int calculateDerivatives(double* b, int bdim, vector<double>& kap);

   int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int getLinearOutputs(float* lin_variables, float* output, int& lin_idx);

   int setupIncMatrix(std::vector<int>& inc, int& row, int& col);

   void getLinearOutputParamNames(vector<string>& names);

protected:

   void setupParameters();
   void init();

   int addLifetimeDerivativesForFret(int idx, double* b, int bdim, vector<double>& kap);
   int addFretEfficiencyDerivatives(double* b, int bdim, vector<double>& kap);
   int addAcceptorIntensityDerivatives(double* b, int bdim, vector<double>& kap);
   int addAcceptorLifetimeDerivatives(double* b, int bdim, vector<double>& kap);
   int addDirectAcceptorDerivatives(double* b, int bdim, vector<double>& kap);

   void addAcceptorContribution(int i, double factor, double* a, int adim, vector<double>& kap);
   void addAcceptorDerivativeContribution(int i, int j, double fact, double* b, int bdim, vector<double>& kap);

   vector<shared_ptr<FittingParameter>> tauT_parameters;
   shared_ptr<FittingParameter> A0_parameter;
   shared_ptr<FittingParameter> AD_parameter;
   shared_ptr<FittingParameter> tauA_parameter;

   int n_fret_populations = 1;
   bool include_donor_only = true;
   bool include_acceptor = true;
   
   vector<vector<double>> a_star;
   vector<double> tau_transfer;
   vector<vector<double>> tau_fret;
   double A0;
   double AD;
   double tauA;

   vector<vector<ExponentialPrecomputationBuffer>> fret_buffer;
   vector<vector<ExponentialPrecomputationBuffer>> acceptor_fret_buffer;
   std::unique_ptr<ExponentialPrecomputationBuffer> acceptor_buffer;
   std::unique_ptr<ExponentialPrecomputationBuffer> direct_acceptor_buffer;
   vector<double> acceptor_channel_factors;
   vector<double> direct_acceptor_channel_factors;

protected:
   int getNumPotentialChannels() { return 3; }
   
private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};

template<class Archive>
void FretDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<MultiExponentialDecayGroup>(*this);
   ar & tauT_parameters;
   ar & A0_parameter;
   ar & AD_parameter;
   ar & tauA_parameter;
   ar & n_fret_populations;
   ar & include_donor_only;
   ar & include_acceptor;
   ar & acceptor_channel_factors;
   ar & direct_acceptor_channel_factors;
};

/*
class QFretDecayGroup : virtual public QAbstractDecayGroup, virtual public FretDecayGroup
{
   Q_OBJECT

public:

   QFretDecayGroup(const QString& name = "FRET Decay", QObject* parent = 0) :
      FretDecayGroup(1, 1, false),
      QAbstractDecayGroup(name, parent) {};

   Q_PROPERTY(int n_exponential MEMBER n_exponential WRITE SetNumExponential USER true);
   Q_PROPERTY(int n_fret_populations MEMBER n_fret_populations WRITE SetNumFretPopulations USER true);
   Q_PROPERTY(bool include_donor_only MEMBER include_donor_only WRITE SetIncludeDonorOnly USER true);
   Q_PROPERTY(bool include_acceptor MEMBER include_acceptor WRITE SetIncludeAcceptor USER true);

private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};

template<class Archive>
void QFretDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & boost::serialization::base_object<FretDecayGroup>(*this);
};
*/