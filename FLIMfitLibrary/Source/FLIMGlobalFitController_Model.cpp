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

#include "DecayModel.h"
#include "IRFConvolution.h"
#include "ModelADA.h"

#include <xmmintrin.h>
#include <cfloat>
#include <cmath>
#include <algorithm>

#include <string.h>

//using namespace std;

int DecayModel::check_alf_mod(Buffers& wb, const double* new_alf, int irf_idx)
{
   if (nl == 0)
      return true;

   if (irf.variable_irf && irf_idx != wb.cur_irf_idx)
   {
      wb.cur_irf_idx = irf_idx;
      return true;
   }

   int changed = false;
   for(int i=0; i<nl; i++)
   {
      changed = changed | (abs((wb.cur_alf[i] - new_alf[i])) > DBL_MIN);
      wb.cur_alf[i] = new_alf[i];
   }

   return changed;
}

void DecayModel::calculate_exponentials(Buffers& wb, int irf_idx)
{

   double e0, de, ej, cum, fact, inv_theta, rate;
   int i, j, k, m, idx, next_idx, tau_idx;
   __m128d *dest_, *src_, *irf_, *t_irf_;

   int row = n_pol_group*n_fret_group*n_exp*N_EXP_BUF_ROWS;
   

   double* lirf = irf.GetIRF(irf_idx, wb.irf_buf);

   for(m=n_pol_group-1; m>=0; m--)
   {

      inv_theta = m>0 ? 1/wb.theta_buf[m-1] : 0; 

      for(i=n_fret_group*n_exp-1; i>=0; i--)
      {
         row--;

         tau_idx = i + n_exp * tau_start; 
         rate = 1/wb.tau_buf[tau_idx] + inv_theta;
         
         // IRF exponential factor
         e0 = exp( (irf.t_irf_buf[0] + t0_guess) * rate ); // * t_g;
         de = exp( + irf.timebin_width * rate );

         
         __m128d  ej_ = _mm_setr_pd(e0, e0*de);
         __m128d  de_ = _mm_set1_pd(de*de);

         dest_ = (__m128d*) (wb.exp_buf + row*exp_dim);
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
            cum = wb.exp_buf[idx++];
            for(j=0; j<n_irf; j++)
            {
               wb.exp_buf[next_idx++] = cum;
               cum += wb.exp_buf[idx++];
            }
         }

         row--;

         __m128d t0_ = _mm_set1_pd(t0_guess);

         // IRF exponential factor * t_irf
         
         for(k=0; k<n_chan; k++)
         {
            dest_  = (__m128d*) (wb.exp_buf + row*exp_dim + k*n_irf);
            src_   = (__m128d*) (wb.exp_buf + (row+2)*exp_dim + k*n_irf);
            t_irf_ = (__m128d*) irf.t_irf_buf;

            for(j=0; j<n_loop; j++)
            {
               __m128d t_ = _mm_add_pd(*(t_irf_++), t0_);
               *(dest_++) = _mm_mul_pd(*(src_++),t_);
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
            cum = wb.exp_buf[idx++];
            for(j=0; j<n_irf; j++)
            {
               wb.exp_buf[next_idx++] = cum;
               cum += wb.exp_buf[idx++];
            }
         }

         row--;
        
         //double tg = t[1] - t[0];
         // Actual decay
         //if (data->data_type == DATA_TYPE_TCSPC && !ref_reconvolution)
         //   fact = ( 1 - exp( - tg * rate ) ) / rate;
         //else
              fact = 1;
      
         if (ref_reconvolution)
            fact *= irf.timebin_width;
         else
            fact *= 1;

         if (eq_spaced_data)
         {
            e0 = exp( -t[0] * rate );
            de = exp( (t[0]-t[1]) * rate );
            for(k=0; k<n_chan; k++)
            {
               ej = e0;
               for(j=0; j<n_t; j++)
               {
                  wb.exp_buf[j+k*n_t+row*exp_dim] = fact * ej * chan_fact[m*n_chan+k] * t_int[j];
                  ej *= de;
               }
            }
         }
         else
         {
            for(k=0; k<n_chan; k++)
            {
               for(j=0; j<n_t; j++)
                  wb.exp_buf[j+k*n_t+row*exp_dim] = fact * exp( - t[j] * rate ) * chan_fact[m*n_chan+k] * t_int[j];
            }
         }
      }
   }
}


void DecayModel::add_decay(Buffers& wb, int tau_idx, int theta_idx, int fret_group_idx, double fact, double ref_lifetime, double a[])
{   
   double c;
   double* local_exp_buf = wb.exp_buf + n_fret_group * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+fret_group_idx)*n_exp);
   
   double* exp_model_buf         = local_exp_buf +  row   *exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+3)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+4)*exp_dim;
            
   int fret_tau_idx = tau_idx + (fret_group_idx+tau_start)*n_exp;

   double rate = 1/wb.tau_buf[fret_tau_idx] + ((theta_idx==0) ? 0 : 1/wb.theta_buf[theta_idx-1]);
   
   

   fact *= (ref_reconvolution && ref_lifetime > 0) ? (1/ref_lifetime - rate) : 1;

   double pulse_fact;
   
   const double x_max = -log(DBL_EPSILON);
   if (t_rep * rate > x_max)
      pulse_fact = 0;
   else
      pulse_fact = exp( t_rep * rate ) - 1; 


   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         
         Convolve(this, rate, exp_irf_buf, exp_irf_cum_buf, k, i, pulse_fact, c);
         a[idx] += exp_model_buf[k*n_t+i] * c * fact;
         idx++;
      }
   }
}

void DecayModel::add_derivative(Buffers& wb, int tau_idx, int theta_idx, int fret_group_idx, double fact, double ref_lifetime, double b[])
{   
   double c;
   double* local_exp_buf = wb.exp_buf + n_fret_group * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+fret_group_idx)*n_exp);

   double* exp_model_buf         = local_exp_buf + (row+0)*exp_dim;
   double* exp_irf_tirf_cum_buf  = local_exp_buf + (row+1)*exp_dim;
   double* exp_irf_tirf_buf      = local_exp_buf + (row+2)*exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+3)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+4)*exp_dim;
      
   int fret_tau_idx = tau_idx + (fret_group_idx+tau_start)*n_exp;
           
   double rate = 1/wb.tau_buf[fret_tau_idx] + ((theta_idx==0) ? 0 : 1/wb.theta_buf[theta_idx-1]);

   double ref_fact = (ref_reconvolution && ref_lifetime > 0) ? (1/ref_lifetime - rate) : 1;
   double pulse_fact = exp( t_rep * rate ) - 1; 

   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         ConvolveDerivative(this, t[i], rate, exp_irf_buf, exp_irf_cum_buf, exp_irf_tirf_buf, exp_irf_tirf_cum_buf, k, i, pulse_fact, ref_fact, c);
         b[idx] += exp_model_buf[k*n_t+i] * c * fact;
         idx++;
      }
   }
}


int DecayModel::flim_model(Buffers& wb, int irf_idx, double ref_lifetime, bool include_fixed, double a[], int adim)
{

   // Total number of columns 
   int n_col = n_fret_group * n_pol_group * n_exp_phi;

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
                  add_irf(wb.irf_buf, irf_idx, a+idx, p);
            }

            // If we're doing delta-function reconvolution add contribution from reference
            // -> but only add once if beta is global (i.e. if we add up all the decays)
            if (ref_reconvolution && (!beta_global || j==0))
               add_irf(wb.irf_buf, irf_idx, a+idx, p);

            double fact = beta_global ? wb.beta_buf[j] : 1;

            add_decay(wb, j, p, g, fact, ref_lifetime, a+idx);

            if (!beta_global)
               idx += adim;
         }

         if (beta_global)
            idx += adim;
      }
   }

   return n_col;
}

int DecayModel::ref_lifetime_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim)
{
   double fact;
  
   int n_col = n_pol_group * (beta_global ? 1 : n_exp);
   for(int i=0; i<n_col; i++)
      memset(b+i*bdim, 0, bdim*sizeof(*b)); 

   for(int p=0; p<n_pol_group; p++)
   {
      for(int g=0; g<n_fret_group; g++)
      {
         int idx = (g+p*n_fret_group)*bdim;
         int cur_decay_group = 0;

         for(int j=0; j<n_exp ; j++)
         {
            if (beta_global && decay_group_buf[j] > cur_decay_group)
            {
               idx += bdim;
               cur_decay_group++;
            }

            fact  = - 1 / (ref_lifetime * ref_lifetime);
            fact *= beta_global ? wb.beta_buf[j] : 1;

            add_decay(wb, j, p, g, fact, 0, b+idx);

            if (!beta_global)
               idx += bdim;
         }
      }
   }

   return n_col;
}

int DecayModel::tau_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim)
{

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
            memset(b+idx, 0, n_meas*sizeof(*b));

            fact  = 1 / (wb.tau_buf[j] * wb.tau_buf[j]) * TransformRangeDerivative(wb.tau_buf[j],tau_min[j],tau_max[j]);
            fact *= beta_global ? wb.beta_buf[j] : 1;

            add_derivative(wb, j, p, 0, fact, ref_lifetime, b+idx);

            col++;
            idx += bdim;
         }
      }

      // d(fret)/d(tau)
      for(int i=0; i<n_fret; i++)
      {
         int g = i + inc_donor;
         double fret_tau = wb.tau_buf[j + n_exp * (i+1)];
         
         memset(b+idx, 0, n_meas*sizeof(*b));
      
         fact = wb.beta_buf[j] / (fret_tau * wb.tau_buf[j]) * TransformRangeDerivative(wb.tau_buf[j],tau_min[j],tau_max[j]);
         
         add_derivative(wb, j, 0, g, fact, ref_lifetime, b+idx);

         col++;
         idx += bdim;
      }
   }

   return col;

}

int DecayModel::beta_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim)
{
   
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
               memset(b+idx, 0, n_meas*sizeof(*b)); 

               for(int k=j; k<group_end; k++)
               {
                  fact = beta_derv(n_group, j-group_start, k-group_start, wb.beta_buf);
                  add_decay(wb, k, p, g, fact, ref_lifetime, b+idx);
               }

               idx += bdim;
               col++;
            }

      group_start = group_end;
   }
   return col;
}

int DecayModel::theta_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim)
{
   
   double fact;

   int col = 0;
   int idx = 0;

   for(int p=n_theta_fix; p<n_theta; p++)
   {
      memset(b+idx, 0, n_meas*sizeof(*b));

      for(int j=0; j<n_exp; j++)
      {      
         fact  = wb.beta_buf[j] / wb.theta_buf[p] / wb.theta_buf[p] * TransformRangeDerivative(wb.theta_buf[p],0,1000000);
         add_derivative(wb, j, p+1, 0, fact, ref_lifetime, b+idx);
      }

      idx += bdim;
      col++;
   }

   return col;

}

int DecayModel::E_derivatives(Buffers& wb, double ref_lifetime, double b[], int bdim)
{
   
   double fact, E, Ej, dE;
   
   int col = 0;
   int idx = 0;

   for(int i=0; i<n_fret_v; i++)
   {
      int g = i + n_fret_fix + inc_donor;

      memset(b+idx, 0, n_meas*sizeof(*b));
      double* fret_tau = wb.tau_buf + n_exp * (g+tau_start);
      
      for(int j=0; j<n_exp; j++)
      {
         E  = 1-fret_tau[0]/wb.tau_buf[0];
         Ej = 1-fret_tau[j]/wb.tau_buf[j];
        
         dE = Ej/E;
         dE *= dE;
         dE *= wb.tau_buf[0]/wb.tau_buf[j];
                 
          
         fact  = - wb.beta_buf[j] * wb.tau_buf[j] / (fret_tau[j] * fret_tau[j]) * dE;
         add_derivative(wb, j, 0, g, fact, ref_lifetime, b+idx);
      }

      col++;
      idx += bdim;

   }
   

   return col;

}


