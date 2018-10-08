#include "GaussianIrfConvolver.h"
#include "mkl_vml_functions.h"
#include "mkl.h"

#define AVX 1

GaussianChannelConvolver::GaussianChannelConvolver(const GaussianParameters& params, const std::vector<double>& timepoints, double T_)
{
   double epsmch = std::numeric_limits<double>::epsilon();
   eps = sqrt(epsmch);

   sigma = params.sigma;
   mu = params.mu;
   T = T_;
   t0_shift = std::numeric_limits<double>::infinity();

   a = 1.0 / (sqrt(2) * sigma);

   dt = timepoints[1] - timepoints[0];
   t0 = timepoints[0];
   n_t = (int) timepoints.size();

   n_tm = (int)std::ceil((n_t + 1) / 4.0);
}

void GaussianChannelConvolver::compute(double rate, double t0_shift_)
{
   double d_rate = eps * rate;
   double rate_p = rate + d_rate;

   if (t0_shift != t0_shift_)
   {
      t0_shift = t0_shift_;

      P.resize(n_tm * 4);

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

   for (int i = 0; i < Q.size(); i++)
   {
      Qp[i] -= Q[i];
      Qp[i] /= d_rate;
   }
}


void GaussianChannelConvolver::computeQ(double rate_, aligned_vector<double>& Q)
{
   Q.resize(n_tm * 4);

   rate = rate_;
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

#ifdef AVX

   aligned_vector<double> Qi(n_tm * 4);
   aligned_vector<double> btav(n_tm * 4);

   __m256d dtam = _mm256_set1_pd(dta * 4);
   __m256d* btavm = (__m256d*) btav.data();
   btavm[0] = _mm256_set_pd(bta + dta * 3, bta + dta * 2, bta + dta, bta);
   for (int i = 1; i < n_tm; i++)
      btavm[i] = _mm256_add_pd(btavm[i - 1], dtam);

   vdErf(n_t+1, btav.data(), Qi.data());

   double de2 = de * de;
   __m256d e0m = _mm256_set_pd(e0 * de * de2, e0 * de2, e0 * de, e0);
   __m256d dem = _mm256_set1_pd(de2*de2);
   __m256d cm = _mm256_set1_pd(c);

   __m256d* Qim = (__m256d*) &Qi[0];
   __m256d* Qim1 = (__m256d*) &Qi[1];

   for (int i = 0; i < n_tm; i++)
   {
      __m256d Qimi = _mm256_add_pd(Qim[i], cm);
      Qim[i] = _mm256_mul_pd(Qimi, e0m);
      e0m = _mm256_mul_pd(e0m, dem);
   }

   __m256d* Qm = (__m256d*) &Q[0];
   __m256d* Pm = (__m256d*) &P[0];
   __m256d taum = _mm256_set1_pd(tau);


   for (int i = 0; i < n_t; i++)
      Q[i] = Qi[i + 1] - Qi[i];

   for (int i = 0; i < n_tm; i++)
   {
      __m256d Qmi = _mm256_sub_pd(Qim1[i], Qim[i]);
      __m256d Ptau = _mm256_mul_pd(taum, Pm[i]);
      Qm[i] = _mm256_add_pd(Qm[i], Ptau);
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
#ifdef _TODO_AVX_ // decay may not be multiple of 4
   __m256d factm = _mm256_set1_pd(fact / dt);
   __m256d* decaym = (__m256d*) &decay[0];
   __m256d* Qm = (__m256d*) Q.data();
   for (int i = 0; i < n_tm; i++)
   {  
      __m256d Qfm = _mm256_mul_pd(Qm[i], factm);
      decaym[i] = _mm256_add_pd(decaym[i], Qfm);
   }
#else
   fact /= dt;
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
   vmlSetMode(VML_EP);

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

   rate = rate_;

   for (auto& c : convolver)
      c.compute(rate, t0_shift);

}

void GaussianIrfConvolver::addDecay(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double_iterator decay) const
{
   auto& t = dp->getTimepoints();
   for (int k = 0; k < n_chan; k++)
      convolver[k].addDecay(fact * channel_factors[k], decay + k*n_t);
}

void GaussianIrfConvolver::addDerivative(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double_iterator derv) const
{
   auto& t = dp->getTimepoints();
   for (int k = 0; k < n_chan; k++)
      convolver[k].addDerivative(fact * channel_factors[k], derv + k*n_t);
}


