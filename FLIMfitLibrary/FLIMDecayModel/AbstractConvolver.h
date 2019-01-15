#pragma once

#include "InstrumentResponseFunction.h"
#include "DataTransformer.h"
#include "AlignedVectors.h"
#include <memory>

class AbstractConvolver
{
protected:
   AbstractConvolver(std::shared_ptr<TransformedDataParameters> dp);

public:
   virtual void compute(double rate, int irf_idx = 0, double t0_shift = 0, double reference_lifetime = 0) = 0;

   virtual void addDecay(double fact, const std::vector<double>& channel_factors, double_iterator a) const = 0;
   virtual void addDerivative(double fact, const std::vector<double>& channel_factors, double_iterator b) const = 0;

   double getRate() const { return rate; };

   static std::shared_ptr<AbstractConvolver> make(std::shared_ptr<TransformedDataParameters> dp);
   static std::vector<std::shared_ptr<AbstractConvolver>> make_vector(size_t n, std::shared_ptr<TransformedDataParameters> dp);

protected:

   std::shared_ptr<InstrumentResponseFunction> irf;
   std::shared_ptr<TransformedDataParameters> dp;
   
   double rate = -1;

   int n_chan;
   int n_t;
};