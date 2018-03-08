
#pragma once

#include "AbstractConvolver.h"

#include <vector>
#include <memory>

class GaussianIrfConvolver : public AbstractConvolver
{

public:
   GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp);

   void compute(double rate, int irf_idx, double t0_shift, const std::vector<double>& channel_factors);

   void addDecay(double fact, double ref_lifetime, double a[], int bin_shift = 0) const;
   void addDerivative(double fact, double ref_lifetime, double b[]) const;

private:

   double compute(double t) const;

   double dt;
   double sigma;
   double mu;
   double T;

   double a, b, c, d, A;
   double b1, c1, d1, A1;
   double eps, rate1;
};