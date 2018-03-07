#pragma once

#include "InstrumentResponseFunction.h"
#include "DataTransformer.h"

#include <vector>
#include <memory>

class AbstractConvolver
{
protected:
   AbstractConvolver(std::shared_ptr<TransformedDataParameters> dp);

public:
   virtual void compute(double rate, int irf_idx, double t0_shift, const std::vector<double>& channel_factors) = 0;

   virtual void addDecay(double fact, double ref_lifetime, double a[], int bin_shift = 0) const = 0;
   virtual void addDerivative(double fact, double ref_lifetime, double b[]) const = 0;

   double getRate() const { return rate; };

   static std::shared_ptr<AbstractConvolver> make(std::shared_ptr<TransformedDataParameters> dp);

protected:

   std::shared_ptr<InstrumentResponseFunction> irf;
   std::shared_ptr<TransformedDataParameters> dp;

   std::vector<double> channel_factors;
   
   double rate = -1;

   int n_chan;
   int n_t;
};