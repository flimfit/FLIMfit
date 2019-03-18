#pragma once

#include "AbstractConvolver.h"

#include <vector>
#include <memory>
#include <immintrin.h>

struct GaussianVariables
{
   std::vector<double> Q;
};

class GaussianChannelConvolver
{
public:

   GaussianChannelConvolver(const GaussianParameters& params, const std::vector<double>& timepoints, double T);

   void compute(double rate, double t0_shift);

   void addDecay(double fact, double_iterator decay) const;
   void addDerivative(double fact, double_iterator derv) const;

protected:

   void computeQ(double rate, aligned_vector<double>& Q);

   void add(double fact, double_iterator decay, const aligned_vector<double>& Q) const;

   int n_t;
   double dt;
   double t0;

   double sigma;
   double mu;
   double T;

   int n_tm;
   int n_tmf;


   aligned_vector<double> P;
   double a;

   aligned_vector<double> Q, Qp, Qi;

   double eps;
   double rate;
   double t0_shift;
};


class GaussianIrfConvolver : public AbstractConvolver
{

public:
   GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp);

   void compute(double rate, PixelIndex irf_idx = 0, double t0_shift = 0, double ref_lifetime = 0);

   void addDecay(double fact, const std::vector<double>& channel_factors, double_iterator a) const;
   void addDerivative(double fact, const std::vector<double>& channel_factors, double_iterator b) const;

private:

   std::vector<GaussianChannelConvolver> convolver;
};