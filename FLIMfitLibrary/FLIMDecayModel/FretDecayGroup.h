#pragma once

#include "MultiExponentialDecayGroup.h"
#include <functional>

class FretDecayGroup : virtual public MultiExponentialDecayGroup
{
public:

   FretDecayGroup(int n_donor_exponential_ = 1, int n_fret_populations_ = 1, bool include_donor_only = false);
   void SetNumFretPopulations(int n_fret_populations_);
   void SetIncludeDonorOnly(bool include_donor_only_);
   void SetIncludeAcceptor(bool include_acceptor_);

   const vector<double>& GetChannelFactors(int index);
   void SetChannelFactors(int index, const vector<double>& channel_factors);


   int SetVariables(const double* variables);
   int CalculateModel(double* a, int adim, vector<double>& kap);
   int CalculateDerivatives(double* b, int bdim, vector<double>& kap);

   int GetNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx);
   int GetLinearOutputs(float* lin_variables, float* output, int& lin_idx);

   int SetupIncMatrix(int* inc, int& row, int& col);

   void GetLinearOutputParamNames(vector<string>& names);

protected:

   void SetupParameters();
   void Init();

   int AddLifetimeDerivativesForFret(int idx, double* b, int bdim, vector<double>& kap);
   int AddFretEfficiencyDerivatives(double* b, int bdim, vector<double>& kap);
   int AddAcceptorIntensityDerivatives(double* b, int bdim, vector<double>& kap);
   int AddAcceptorLifetimeDerivatives(double* b, int bdim, vector<double>& kap);
   int AddDirectAcceptorDerivatives(double* b, int bdim, vector<double>& kap);

   void AddAcceptorContribution(int i, double factor, double* a, int adim, vector<double>& kap);
   void AddAcceptorDerivativeContribution(int i, int j, double fact, double* b, int bdim, vector<double>& kap);

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
   int GetNumPotentialChannels() { return 3; }
   
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
