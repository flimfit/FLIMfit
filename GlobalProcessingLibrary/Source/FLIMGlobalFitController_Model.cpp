#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"
#include <xmmintrin.h>

int FLIMGlobalFitController::check_alf_mod(int thread, double* new_alf)
{
   double *cur_alf = this->cur_alf + thread * nl;

   if (nl == 0)
      return true;

   int changed = false;

   for(int i=0; i<nl; i++)
   {
      changed = changed | (cur_alf[i] != new_alf[i]);
      cur_alf[i] = new_alf[i];
   }

   return changed;
}

void FLIMGlobalFitController::calculate_exponentials(int thread, double tau[], double theta[])
{

   double e0, de, ej, cum, fact, inv_theta, rate;
   int i, j, k, m, idx, next_idx;
   __m128d *dest_, *src_, *irf_, *t_irf_;

   double* local_exp_buf = exp_buf + thread * n_decay_group * exp_buf_size;
   int row = n_pol_group*n_decay_group*n_exp*N_EXP_BUF_ROWS;
   
   double *lirf;
   
   if (image_irf)
      lirf = local_irf[thread];
   else
      lirf = irf_buf;

   for(m=n_pol_group-1; m>=0; m--)
   {

      inv_theta = m>0 ? 1/theta[m-1] : 0; 

      for(i=n_decay_group*n_exp-1; i>=0; i--)
      {
         row--;

         rate = 1/tau[i] + inv_theta;
         
         // IRF exponential factor
         e0 = exp( (t_irf[0] + t0_guess) * rate ); // * t_g;
         de = exp( + t_g * rate );

         
         __m128d  ej_ = _mm_setr_pd(e0, e0*de);
         __m128d  de_ = _mm_set1_pd(de*de);

         dest_ = (__m128d*) (local_exp_buf + row*exp_dim);
         irf_  = (__m128d*) lirf;

         int n_loop = n_irf/2;

         for(j=0; j<n_loop; j++)
         {
            for(k=0; k<n_chan; k++)
               dest_[k*n_irf/2] = _mm_mul_pd(irf_[k*n_irf/2],ej_);
            ej_ = _mm_mul_pd(ej_,de_);
            irf_++;
            dest_++;
         }
         
         
         /*
         ej = e0;
          

         for(j=0; j<n_irf; j++)
         {
            for(k=0; k<n_chan; k++)
            {
               local_exp_buf[j+k*n_irf+row*exp_dim] = ej * lirf[j+k*n_irf];
            }
            ej *= de;
          }
          */
          
         row--;

         // Cumulative IRF expontial
         for(k=0; k<n_chan; k++)
         {
            next_idx = row*exp_dim + k*n_irf;
            idx = next_idx + exp_dim;
            cum = local_exp_buf[idx++];
            for(j=0; j<n_irf; j++)
            {
               local_exp_buf[next_idx++] = cum;
               cum += local_exp_buf[idx++];
            }
         }

         row--;

         __m128d t0_ = _mm_set1_pd(t0_guess);

         // IRF exponential factor * t_irf
         
         for(k=0; k<n_chan; k++)
         {
            dest_  = (__m128d*) (local_exp_buf + row*exp_dim + k*n_irf);
            src_   = (__m128d*) (local_exp_buf + (row+2)*exp_dim + k*n_irf);
            t_irf_ = (__m128d*) t_irf_buf;

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
            cum = local_exp_buf[idx++];
            for(j=0; j<n_irf; j++)
            {
               local_exp_buf[next_idx++] = cum;
               cum += local_exp_buf[idx++];
            }
         }

         row--;
        
         double tg = t[1] - t[0];

         // Actual decay
         //if (data->data_type == DATA_TYPE_TCSPC && !ref_reconvolution)
         //   fact = ( 1 - exp( - tg * rate ) ) / rate;
         //else
              fact = 1;
      
         if (ref_reconvolution)
            fact *= t_g;
         else
            fact *= 1;

         for(k=0; k<n_chan; k++)
         {
            for(j=0; j<n_t; j++)
               local_exp_buf[j+k*n_t+row*exp_dim] = fact * exp( - t[j] * rate ) * chan_fact[m*n_chan+k] * data->t_int[j];
         }

      }
   }
}


void FLIMGlobalFitController::add_decay(int thread, int tau_idx, int theta_idx, int decay_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double a[])
{   
   double c;
   double* local_exp_buf = exp_buf + thread * n_decay_group * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+decay_group_idx)*n_exp);
   
   double* exp_model_buf         = local_exp_buf +  row   *exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+3)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+4)*exp_dim;
            
   int fret_tau_idx = tau_idx + decay_group_idx*n_exp;

   double rate = 1/tau[fret_tau_idx] + ((theta_idx==0) ? 0 : 1/theta[theta_idx-1]);

   int* resample_idx = data->GetResampleIdx(thread);

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
         idx += resample_idx[i];
      }
      idx++;
   }
}

void FLIMGlobalFitController::add_derivative(int thread, int tau_idx, int theta_idx, int decay_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double b[])
{   
   double c;
   double* local_exp_buf = exp_buf + thread * n_decay_group * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+decay_group_idx)*n_exp);

   double* exp_model_buf         = local_exp_buf + (row+0)*exp_dim;
   double* exp_irf_tirf_cum_buf  = local_exp_buf + (row+1)*exp_dim;
   double* exp_irf_tirf_buf      = local_exp_buf + (row+2)*exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+3)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+4)*exp_dim;
   
   int* resample_idx = data->GetResampleIdx(thread);
   
  int fret_tau_idx = tau_idx + decay_group_idx*n_exp;
           
   double rate = 1/tau[fret_tau_idx] + ((theta_idx==0) ? 0 : 1/theta[theta_idx-1]);

   double ref_fact = (ref_reconvolution && ref_lifetime > 0) ? (1/ref_lifetime - rate) : 1;
   double pulse_fact = exp( t_rep * rate ) - 1; 

   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         ConvolveDerivative(this, t[i], rate, exp_irf_buf, exp_irf_cum_buf, exp_irf_tirf_buf, exp_irf_tirf_cum_buf, k, i, pulse_fact, ref_fact, c);
         b[idx] += exp_model_buf[k*n_t+i] * c * fact;
         idx += resample_idx[i];
      }
      idx++;
   }
}

void FLIMGlobalFitController::add_irf(int thread, double a[],int pol_group, double* scale_fact)
{
   int* resample_idx = data->GetResampleIdx(thread);

   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[k];
      for(int i=0; i<n_t; i++)
      {
         a[idx] += resampled_irf[k*n_t+i] * chan_fact[pol_group*n_chan+k] * scale;
         idx += resample_idx[i];
      }
      idx++;
   }
}

int FLIMGlobalFitController::flim_model(int thread, double tau[], double beta[], double theta[], double ref_lifetime, bool include_fixed, double a[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);

   double fact;
  
   int j_start = (include_fixed || beta_global) ? 0 : n_fix;

   int g_start = 0;
   if (fit_fret && !include_fixed && n_fix == n_exp && fit_beta!=FIT_GLOBALLY)
      g_start = n_fret_fix + (inc_donor ? 1 : 0);

   int p_start = 0;
   if (polarisation_resolved && !include_fixed && n_fix == n_exp && fit_beta!=FIT_GLOBALLY)
      p_start = 1 + n_theta_fix;

   int n_col = n_decay_group * n_pol_group * (beta_global ? 1 : n_exp);

   int idx = p_start * n_meas_res;

   for(int p=p_start; p<n_pol_group; p++)
   {
      idx += g_start * n_meas_res;

      for(int g=g_start; g<n_decay_group; g++)
      {
         idx += j_start * n_meas_res;

         for(int j=j_start; j<n_exp ; j++)
         {
            if (j==j_start || !beta_global)
               memset(a+idx, 0, n_meas_res*sizeof(*a)); 

            if (ref_reconvolution && (!beta_global || j==0))
               add_irf(thread, a+idx, p);

            fact = beta_global       ? beta[j]    : 1;

            add_decay(thread, j, p, g, tau, theta, fact, ref_lifetime, a+idx);

            if (!beta_global)
               idx += n_meas_res;
         }

         if (beta_global)
            idx += n_meas_res;
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
      for(int g=0; g<n_decay_group; g++)
      {
         int idx = (g+p*n_decay_group)*n_meas_res;   

         for(int j=0; j<n_exp ; j++)
         {
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

int FLIMGlobalFitController::FMM_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
/*
   int j;
   double fact;
   double t_m = aux_tau[thread];

   int idx = 0;
   int col = 0;

   double f = 1/(beta[1]*(t_m-2*tau[1])); //1 / sqrt( beta[1] * ( 4*beta[0]*tau[0]*(t_m-tau[0]) + beta[1]*t_m*t_m ) );

   memset(b+idx, 0, n_meas*sizeof(double));

   j = 0;
   fact  = beta[j] / (tau[j] * tau[j]) * d_tau_d_alf(tau[j],tau_min[j],tau_max[j]);
   add_derivative(thread, j, 0, 0, tau, theta, fact, ref_lifetime, b+idx);

   j=1;
   fact  = beta[j] / (tau[j] * tau[j]) * d_tau_d_alf(tau[j],tau_min[j],tau_max[j]);
   fact *= (2*tau[0]*beta[0]-t_m*beta[0])*f; //- beta[0] * ( t_m - 2*tau[0] ) * f;
   add_derivative(thread, j, 0, 0, tau, theta, fact, ref_lifetime, b+idx);

   col++;
   idx += ndim;

   memset(b+idx, 0, n_meas*sizeof(double)); 

   j = 0;
   fact = 1;
   add_decay(thread, j, 0, 0, tau, theta, fact, ref_lifetime, b+idx);

   j = 1;
   fact = -1;
   add_decay(thread, j, 0, 0, tau, theta, fact, ref_lifetime, b+idx);

   //fact  = (aux_tau[thread] - tau[0]) / (1 - beta[0]) / (tau[j] * tau[j]) * d_tau_d_alf(tau[j],tau_min[j],tau_max[j]);
   fact  = beta[j] / (tau[j] * tau[j]) * d_tau_d_alf(tau[j],tau_min[j],tau_max[j]);
   fact *= ((tau[0]*tau[0]-tau[1]*tau[1]-(tau[0]-tau[1])*t_m)) * f; //- tau[0] * (t_m - tau[0]) / beta[1] * f;
   add_derivative(thread, j, 0, 0, tau, theta, fact, ref_lifetime, b+idx);

   idx += ndim;
   col++;

   return col;
   */
   return 0;
}

int FLIMGlobalFitController::tau_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);

   double fact;

   int col = 0;
   int idx = 0;

   // d(donor)/d(tau)
   for(int j=n_fix; j<n_exp; j++)
   {
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

      for(int i=0; i<n_fret; i++)
      {
         int g = i + (inc_donor ? 1 : 0);
         double fret_tau = tau[j + n_exp * (1 + i)];
         
         memset(b+idx, 0, n_meas_res*sizeof(*b));
      
         fact = beta[j] / (fret_tau * tau[j]) * TransformRangeDerivative(tau[j],tau_min[j],tau_max[j]);
         
         add_derivative(thread, j, 0, g, tau, theta, fact, ref_lifetime, b+idx);

         col++;
         idx += ndim;
      }
   }

   return col;

}

int FLIMGlobalFitController::beta_derivatives(int thread, double tau[], double alf[], double theta[], double ref_lifetime, double b[])
{
   int n_meas_res = data->GetResampleNumMeas(thread);
   
   double fact;
  
   int col = 0;
   int idx = 0;

   for(int j=0; j<n_exp-1; j++)
   {
      for(int p=0; p<n_pol_group; p++)
      {
         for(int g=0; g<n_decay_group; g++)
         {
            memset(b+idx, 0, n_meas_res*sizeof(*b)); 

            for(int k=j; k<n_exp; k++)
            {
               fact = beta_derv(n_exp, j, k, alf);
               add_decay(thread, k, p, g, tau, theta, fact, ref_lifetime, b+idx);
            }

            idx += ndim;
            col++;
         }
      }
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
   
   double fact;
   
   int col = 0;
   int idx = 0;

   for(int i=0; i<n_fret_v; i++)
   {
      int g = i + n_fret_fix + (inc_donor ? 1 : 0);

      memset(b+idx, 0, n_meas_res*sizeof(*b));
      double* fret_tau = tau + n_exp * (1 + i + n_fret_fix);
      
      for(int j=0; j<n_exp; j++)
      {
         fact  = - beta[j] * tau[j] / (fret_tau[j] * fret_tau[j]);
         add_derivative(thread, j, 0, g, tau, theta, fact, ref_lifetime, b+idx);
      }

      col++;
      idx += ndim;

   }
   

   return col;

}