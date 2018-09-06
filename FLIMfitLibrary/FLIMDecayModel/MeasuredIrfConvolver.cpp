 //=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================


#include "MeasuredIrfConvolver.h"
#include <iostream>
#include <cmath>

#ifdef __llvm__ 
#include <x86intrin.h>
#endif

MeasuredIrfConvolver::MeasuredIrfConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   AbstractConvolver(dp), n_irf(irf->n_irf)
{
   irf_exp_factor.resize(n_chan, aligned_vector<double>(n_irf));
   cum_irf_exp_factor.resize(n_chan, aligned_vector<double>(n_irf));
   irf_exp_t_factor.resize(n_chan, aligned_vector<double>(n_irf));
   cum_irf_exp_t_factor.resize(n_chan, aligned_vector<double>(n_irf));
   irf_exp_factor.resize(n_chan, aligned_vector<double>(n_t));
   model_decay.resize(n_t);

   irf_working.resize(n_irf * n_chan);

   calculateIRFMax();
};

void MeasuredIrfConvolver::compute(double rate_, int irf_idx, double t0_shift)
{
   // Don't compute if rate is the same
   if (rate_ == rate)
      return;
  
   if (!std::isfinite(rate_))
      throw(std::runtime_error("Rate not finite"));
      
   rate = rate_;

   computeIRFFactors(rate, irf_idx, t0_shift);
   computeModelFactors(rate);
}

void MeasuredIrfConvolver::computeIRFFactors(double rate, int irf_idx, double t0_shift)
{
   double_iterator lirf = irf->getIRF(irf_idx, t0_shift, irf_working.begin()); // TODO: add image irf shifting to GetIRF
   double t0 = irf->getT0();
   double dt_irf = irf->timebin_width;

   assert(dt_irf > 0);

   // IRF exponential factor
   //------------------------------------------------
   double e0 = exp(t0  * rate);
   double de = exp(+dt_irf * rate);


   int n_loop = n_irf / 2;

   for (int k = 0; k < n_chan; k++)
   {
      __m128d  ej_ = _mm_setr_pd(e0, e0*de);
      __m128d  de_ = _mm_set1_pd(de*de);

      __m128d* dest_ = (__m128d*) irf_exp_factor[k].data();
      __m128d* irf_ = (__m128d*) (&lirf[k * n_irf]);

      for (int j = 0; j < n_loop; j++)
      {
         dest_[j] = _mm_mul_pd(irf_[j], ej_);
         ej_ = _mm_mul_pd(ej_, de_);
      }
   }

   // Cumulative IRF expontial
   //------------------------------------------------
   for (int k = 0; k < n_chan; k++)
   {
      double cum = 0;
      for (int j = 0; j < n_irf; j++)
      {
         cum += irf_exp_factor[k][j];
         cum_irf_exp_factor[k][j] = cum;
      }
   }


   // IRF exponential factor * t_irf
   //------------------------------------------------
   __m128d dt_irf_ = _mm_set1_pd(dt_irf * 2);

   for (int k = 0; k < n_chan; k++)
   {
      __m128d* dest_ = (__m128d*) irf_exp_t_factor[k].data();
      __m128d* src_ = (__m128d*) irf_exp_factor[k].data();
      __m128d t_irf_ = _mm_setr_pd(t0, t0 + dt_irf);

      for (int j = 0; j < n_loop; j++)
      {
         *(dest_++) = _mm_mul_pd(*(src_++), t_irf_);
         t_irf_ = _mm_add_pd(t_irf_, dt_irf_);
      }
   }

   // Cumulative IRF expontial * t_irf
   //------------------------------------------------
   for (int k = 0; k < n_chan; k++)
   {
      double cum = 0;
      for (int j = 0; j < n_irf; j++)
      {
         cum += irf_exp_t_factor[k][j];
         cum_irf_exp_t_factor[k][j] = cum;
      }
   }

}

void MeasuredIrfConvolver::computeModelFactors(double rate)
{
   double fact = 1;

   if (irf->type == Reference)
      fact *= irf->timebin_width;

   auto& t = dp->getTimepoints();
   auto& t_int = dp->getGateIntegrationTimes();
   
   double de = exp((t[0] - t[1]) * rate);

   if (dp->equally_spaced_gates)
   {
      double e0 = exp(-t[0] * rate);
      double ej = e0;
      for (int j = 0; j < n_t; j++)
      {
         model_decay[j] = fact * ej * t_int[j];
         ej *= de;
      }
   }
   else
   {
      for (int j = 0; j < n_t; j++)
         model_decay[j] = fact * exp(-t[j] * rate) * t_int[j];
   }
}




void MeasuredIrfConvolver::convolve(int k, int i, double pulse_fact, double& c) const
{
   const auto& exp_irf_cum_buf = cum_irf_exp_factor[k];
   const auto& exp_irf_buf = irf_exp_factor[k];

   int j = k*n_t + i;
   int idx = irf_max[j];

   c = exp_irf_cum_buf[idx] - 0.5*exp_irf_buf[idx];

   if (pulse_fact > 0 && pulse_fact < HUGE_VAL)
      c += (exp_irf_cum_buf[n_irf - 1] - 0.5*exp_irf_buf[n_irf - 1]) / pulse_fact;
}



void MeasuredIrfConvolver::convolveDerivative(double t, int k, int i, double pulse_fact, double pulse_fact_der, double ref_fact_a, double ref_fact_b, double& c) const
{
   const auto& exp_irf_tirf_cum_buf = cum_irf_exp_t_factor[k];
   const auto& exp_irf_tirf_buf = irf_exp_t_factor[k];
   const auto& exp_irf_cum_buf = cum_irf_exp_factor[k];
   const auto& exp_irf_buf = irf_exp_factor[k];

   double c_rep;

   int idx = irf_max[k*n_t + i];
   int irf_end = n_irf - 1;

   c = (t * ref_fact_a + ref_fact_b) * exp_irf_cum_buf[idx] - exp_irf_tirf_cum_buf[idx] * ref_fact_a;
   c -= 0.5 * ((t * ref_fact_a + ref_fact_b) * exp_irf_buf[idx] - exp_irf_tirf_buf[idx] * ref_fact_a);


   if (pulse_fact > 0)
   {
      c_rep = (t * ref_fact_a + ref_fact_b) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact_a;
      c_rep -= 0.5 * ((t * ref_fact_a + ref_fact_b) * exp_irf_buf[irf_end] - exp_irf_tirf_buf[irf_end] * ref_fact_a);
      c_rep /= pulse_fact;
      c += c_rep;

      c += (exp_irf_cum_buf[n_irf - 1] - 0.5*exp_irf_buf[n_irf - 1]) * ref_fact_a / pulse_fact_der;
   }
}



void MeasuredIrfConvolver::addDecay(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double_iterator a) const
{
   double c;

   fact *= (irf->type == Reference && ref_lifetime > 0) ? (1 / ref_lifetime - rate) : 1;

   double pulse_fact;

   const double x_max = -log(std::numeric_limits<double>::epsilon());
   if (dp->t_rep * rate > x_max)
      pulse_fact = 0;
   else
      pulse_fact = exp(dp->t_rep * rate) - 1;

   int idx = 0;
   for (int k = 0; k<n_chan; k++)
   {
      for (int i = 0; i<n_t; i++)
      {
         convolve(k, i, pulse_fact, c);
         a[i+k*n_t] += model_decay[i] * c * fact * channel_factors[k];
      }
   }
}

void MeasuredIrfConvolver::addDerivative(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double_iterator b) const
{
   double c;

   double ref_fact_a = (irf->type == Reference && ref_lifetime > 0) ? (1 / ref_lifetime - rate) : 1;
   double ref_fact_b = (irf->type == Reference && ref_lifetime > 0) ? 1 : 0;

   double t_rep = dp->t_rep;
   double pulse_fact = exp(t_rep * rate) - 1;
   double pulse_fact_der = pulse_fact * pulse_fact / (t_rep * exp(t_rep * rate));

   auto& t = dp->getTimepoints();
   
   for (int k = 0; k<n_chan; k++)
   {
      for (int i = 0; i<n_t; i++)
      {
         convolveDerivative(t[i], k, i, pulse_fact, pulse_fact_der, ref_fact_a, ref_fact_b, c);
         b[i + k*n_t] += model_decay[i] * c * fact * channel_factors[k];
      }
   }
}


void MeasuredIrfConvolver::calculateIRFMax()
{
   irf_max.assign(dp->n_meas, 0);
   auto t = dp->getTimepoints();
   
   double t0 = irf->getT0();
   double dt_irf = irf->timebin_width;
   int n_irf = irf->n_irf;
   
   for (int j = 0; j<n_chan; j++)
   {
      for (int i = 0; i<n_t; i++)
      {
         int k = 0;
         while (k < n_irf && (t[i] - t0 - k*dt_irf) >= -1.0)
         {
            irf_max[j*n_t + i] = k;
            k++;
         }
      }
   }
   
}

