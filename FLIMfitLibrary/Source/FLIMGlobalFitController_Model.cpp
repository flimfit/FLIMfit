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

#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"

#include <xmmintrin.h>
#include <algorithm>
#include <boost/math/special_functions/fpclassify.hpp>

#include <cfloat>

using std::min;
using std::max;

int FLIMGlobalFitController::check_alf_mod(int thread, const double* new_alf, int irf_idx)
{
   double *cur_alf = this->cur_alf + thread * nl;
   int* cur_irf_idx = this->cur_irf_idx + thread;

   if (nl == 0 || fit_t0 == FIT)
      return true;
   

   if ((image_irf || t0_image != NULL) && (irf_idx != *cur_irf_idx || *cur_irf_idx == -1))
   {
      *cur_irf_idx = irf_idx;
      return true;
   }

   if ( data->image_t0_shift && (irf_idx / data->n_px != *cur_irf_idx / data->n_px || *cur_irf_idx == -1))
   {
      *cur_irf_idx = irf_idx;
      return true;
   }


   bool changed = false;
   for(int i=0; i<nl; i++)
   {
      changed = changed | (std::abs((cur_alf[i] - new_alf[i])) > DBL_MIN) | boost::math::isnan(cur_alf[i]);
      cur_alf[i] = new_alf[i];
   }

   return changed;
}

void FLIMGlobalFitController::calculate_exponentials(int thread, int irf_idx, double tau[], double theta[], double t0_shift)
{

   double e0, de, ej, cum, fact, inv_theta, rate;
   int i, j, k, m, idx, next_idx, tau_idx;
   __m128d *dest_, *src_, *irf_, *t_irf_;

   double* local_exp_buf = exp_buf + thread * exp_buf_size;
   int row = n_pol_group*n_fret_group*n_exp*N_EXP_BUF_ROWS;
   
   double *lirf = irf_buf; 
   
   int irf_px = irf_idx % data->n_px;
   int irf_im = irf_idx / data->n_px;

   if (data->image_t0_shift)
      t0_shift += data->image_t0_shift[irf_im];

   if (image_irf)
      lirf += irf_px * n_irf * n_chan;
   else if (t0_image)
      t0_shift += t0_image[irf_px];
   
   if (t0_shift != 0)
   {
      lirf = irf_buf + (thread + 1) * n_irf * n_chan;
      ShiftIRF(t0_shift, lirf);
   }

   for(m=n_pol_group-1; m>=0; m--)
   {

      inv_theta = m>0 ? 1/theta[m-1] : 0; 

      for(i=n_fret_group*n_exp-1; i>=0; i--)
      {
         row--;

         tau_idx = i + n_exp * tau_start; 
         rate = 1/tau[tau_idx] + inv_theta;
         
         // IRF exponential factor
         e0 = exp( t_irf[0] * rate ); // * t_g;
         de = exp( + t_g * rate );

         
         __m128d  ej_ = _mm_setr_pd(e0, e0*de);
         __m128d  de_ = _mm_set1_pd(de*de);

         dest_ = (__m128d*) (local_exp_buf + row*exp_dim);
         irf_  = (__m128d*) lirf;

         int n_loop = n_irf/2;

         for(j=0; j<n_loop; j++)
         {
            for(k=0; k<n_chan; k++)
               dest_[k*n_loop] = _mm_mul_pd(irf_[k*n_loop],ej_);
            ej_ = _mm_mul_pd(ej_,de_);
            irf_++;
            dest_++;
         }
         
         
         /*
         ej = e0;
         for(j=0; j<n_irf; j++)
         {
            for(k=0; k<n_chan; k++)
               local_exp_buf[j+k*n_irf+row*exp_dim] = ej * lirf[j+k*n_irf];
            ej *= de;
          }
          */
          
         row--;

         // Cumulative IRF expontial
         for(k=0; k<n_chan; k++)
         {
            next_idx = row*exp_dim + k*n_irf;
            idx = next_idx + exp_dim;
            cum = 0;
            for(j=0; j<n_irf; j++)
            {
               cum += local_exp_buf[idx++];
               local_exp_buf[next_idx++] = cum;
            }
         }

         row--;

         // IRF exponential factor * t_irf
         
         for(k=0; k<n_chan; k++)
         {
            dest_  = (__m128d*) (local_exp_buf + row*exp_dim + k*n_irf);
            src_   = (__m128d*) (local_exp_buf + (row+2)*exp_dim + k*n_irf);
            t_irf_ = (__m128d*) t_irf_buf;

            for(j=0; j<n_loop; j++)
            {
               *(dest_++) = _mm_mul_pd(*(src_++),*(t_irf_++));
            }
         }
         
         /*
         // IRF exponential factor * t_irf
         for(k=0; k<n_chan; k++)
         {
            next_idx = row*exp_dim + k*n_irf;
            idx = next_idx + 2*exp_dim;
            for(j=0; j<n_irf; j++)
            {
               local_exp_buf[next_idx+j] = local_exp_buf[idx+j] * (t_irf[j] + t0_guess);
            }
         }
         */

         row--;

         // Cumulative IRF expontial * t_irf
         
         for(k=0; k<n_chan; k++)
         {
            next_idx = row*exp_dim + k*n_irf;
            idx = next_idx + exp_dim;
            cum = 0;
            for(j=0; j<n_irf; j++)
            {
               cum += local_exp_buf[idx++];
               local_exp_buf[next_idx++] = cum;
            }
         }

         row -= 2; // we're going to put the t0 shift model in first
        
         fact = 1;
      
         if (ref_reconvolution)
            fact *= t_g;
         else
            fact *= 1;


         de = exp( (t[0]-t[1]) * rate );

         if (eq_spaced_data)
         {
            e0 = exp( -t[0] * rate );   
            for(k=0; k<n_chan; k++)
            {
               ej = e0;
               for(j=0; j<n_t; j++)
               {
                  local_exp_buf[j+k*n_t+row*exp_dim] = fact * ej * chan_fact[m*n_chan+k] * data->t_int[j];
                  ej *= de;
               }
            }
         }
         else
         {
            for(k=0; k<n_chan; k++)
            {
               for(j=0; j<n_t; j++)
                  local_exp_buf[j+k*n_t+row*exp_dim] = fact * exp( - t[j] * rate ) * chan_fact[m*n_chan+k] * data->t_int[j];
            }
         }

         // Calculated shifted model functions
         if (fit_t0 == FIT)
         {
            for(k=0; k<n_chan; k++)
            {
               idx = row*exp_dim + k*n_irf;
               next_idx = idx + exp_dim;
               for(j=0; j<n_irf; j++)
               {
                  local_exp_buf[next_idx++] = local_exp_buf[idx++] * de;
               }
            }

            de = 1/de;
            for(k=0; k<n_chan; k++)
            {
               idx = row*exp_dim + k*n_irf;
               next_idx = idx - exp_dim;
               for(j=0; j<n_irf; j++)
               {
                  local_exp_buf[next_idx++] = local_exp_buf[idx++] * de;
               }
            }
         }

         row--;
      }


   }
}


void FLIMGlobalFitController::add_decay(int threadi, int tau_idx, int theta_idx, int fret_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double a[], int bin_shift)
{   
   double c;
   double* local_exp_buf = exp_buf + threadi * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+fret_group_idx)*n_exp);
   
   double* exp_model_buf         = local_exp_buf + (row+1+bin_shift)*exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+5)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+6)*exp_dim;
            
   int fret_tau_idx = tau_idx + (fret_group_idx+tau_start)*n_exp;

   double rate = 1/tau[fret_tau_idx] + ((theta_idx==0) ? 0 : 1/theta[theta_idx-1]);

   int* resample_idx = data->GetResampleIdx(threadi);
   
   

   fact *= (ref_reconvolution && ref_lifetime > 0) ? (1/ref_lifetime - rate) : 1;

   double pulse_fact = (t_rep * rate > 36) ? 4e15 : exp(t_rep * rate) - 1; // crudely make sure we keep in double range

   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         
         Convolve(this, rate, exp_irf_buf, exp_irf_cum_buf, k, i, pulse_fact, bin_shift, c);
         a[idx] += exp_model_buf[k*n_t+i] * c * fact;
         idx += resample_idx[i];
      }
      idx++;
   }
}

void FLIMGlobalFitController::add_derivative(int thread, int tau_idx, int theta_idx, int fret_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double b[])
{   
   double c;
   double* local_exp_buf = exp_buf + thread * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+fret_group_idx)*n_exp);

   double* exp_model_buf         = local_exp_buf + (row+1)*exp_dim;
   double* exp_irf_tirf_cum_buf  = local_exp_buf + (row+3)*exp_dim;
   double* exp_irf_tirf_buf      = local_exp_buf + (row+4)*exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+5)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+6)*exp_dim;
   
   int* resample_idx = data->GetResampleIdx(thread);
   
   int fret_tau_idx = tau_idx + (fret_group_idx+tau_start)*n_exp;
           
   double rate = 1/tau[fret_tau_idx] + ((theta_idx==0) ? 0 : 1/theta[theta_idx-1]);

   double ref_fact_a = (ref_reconvolution && ref_lifetime > 0) ? (1/ref_lifetime - rate) : 1;
   double ref_fact_b = (ref_reconvolution && ref_lifetime > 0) ? 1 : 0;

   double pulse_fact = (t_rep * rate > 36) ? 4e15 : exp(t_rep * rate) - 1; // make sure we keep in double range
   double pulse_fact_der = (pulse_fact / (t_rep * (pulse_fact+1))) * pulse_fact; // order this way to prevent overflow 


   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         ConvolveDerivative(this, t[i], rate, exp_irf_buf, exp_irf_cum_buf, exp_irf_tirf_buf, exp_irf_tirf_cum_buf, k, i, pulse_fact, pulse_fact_der, ref_fact_a, ref_fact_b, c);
         b[idx] += exp_model_buf[k*n_t+i] * c * fact;
         idx += resample_idx[i];
      }
      idx++;
   }
}


int FLIMGlobalFitController::flim_model(int thread, int irf_idx, double tau[], double beta[], double theta[], double ref_lifetime, double t0_shift, bool include_fixed, int bin_shift, double a[], int adim)
{
   int n_meas_res = data->GetResampleNumMeas(thread);

   // Total number of columns 
   int n_col = n_fret_group * n_pol_group * n_exp_phi;

   if (bin_shift != 1) // otherwise we're doing numerical derivatives for t0 and want to add
      memset(a, 0, adim*n_col*sizeof(double));


   int idx = 0;
   for(int p=0; p<n_pol_group; p++)
   {
      for(int g=0; g<n_fret_group; g++)
      {
         int cur_decay_group = 0;
         for(int j=0; j<n_exp; j++)
         {
            if (beta_global && decay_group_buf[j] > cur_decay_group)
            {
               idx += adim;
               cur_decay_group++;

               if (ref_reconvolution)
                  add_irf(thread, irf_idx, t0_shift, a+idx, p);
            }

            // If we're doing delta-function reconvolution add contribution from reference
            // -> but only add once if beta is global (i.e. if we add up all the decays)
            if (ref_reconvolution && (!beta_global || j==0))
               add_irf(thread, irf_idx, t0_shift, a+idx, p);

            double fact = beta_global ? beta[j] : 1;

            add_decay(thread, j, p, g, tau, theta, fact, ref_lifetime, a+idx, bin_shift);

            if (!beta_global)
               idx += adim;
         }

         if (beta_global)
            idx += adim;
      }
   }

   return n_col;
}

int FLIMGlobalFitController::ref_lifetime_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);

   double fact;
  
   int n_col = n_pol_group * (beta_global ? 1 : n_exp);
   for(int i=0; i<n_col; i++)
      memset(b+i*ndim, 0, n_meas_res*sizeof(*b)); 

   for(int p=0; p<n_pol_group; p++)
   {
      for(int g=0; g<n_fret_group; g++)
      {
         int idx = (g+p*n_fret_group)*n_meas_res;
         int cur_decay_group = 0;

         for(int j=0; j<n_exp ; j++)
         {
            if (beta_global && decay_group_buf[j] > cur_decay_group)
            {
               idx += ndim;
               cur_decay_group++;
            }

            fact  = - 1 / (ref_lifetime * ref_lifetime);
            fact *= beta_global ? beta[j] : 1;

            add_decay(thread, j, p, g, tau, theta, fact, 0, b+idx);

            if (!beta_global)
               idx += ndim;
         }
      }
   }

   return n_col;
}


int FLIMGlobalFitController::t0_derivatives(int thread, int irf_idx, double tau[], double beta[], double theta[], double ref_lifetime, double t0_shift, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);

   // Total number of columns 
   int n_col = n_fret_group * n_pol_group * n_exp_phi;

   
   flim_model(thread, irf_idx, tau, beta, theta, ref_lifetime, t0_shift, false, -1, b, ndim);

   for(int i=0; i<n_meas_res*n_col; i++)
      b[i] *= -1;
   
   flim_model(thread, irf_idx, tau, beta, theta, ref_lifetime, t0_shift, false, 1, b, ndim);

   double idt = 0.5/(t_irf[1]-t_irf[0]);
   for(int i=0; i<n_meas_res*n_col; i++)
      b[i] *= idt;

      return n_col;
}

int FLIMGlobalFitController::tau_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);

   double fact;

   int col = 0;
   int idx = 0;

   
   for(int j=n_fix; j<n_exp; j++)
   {
      // d(donor)/d(tau)
      if (inc_donor)
      {
         for(int p=0; p<n_pol_group; p++)
         {
            memset(b+idx, 0, n_meas_res*sizeof(*b));

            fact  = 1 / (tau[j] * tau[j]) * TransformRangeDerivative(tau[j],tau_min[j],tau_max[j]);
            fact *= beta_global ? beta[j] : 1;

            add_derivative(thread, j, p, 0, tau, theta, fact, ref_lifetime, b+idx);

            col++;
            idx += ndim;
         }
      }

      // d(fret)/d(tau)
      for(int i=0; i<n_fret; i++)
      {
         int g = i + inc_donor;
         double fret_tau = tau[j + n_exp * (i+1)];
         
         memset(b+idx, 0, n_meas_res*sizeof(*b));
      
         fact = beta[j] / (fret_tau * tau[j]) * TransformRangeDerivative(tau[j],tau_min[j],tau_max[j]);
         
         add_derivative(thread, j, 0, g, tau, theta, fact, ref_lifetime, b+idx);

         col++;
         idx += ndim;
      }
   }

   return col;

}

int FLIMGlobalFitController::beta_derivatives(int thread, double tau[], const double alf[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);
   
   double fact;
  
   int col = 0;
   int idx = 0;
   int d_idx = 0;

   int group_start = 0;
   int group_end   = 0;

   for(int d=0; d<n_decay_group; d++)
   {
      int n_group = 0;
      while(d_idx < n_exp && decay_group_buf[d_idx]==d)
      {
         d_idx++;
         n_group++;
         group_end++;
      }


      for(int j=group_start; j<group_end-1; j++)
         for(int p=0; p<n_pol_group; p++)
            for(int g=0; g<n_fret_group; g++)
            {
               memset(b+idx, 0, n_meas_res*sizeof(*b)); 

               for(int k=j; k<group_end; k++)
               {
                  fact = beta_derv(n_group, j-group_start, k-group_start, alf);
                  add_decay(thread, k, p, g, tau, theta, fact, ref_lifetime, b+idx);
               }

               idx += ndim;
               col++;
            }

      group_start = group_end;
   }
   return col;
}

int FLIMGlobalFitController::theta_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);
   
   double fact;

   int col = 0;
   int idx = 0;

   for(int p=n_theta_fix; p<n_theta; p++)
   {
      memset(b+idx, 0, n_meas_res*sizeof(*b));

      for(int j=0; j<n_exp; j++)
      {      
         fact  = beta[j] / theta[p] / theta[p] * TransformRangeDerivative(theta[p],0,1000000);
         add_derivative(thread, j, p+1, 0, tau, theta, fact, ref_lifetime, b+idx);
      }

      idx += ndim;
      col++;
   }

   return col;

}

int FLIMGlobalFitController::E_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);
   
   double fact, E, Ej, dE;
   
   int col = 0;
   int idx = 0;

   for(int i=0; i<n_fret_v; i++)
   {
      int g = i + n_fret_fix + inc_donor;

      memset(b+idx, 0, n_meas_res*sizeof(*b));
      double* fret_tau = tau + n_exp * (g+tau_start);
      
      for(int j=0; j<n_exp; j++)
      {
         E  = 1-fret_tau[0]/tau[0];
         Ej = 1-fret_tau[j]/tau[j];
        
         dE = Ej/E;
         dE *= dE;
         dE *= tau[0]/tau[j];
                 
          
         fact  = - beta[j] * tau[j] / (fret_tau[j] * fret_tau[j]) * dE;
         add_derivative(thread, j, 0, g, tau, theta, fact, ref_lifetime, b+idx);
      }

      col++;
      idx += ndim;

   }
   

   return col;

}


// http://paulbourke.net/miscellaneous/interpolation/
double CubicInterpolate(double  y[], double mu)
{
   // mu - distance between y1 and y2
   double a0,a1,a2,a3,mu2;

   mu2 = mu*mu;
   a0 = -0.5*y[0] + 1.5*y[1] - 1.5*y[2] + 0.5*y[3];
   a1 = y[0] - 2.5*y[1] + 2*y[2] - 0.5*y[3];
   a2 = -0.5*y[0] + 0.5*y[2];
   a3 = y[1];

   return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}


void FLIMGlobalFitController::ShiftIRF(double shift, double s_irf[])
{
   int i;

   shift /= t_g;

   int c_shift = (int) floor(shift); 
   double f_shift = shift-c_shift;

   int start = max(0,1-c_shift);
   int end   = min(n_irf,n_irf-c_shift-3);

   start = min(start, n_irf-1);
   end   = max(end, 0);



   for(i=0; i<start; i++)
       s_irf[i] = irf_buf[0];


   for(i=start; i<end; i++)
   {
      // will read y[0]...y[3]
      _ASSERT(i+c_shift-1 < (n_irf-3));
      _ASSERT(i+c_shift-1 >= 0);
      s_irf[i] = CubicInterpolate(irf_buf+i+c_shift-1,f_shift);
   }

   for(i=end; i<n_irf; i++)
      s_irf[i] = irf_buf[n_irf-1];

}