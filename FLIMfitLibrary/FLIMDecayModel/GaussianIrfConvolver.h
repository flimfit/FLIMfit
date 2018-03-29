
#pragma once

#include "AbstractConvolver.h"

#include <vector>
#include <memory>

struct GaussianVariables
{
   std::vector<double> Q;
};

class GaussianChannelConvolver
{
public:

   GaussianChannelConvolver(const GaussianParameters& params, const std::vector<double>& timepoints, double T);

   void compute(double rate, double t0_shift);

   void addDecay(double fact, double* decay) const;
   void addDerivative(double fact, double* derv) const;

protected:

   void computeQ(double rate, std::vector<double>& Q);

   void add(double fact, double* decay, const std::vector<double>& Q) const;

   int n_t;
   double dt;
   double t0;

   double sigma;
   double mu;
   double T;

   int n_tm;

   std::vector<double> P;
   double a;

   std::vector<double> Q, Qp;
   double eps;
   double rate;
   double t0_shift;
};


class GaussianIrfConvolver : public AbstractConvolver
{

public:
   GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp);

   void compute(double rate, int irf_idx, double t0_shift);

   void addDecay(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double a[], int bin_shift = 0) const;
   void addDerivative(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double b[]) const;

private:

   std::vector<GaussianChannelConvolver> convolver;
};