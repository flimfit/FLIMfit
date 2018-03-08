#include "GaussianIrfConvolver.h"


GaussianIrfConvolver::GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   AbstractConvolver(dp)
{
   double epsmch = std::numeric_limits<double>::epsilon();
   eps = sqrt(epsmch);

   sigma = dp->irf->gaussian_sigma;
   mu = dp->irf->gaussian_mu;
   T = dp->t_rep;
};

void GaussianIrfConvolver::compute(double rate_, int irf_idx, double t0_shift, const std::vector<double>& channel_factors_)
{
   channel_factors = channel_factors_;
   
   // Don't compute if rate is the same
   if (rate_ == rate)
      return;
  
   if (!std::isfinite(rate_))
      throw(std::runtime_error("Rate not finite"));

   if (rate > 0.02) // 50ps
      rate = 0.02;
      
   rate = rate_;

   double tau = 1.0 / rate;
   double tau_p = eps * abs(tau);
   if (tau_p == 0.0) tau_p = eps;
   rate1 = 1.0 / (tau + tau_p);

   a = sqrt(2) * sigma;
   b = (sigma * sigma * rate + mu) / a;
   c = erf(b);
   d = (c - erf(b - T / a)) / (exp(T * rate) - 1);
   A = 0.5 * exp(rate * (0.5 * sigma * sigma * rate + mu));

   b1 = (sigma * sigma * rate1 + mu) / a;
   c1 = erf(b1);
   d1 = (c1 - erf(b1 - T / a)) / (exp(T * rate1) - 1);
   A1 = 0.5 * exp(rate1 * (0.5 * sigma * sigma * rate1 + mu));
}

double GaussianIrfConvolver::compute(double t) const
{
   return A * exp(-t * rate) * (c - erf(b - t / a) + d);
}

void GaussianIrfConvolver::addDecay(double fact, double ref_lifetime, double decay[], int bin_shift) const
{
   auto& t = dp->getTimepoints();
   for (int i = 0; i < n_t; i++)
   {
      double D = A * exp(-t[i] * rate) * (c - erf(b - t[i] / a) + d);
      for (int k = 0; k < n_chan; k++)
         decay[i + k*n_t] += D * channel_factors[k];
   }
}

void GaussianIrfConvolver::addDerivative(double fact, double ref_lifetime, double derv[]) const
{
   auto& t = dp->getTimepoints();
   for (int i = 0; i < n_t; i++)
   {
      double D0 = A * exp(-t[i] * rate) * (c - erf(b - t[i] / a) + d);
      double D1 = A1 * exp(-t[i] * rate1) * (c1 - erf(b1 - t[i] / a) + d1);
      double D = (D1 - D0) / eps * rate;
      for (int k = 0; k < n_chan; k++)
         derv[i + k*n_t] += D * channel_factors[k];
   }
}


