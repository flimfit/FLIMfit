
#define USE_SIMD true

#include "DataTransformer.h"
#include "GaussianIrfConvolver.h"
#include "FastErf.h"
#include <algorithm>

GaussianChannelConvolver::GaussianChannelConvolver(const GaussianParameters& params, const std::vector<double>& timepoints, double T_)
{
   double epsmch = std::numeric_limits<double>::epsilon();
   eps = sqrt(epsmch);

   sigma = params.sigma;
   mu = params.mu;
   T = T_;
   t0_shift = std::numeric_limits<double>::infinity();
   rate = -1;
   
   dt = timepoints[1] - timepoints[0];
   t0 = timepoints[0];
   n_t = (int) timepoints.size();

   n_tm = (int)std::ceil((n_t + 1) / 4.0);
   n_tmf = (int)std::floor(n_t / 4.0);


   size_t q_size = (n_tm) * 4;
   Qi.resize(q_size);
   Q.resize(q_size);
   Qp.resize(q_size);
   P.resize(q_size);
}

void GaussianChannelConvolver::compute(double rate_, double t0_shift_, double sigma_override)
{   
   // Don't compute if rate, t0 are the same
   if ((rate_ == rate) && (t0_shift_ == t0_shift) && 
       (sigma_override < 0 || sigma == sigma_override))
      return;

   if (sigma_override >= 0)
      sigma = sigma_override;

   a = 1.0 / (sqrt(2) * sigma);

   rate = rate_;
   double d_rate = eps * rate;
   double rate_p = rate + d_rate;

   if (t0_shift != t0_shift_)
   {
      t0_shift = t0_shift_;

      double tmua = (t0 - mu - t0_shift) * a;
      double dta = dt * a;

      double Plast = 0;
      double Pi = 0.5 * erf(tmua);
      for (int i = 0; i < P.size(); i++)
      {
         Plast = Pi;
         tmua += dta;
         Pi = 0.5 * erf(tmua);
         P[i] = Pi - Plast;
      }
   }

   computeQ(rate, Q);
   computeQ(rate_p, Qp);

#ifdef USE_SIMD
   __m256d* Qm = (__m256d*) Q.data();
   __m256d* Qpm = (__m256d*) Qp.data();
   __m256d inv_d_rate = _mm256_set1_pd(1.0 / d_rate);
   for (int i = 0; i < n_tm; i++)
      Qpm[i] = _mm256_mul_pd(_mm256_sub_pd(Qpm[i], Qm[i]), inv_d_rate);
#else
   for (int i = 0; i < Q.size(); i++)
   {
      Qp[i] -= Q[i];
      Qp[i] /= d_rate;
   }
#endif
}


void GaussianChannelConvolver::computeQ(double rate, aligned_vector<double>& Q)
{
   double tau = 1.0 / rate;

   double b = (sigma * sigma * rate + mu + t0_shift) * a;

   double f = exp(T * rate);
   double c = f < HUGE_VAL ? (erf(b - T * a) - f * erf(b)) / (f - 1) : -1.0;
   double d = 0.5 * tau * exp(rate * (0.5 * sigma * sigma * rate + mu + t0_shift));

   d = d < HUGE_VAL ? d : 0;
   double e0 = d * exp(-t0 * rate);
   double de = exp(-dt * rate);

   double bta = b - t0*a;
   double dta = -dt*a;

#ifdef USE_SIMD

   double de2 = de * de;
   __m256d e0m = _mm256_set_pd(e0 * de * de2, e0 * de2, e0 * de, e0);
   __m256d dem = _mm256_set1_pd(de2*de2);
   __m256d cm = _mm256_set1_pd(c);

   __m256d* Qim = (__m256d*) &Qi[0];
   
   int iL = std::floor((6.0 - bta) / (dta * 4));
   int iU = std::ceil((-6.0 - bta) / (dta * 4));
   iU = std::max(0, std::min(iU, n_tm));
   iL = std::max(0, std::min(iL, n_tm));

   __m256d dtam = _mm256_set1_pd(dta * 4);
   __m256d btavm = _mm256_set_pd(bta + dta * 3, bta + dta * 2, bta + dta, bta);
   btavm = _mm256_add_pd(btavm, _mm256_mul_pd(dtam, _mm256_set1_pd(iL)));

   auto setQ = [&](int i, __m256d Qerf) 
   { 
      Qim[i] = _mm256_mul_pd(Qerf, e0m);
      e0m = _mm256_mul_pd(e0m, dem);
   };

   for (int i = 0; i < iL; i++)
      setQ(i, _mm256_set1_pd(1.0 + c));

   for (int i = iL; i < iU; i++)
   {
      __m256d Qerf = _mm256_erf_pd_(btavm);
      setQ(i, _mm256_add_pd(Qerf, cm));
      btavm = _mm256_add_pd(btavm, dtam);
   }

   for (int i = iU; i < n_tm; i++)
      setQ(i, _mm256_set1_pd(-1.0 + c));

   __m256d* Qm = (__m256d*) &Q[0];
   __m256d* Pm = (__m256d*) &P[0];
   __m256d taum = _mm256_set1_pd(tau);

   for (int i = 0; i < n_t; i++)
      Q[i] = Qi[i + 1] - Qi[i];

   for (int i = 0; i < n_tm; i++)
   {
      __m256d Ptau = _mm256_mul_pd(taum, Pm[i]);
      Qm[i] = _mm256_fmadd_pd(taum, Pm[i], Qm[i]);
   }

#else 

   double Qlast = 0;
   double Qthis = (erf(bta) + c) * e0;
   for (int i = 0; i < P.size(); i++)
   {
      Qlast = Qthis;
      bta += dta;
      e0 *= de;
      Qthis = (erf(bta) + c) * e0;
      Q[i] = (Qthis - Qlast) + tau * P[i];
   }
#endif

}

void GaussianChannelConvolver::add(double fact, double_iterator decay, const aligned_vector<double>& Q) const
{
   fact /= dt;
#ifdef USE_SIMD

   __m256d factm = _mm256_set1_pd(fact);
   __m256d* decaym = (__m256d*) &decay[0];
   __m256d* Qm = (__m256d*) Q.data();

   for (int i = 0; i < n_tmf; i++)
      decaym[i] = _mm256_fmadd_pd(Qm[i], factm, decaym[i]);

   for (int i = n_tmf * 4; i < n_t; i++)
      decay[i] += Q[i] * fact;

#else
   for(int i=0; i<n_t; i++)
      decay[i] += Q[i] * fact;
#endif
}

void GaussianChannelConvolver::addDecay(double fact, double_iterator decay) const
{
   add(fact, decay, Q);
}

void GaussianChannelConvolver::addDerivative(double fact, double_iterator derv) const
{
   add(fact, derv, Qp);
}


GaussianIrfConvolver::GaussianIrfConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   AbstractConvolver(dp)
{

   irf = std::dynamic_pointer_cast<GaussianIrf>(dp->irf);
      
   auto& t = dp->getTimepoints();

   if (!dp->equally_spaced_gates)
      std::runtime_error("Gates must be equally spaced");

   for (auto& p : irf->gaussian_params)
      convolver.push_back(GaussianChannelConvolver(p, t, dp->t_rep));
};


void GaussianIrfConvolver::compute(double rate_, PixelIndex irf_idx, double t0_shift, double ref_lifetime)
{
   if (!std::isfinite(rate_))
      throw(std::runtime_error("Rate not finite"));

   t0_shift += irf->getT0Shift(irf_idx);

   double sigma_override = irf->getSigma(irf_idx);

   rate = rate_;

   for (auto& c : convolver)
      c.compute(rate, t0_shift, sigma_override);

}

void GaussianIrfConvolver::addDecay(double fact, const std::vector<double>& channel_factors, double_iterator decay) const
{
   auto& t = dp->getTimepoints();
   for (int k = 0; k < n_chan; k++)
      convolver[k].addDecay(fact * channel_factors[k], decay + k*n_t);
}

void GaussianIrfConvolver::addDerivative(double fact, const std::vector<double>& channel_factors, double_iterator derv) const
{
   auto& t = dp->getTimepoints();
   for (int k = 0; k < n_chan; k++)
      convolver[k].addDerivative(fact * channel_factors[k], derv + k*n_t);
}

void GaussianIrfConvolver::addIrf(double fact, const std::vector<double>& channel_factors, double_iterator derv) const
{
   //throw std::runtime_error("Adding IRF with gaussian convolver not implemented yet"); // TODO
}


