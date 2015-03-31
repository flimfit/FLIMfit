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


#include "ExponentialPrecomputationBuffer.h"
#include <iostream>

ExponentialPrecomputationBuffer::ExponentialPrecomputationBuffer(shared_ptr<AcquisitionParameters> acquisition_params) :
acquisition_params(acquisition_params),
irf(acquisition_params->irf),
n_irf(irf->n_irf),
n_t(acquisition_params->n_t),
n_chan(acquisition_params->n_chan)
{
   irf_exp_factor.resize(n_chan, aligned_vector<double>(n_irf));
   cum_irf_exp_factor.resize(n_chan, aligned_vector<double>(n_irf));
   irf_exp_t_factor.resize(n_chan, aligned_vector<double>(n_irf));
   cum_irf_exp_t_factor.resize(n_chan, aligned_vector<double>(n_irf));
   irf_exp_factor.resize(n_chan, aligned_vector<double>(n_t));
   model_decay.resize(n_chan, aligned_vector<double>(n_t));
   shifted_model_decay_high.resize(n_chan, aligned_vector<double>(n_t));
   shifted_model_decay_low.resize(n_chan, aligned_vector<double>(n_t));

   irf_working.resize(n_irf * n_chan);
};

void ExponentialPrecomputationBuffer::Compute(double rate_, int irf_idx, double t0_shift, const vector<double>& channel_factors, bool compute_shifted_models)
{
   // Don't compute if rate is the same
   if (rate_ == rate)
      return;
   
   rate = rate_;

   std::cout << "Tau: " << 1 / rate << "\n";

   ComputeIRFFactors(rate, irf_idx, t0_shift);
   ComputeModelFactors(rate, channel_factors, compute_shifted_models);
}

void ExponentialPrecomputationBuffer::ComputeIRFFactors(double rate, int irf_idx, double t0_shift)
{
   double* lirf = irf->GetIRF(irf_idx, t0_shift, irf_working.data()); // TODO: add image irf shifting to GetIRF
   double t0 = irf->GetT0();
   double dt_irf = irf->timebin_width;

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
      __m128d* irf_ = (__m128d*) (lirf + k*n_irf);

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
   __m128d dt_irf_ = _mm_set1_pd(dt_irf);
   __m128d t_irf_ = _mm_setr_pd(t0, t0 + dt_irf);

   for (int k = 0; k < n_chan; k++)
   {
      __m128d* dest_ = (__m128d*) irf_exp_t_factor[k].data();
      __m128d* src_ = (__m128d*) irf_exp_factor[k].data();

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

void ExponentialPrecomputationBuffer::ComputeModelFactors(double rate, const vector<double>& channel_factors, bool compute_shifted_models)
{
   double fact = 1;

   if (irf->type == Reference)
      fact *= irf->timebin_width;

   double* t = acquisition_params->GetT();

   double de = exp((t[0] - t[1]) * rate);

   if (acquisition_params->equally_spaced_gates)
   {
      double e0 = exp(-t[0] * rate);
      for (int k = 0; k < n_chan; k++)
      {
         double ej = e0 * channel_factors[k];
         for (int j = 0; j < n_t; j++)
         {
            model_decay[k][j] = fact * ej * acquisition_params->t_int[j];
            ej *= de;
         }
      }
   }
   else
   {
      for (int k = 0; k < n_chan; k++)
         for (int j = 0; j < n_t; j++)
            model_decay[k][j] = fact * exp(-t[j] * rate) * channel_factors[k] * acquisition_params->t_int[j];
   }

   // Calculated shifted model functions
   if (compute_shifted_models)
   {
      double inv_de = 1 / de;
      for (int k = 0; k < n_chan; k++)
      {
         for (int j = 0; j < n_irf; j++)
         {
            shifted_model_decay_high[k][j] = model_decay[k][j] * de;
            shifted_model_decay_high[k][j] = model_decay[k][j] * inv_de;
         }
      }
   }
}




void ExponentialPrecomputationBuffer::Convolve(int k, int i, double pulse_fact, int bin_shift, double& c) const
{
   const auto& exp_irf_cum_buf = cum_irf_exp_factor[k];
   const auto& exp_irf_buf = irf_exp_factor[k];

   int j = k*n_t + i;
   int idx = acquisition_params->irf_max[j] + bin_shift;

   idx = idx < 0 ? 0 : idx;
   idx = idx >= n_irf ? n_irf - 1 : idx;

   c = exp_irf_cum_buf[idx] - 0.5*exp_irf_buf[idx];

   if (pulse_fact > 0)
      c += (exp_irf_cum_buf[n_irf - 1] - 0.5*exp_irf_buf[n_irf - 1]) / pulse_fact;
}



void ExponentialPrecomputationBuffer::ConvolveDerivative(double t, int k, int i, double pulse_fact, double ref_fact_a, double ref_fact_b, double& c) const
{
   const auto& exp_model_buf = model_decay[k];
   const auto& exp_irf_tirf_cum_buf = cum_irf_exp_t_factor[k];
   const auto& exp_irf_tirf_buf = irf_exp_t_factor[k];
   const auto& exp_irf_cum_buf = cum_irf_exp_factor[k];
   const auto& exp_irf_buf = irf_exp_factor[k];

   double c_rep;

   int idx = acquisition_params->irf_max[k*n_t + i];
   int irf_end = n_irf - 1;

   c = (t * ref_fact_a + ref_fact_b) * exp_irf_cum_buf[idx] - exp_irf_tirf_cum_buf[idx] * ref_fact_a;
   c -= 0.5 * ((t * ref_fact_a + ref_fact_b) * exp_irf_buf[idx] - exp_irf_tirf_buf[idx] * ref_fact_a);


   if (pulse_fact > 0)
   {
      double t_rep = acquisition_params->t_rep;

      c_rep = ((t + t_rep) * ref_fact_a + ref_fact_b) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact_a;
      c_rep -= 0.5 * (((t + t_rep) * ref_fact_a + ref_fact_b) * exp_irf_buf[irf_end] - exp_irf_tirf_buf[irf_end] * ref_fact_a);
      c_rep /= pulse_fact;
      c += c_rep;
   }
}



void ExponentialPrecomputationBuffer::AddDecay(double fact, double ref_lifetime, double a[], int bin_shift) const
{
   double c;

   fact *= (irf->type == Reference && ref_lifetime > 0) ? (1 / ref_lifetime - rate) : 1;

   double pulse_fact;

   const double x_max = -log(DBL_EPSILON);
   if (acquisition_params->t_rep * rate > x_max)
      pulse_fact = 0;
   else
      pulse_fact = exp(acquisition_params->t_rep * rate) - 1;

   int idx = 0;
   for (int k = 0; k<n_chan; k++)
   {
      for (int i = 0; i<n_t; i++)
      {
         Convolve(k, i, pulse_fact, bin_shift, c);

         int mi = i + 1 + bin_shift; // TODO: 1 is correct here?

         mi = mi < 0 ? 0 : mi;
         mi = mi >= n_irf ? n_irf - 1 : mi;


         a[idx] += model_decay[k][mi] * c * fact;
         idx++;
      }
   }
}

void ExponentialPrecomputationBuffer::AddDerivative(double fact, double ref_lifetime, double b[]) const
{
   double c;

   double ref_fact_a = (irf->type == Reference && ref_lifetime > 0) ? (1 / ref_lifetime - rate) : 1;
   double ref_fact_b = (irf->type == Reference && ref_lifetime > 0) ? 1 : 0;
   double pulse_fact = exp(acquisition_params->t_rep * rate) - 1;

   int idx = 0;
   for (int k = 0; k<n_chan; k++)
   {
      for (int i = 0; i<n_t; i++)
      {
         ConvolveDerivative(acquisition_params->t[i], k, i, pulse_fact, ref_fact_a, ref_fact_b, c);
         b[idx] += model_decay[k][i] * c * fact;
         idx++;
      }
   }
}

