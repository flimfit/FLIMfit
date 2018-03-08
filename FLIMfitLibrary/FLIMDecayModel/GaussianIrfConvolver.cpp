#include "GaussianIrfConvolver.h"


GaussianIrfConvolver::GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   AbstractConvolver(dp)
{
   double epsmch = std::numeric_limits<double>::epsilon();
   eps = sqrt(epsmch);

   sigma = dp->irf->gaussian_sigma;
   mu = dp->irf->gaussian_mu;
   T = dp->t_rep;

   a = 1.0 / (sqrt(2) * sigma);

   auto& t = dp->getTimepoints();

   if (!dp->equally_spaced_gates)
      std::runtime_error("Gates must be equally spaced");

   dt = t[1] - t[0];
   t0 = t[0];

   P.resize(t.size() + 1);
   for (int i = 0; i < P.size(); i++)
      P[i] = 0.5 * erf((t0 + i * dt - mu) * a);
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
   double rate_p = 1.0 / (tau + tau_p);

   computeVariables(rate, v);
   computeVariables(rate_p, vp);
}


void GaussianIrfConvolver::computeVariables(double rate, GaussianVariables& v)
{
   v.Q.resize(n_t + 1);
   v.R.resize(n_t + 1);

   v.tau = 1.0 / rate;

   double f = exp(T * rate);

   double b = (sigma * sigma * rate + mu) * a;
   v.c = (erf(b - T * a) - f * erf(b)) / (f - 1);
   v.d = 0.5 * v.tau * exp(rate * (0.5 * sigma * sigma * rate + mu));

   double e0 = exp(-t0 * rate);
   double de = exp(-dt * rate);
   for (int i = 0; i < v.Q.size(); i++)
   {
      v.Q[i] = erf(b - (i*dt + t0) * a);
      v.R[i] = e0;
      e0 *= de;
   }
}

double GaussianIrfConvolver::computeTimepoint(int i, const GaussianVariables& v) const
{
   return (v.tau * (P[i + 1] - P[i]) + v.d * (v.R[i + 1] * (v.Q[i + 1] + v.c) - v.R[i] * (v.Q[i] + v.c))) / dt;
}

void GaussianIrfConvolver::addDecay(double fact, double ref_lifetime, double decay[], int bin_shift) const
{
   auto& t = dp->getTimepoints();
   for (int i = 0; i < n_t; i++)
   {
      double D = computeTimepoint(i, v);
      for (int k = 0; k < n_chan; k++)
         decay[i + k*n_t] += D * channel_factors[k];
   }
}

void GaussianIrfConvolver::addDerivative(double fact, double ref_lifetime, double derv[]) const
{
   auto& t = dp->getTimepoints();
   for (int i = 0; i < n_t; i++)
   {
      double D = (computeTimepoint(i, vp) - computeTimepoint(i, v)) / eps * rate;
      for (int k = 0; k < n_chan; k++)
         derv[i + k*n_t] += D * channel_factors[k];
   }
}


