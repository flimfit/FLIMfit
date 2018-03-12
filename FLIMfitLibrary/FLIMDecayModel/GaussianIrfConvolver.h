
#pragma once

#include "AbstractConvolver.h"

#include <vector>
#include <memory>

struct GaussianVariables
{
   double tau, c, d;
   std::vector<double> Q, R;
};

class GaussianChannelConvolver
{
public:

   GaussianChannelConvolver(const GaussianParameters& params, const std::vector<double>& timepoints, double T);

   void compute(double rate, double t0_shift);

   double computeDecay(int i) const;
   double computeDerivative(int i) const;

protected:

   void computeVariables(double rate, GaussianVariables& v);
   double compute(int i, const GaussianVariables& v) const;

   int n_t;
   double dt;
   double t0;

   double sigma;
   double mu;
   double T;

   std::vector<double> P;
   double a;

   GaussianVariables v, vp;
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