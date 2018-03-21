#include "GaussianIrfConvolver.h"

GaussianChannelConvolver::GaussianChannelConvolver(const GaussianParameters& params, const std::vector<double>& timepoints, double T_)
{
   double epsmch = std::numeric_limits<double>::epsilon();
   eps = sqrt(epsmch);

   sigma = params.sigma;
   mu = params.mu;
   T = T_;

   a = 1.0 / (sqrt(2) * sigma);

   dt = timepoints[1] - timepoints[0];
   t0 = timepoints[0];
   n_t = size(timepoints);
}

void GaussianChannelConvolver::compute(double rate, double t0_shift_)
{
   double tau = 1.0 / rate;
   double tau_p = eps * abs(tau);
   if (tau_p == 0.0) tau_p = eps;
   double rate_p = 1.0 / (tau + tau_p);

   t0_shift = t0_shift_;

   P.resize(n_t + 1);
   for (int i = 0; i < P.size(); i++)
      P[i] = 0.5 * erf((t0 + i * dt - mu - t0_shift) * a);


   computeVariables(rate, v);
   computeVariables(rate_p, vp);
}


void GaussianChannelConvolver::computeVariables(double rate_, GaussianVariables& v)
{
   v.Q.resize(n_t + 1);
   v.R.resize(n_t + 1);

   if(rate_ > 0.02) // 50ps
      rate_ = 0.02;

   rate = rate_;
   v.tau = 1.0 / rate;

   double f = exp(T * rate);

   double b = (sigma * sigma * rate + mu + t0_shift) * a;
   v.c = (erf(b - T * a) - f * erf(b)) / (f - 1);
   v.d = 0.5 * v.tau * exp(rate * (0.5 * sigma * sigma * rate + mu + t0_shift));

   double e0 = exp(-t0 * rate);
   double de = exp(-dt * rate);
   for (int i = 0; i < v.Q.size(); i++)
   {
      v.Q[i] = erf(b - (i*dt + t0) * a);
      v.R[i] = e0;
      e0 *= de;
   }
}

double GaussianChannelConvolver::compute(int i, const GaussianVariables& v) const
{
   return (v.tau * (P[i + 1] - P[i]) + v.d * (v.R[i + 1] * (v.Q[i + 1] + v.c) - v.R[i] * (v.Q[i] + v.c))) / dt;
}

double GaussianChannelConvolver::computeDecay(int i) const
{
   return compute(i, v);
}

double GaussianChannelConvolver::computeDerivative(int i) const
{
   return (compute(i, vp) - compute(i, v)) / (eps * rate);
}


GaussianIrfConvolver::GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   AbstractConvolver(dp)
{
   auto& t = dp->getTimepoints();

   if (!dp->equally_spaced_gates)
      std::runtime_error("Gates must be equally spaced");

   for (auto& p : irf->gaussian_params)
      convolver.push_back(GaussianChannelConvolver(p, t, dp->t_rep));
};


void GaussianIrfConvolver::compute(double rate_, int irf_idx, double t0_shift)
{
   // Don't compute if rate is the same
   if (rate_ == rate)
      return;

   if (!std::isfinite(rate_))
      throw(std::runtime_error("Rate not finite"));

   if (rate > 0.02) // 50ps
      rate = 0.02;

   rate = rate_;

   for (auto& c : convolver)
      c.compute(rate, t0_shift);

}

void GaussianIrfConvolver::addDecay(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double decay[], int bin_shift) const
{
   auto& t = dp->getTimepoints();
   for (int k = 0; k < n_chan; k++)
      for (int i = 0; i < n_t; i++)
         decay[i + k*n_t] += fact * convolver[k].computeDecay(i) * channel_factors[k];
}

void GaussianIrfConvolver::addDerivative(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double derv[]) const
{
   auto& t = dp->getTimepoints();
   for (int k = 0; k < n_chan; k++)
      for (int i = 0; i < n_t; i++)
        derv[i + k*n_t] += fact * convolver[k].computeDerivative(i) * channel_factors[k];
}


