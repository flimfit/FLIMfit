
#pragma once

#include "AbstractConvolver.h"

#include <vector>
#include <memory>

struct GaussianVariables
{
   double tau, c, d;
   std::vector<double> Q, R;
};

class GaussianIrfConvolver : public AbstractConvolver
{

public:
   GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp);

   void compute(double rate, int irf_idx, double t0_shift, const std::vector<double>& channel_factors);

   void addDecay(double fact, double ref_lifetime, double a[], int bin_shift = 0) const;
   void addDerivative(double fact, double ref_lifetime, double b[]) const;

private:

   void computeVariables(double rate, GaussianVariables& v);
   double computeTimepoint(int i, const GaussianVariables& v) const;

   double dt;
   double t0;
   double sigma;
   double mu;
   double T;

   std::vector<double> P;
   double a;

   GaussianVariables v, vp;
   double eps;
};