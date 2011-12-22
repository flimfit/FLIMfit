#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"





void FLIMGlobalFitController::add_decay(int thread, int tau_idx, int theta_idx, int decay_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double a[])
{   
   double c;
   double* local_exp_buf = exp_buf + thread * n_decay_group * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+decay_group_idx)*n_exp);
   
   double* exp_model_buf         = local_exp_buf +  row   *exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+4)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+5)*exp_dim;
            
   double rate = 1/tau[tau_idx] + ((theta_idx==0) ? 0 : 1/theta[theta_idx-1]);

   fact *= ref_reconvolution ? 1/ref_lifetime - rate : 1;

   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         
         Convolve(this, rate, exp_irf_buf, exp_irf_cum_buf, k, i, c);
         a[idx] += exp_model_buf[idx] * c * fact;
         idx++;
      }
   }
}

void FLIMGlobalFitController::add_derivative(int thread, int tau_idx, int theta_idx, int decay_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double b[])
{   
   double c;
   double* local_exp_buf = exp_buf + thread * n_decay_group * exp_buf_size;
   int row = N_EXP_BUF_ROWS*(tau_idx+(theta_idx+decay_group_idx)*n_exp);

   double* exp_model_buf         = local_exp_buf +  row   *exp_dim;
   double* exp_irf_tirf_cum_buf  = local_exp_buf + (row+2)*exp_dim;
   double* exp_irf_tirf_buf      = local_exp_buf + (row+3)*exp_dim;
   double* exp_irf_cum_buf       = local_exp_buf + (row+4)*exp_dim;
   double* exp_irf_buf           = local_exp_buf + (row+5)*exp_dim;
            
   double rate = 1/tau[tau_idx] + ((theta_idx==0) ? 0 : 1/theta[theta_idx-1]);

   double ref_fact = ref_reconvolution ? (1/ref_lifetime - rate) : 1;

   int idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         ConvolveDerivative(this, t[i], rate, exp_irf_buf, exp_irf_cum_buf, exp_irf_tirf_buf, exp_irf_tirf_cum_buf, k, i, ref_fact, c);
         b[idx] += exp_model_buf[idx] * c * fact;
         idx++;
      }
   }
}

void FLIMGlobalFitController::add_irf(double a[],int pol_group, double* scale_fact)
{
   int idx = 0;
   for(int i=0; i<n_chan; i++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[i];
      for(int j=0; j<n_t; j++)
      {
         a[idx] += resampled_irf[idx] * chan_fact[pol_group*n_chan+i] * scale;
         idx++;
      }
   }
}

int FLIMGlobalFitController::flim_model(int thread, double tau[], double beta[], double theta[], double ref_lifetime, bool include_fixed, double a[])
{
   double fact;
  
   int j_start = (include_fixed || beta_global) ? 0 : n_fix;

   int g_start = 0;
   if (fit_fret && !include_fixed && n_fix == n_exp && fit_beta!=FIT_GLOBALLY)
      g_start = n_fret_fix + (inc_donor ? 1 : 0);

   int p_start = 0;
   if (polarisation_resolved && !include_fixed && n_fix == n_exp && fit_beta!=FIT_GLOBALLY)
      p_start = 1 + n_theta_fix;

   int n_col = n_decay_group * n_pol_group * (beta_global ? 1 : n_exp);

   int idx = p_start * n_meas;

   for(int p=p_start; p<n_pol_group; p++)
   {
      idx += g_start * n_meas;

      for(int g=g_start; g<n_decay_group; g++)
      {
         idx += j_start * n_meas;

         for(int j=j_start; j<n_exp ; j++)
         {
            if (j==j_start || !beta_global)
               memset(a+idx, 0, n_meas*sizeof(double)); 

            if (ref_reconvolution && (!beta_global || j==0))
               add_irf(a+idx, p);

            fact = beta_global       ? beta[j]    : 1;

            add_decay(thread, j, p, g, tau, theta, fact, ref_lifetime, a+idx);

            if (!beta_global)
               idx += n_meas;
         }

         if (beta_global)
            idx += n_meas;
      }
   }

   return n_col;
}

int FLIMGlobalFitController::ref_lifetime_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   double fact;
  
   int n_col = n_pol_group * (beta_global ? 1 : n_exp);
   for(int i=0; i<n_col; i++)
      memset(b, 0, n_meas*sizeof(double)); 

   for(int p=0; p<n_pol_group; p++)
   {
      for(int g=0; g<n_decay_group; g++)
      {
         int idx = (g+p*n_decay_group)*n_meas;   

         for(int j=0; j<n_exp ; j++)
         {
            fact  = - 1 / (ref_lifetime * ref_lifetime);
            fact *= beta_global ? beta[j] : 1;

            add_decay(thread, j, p, g, tau, theta, fact, ref_lifetime, a+idx);

            if (!beta_global)
               idx += n_meas;
         }
      }
   }

   return n_col;
}

int FLIMGlobalFitController::tau_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   double fact;

   int col = 0;
   int idx = 0;

   // d(donor)/d(tau)
   if (inc_donor)
   {
      for(int j=n_fix; j<n_exp; j++)
      {
         for(int p=0; p<n_pol_group; p++)
         {
            memset(b+idx, 0, n_meas*sizeof(double));

            fact  = 1 / (tau[j] * tau[j]) * d_tau_d_alf(tau[j],tau_min[j],tau_max[j]);
            fact *= beta_global ? beta[j] : 1;

            add_derivative(thread, j, p, 0, tau, theta, fact, ref_lifetime, b+idx);

            col++;
            idx += ndim;
         }

         for(int i=0; i<n_fret; i++)
         {
            int g = i + (inc_donor ? 1 : 0);
            double fret_tau = tau[j + n_exp * (1 + i)];
         
            memset(b+idx, 0, n_meas*sizeof(double));
      
            fact = beta[j] / (fret_tau * tau[j]) * d_tau_d_alf(tau[j],tau_min[j],tau_max[j]);
         
            add_derivative(thread, j, 0, g, tau, theta, fact, ref_lifetime, b+idx);

            col++;
            idx += ndim;
         }

      }
   }

   return col;

}

int FLIMGlobalFitController::beta_derivatives(int thread, double tau[], double alf[], double theta[], double ref_lifetime, double b[])
{
   double fact;
  
   int col = 0;
   int idx = 0;

   for(int j=0; j<n_exp-1; j++)
   {
      for(int p=0; p<n_pol_group; p++)
      {
         for(int g=0; g<n_decay_group; g++)
         {
            memset(b+idx, 0, n_meas*sizeof(double)); 

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
   double fact;

   int col = 0;
   int idx = 0;

   for(int p=n_theta_fix; p<n_theta; p++)
   {
      memset(b+idx, 0, n_meas*sizeof(double));

      for(int j=0; j<n_exp; j++)
      {      
         fact  = beta[j] / theta[p] / theta[p] * d_tau_d_alf(theta[p],0,1000000);
         add_derivative(thread, j, p+1, 0, tau, theta, fact, ref_lifetime, b+idx);
      }

      idx += ndim;
      col++;
   }

   return col;

}

int FLIMGlobalFitController::E_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[])
{
   double fact;
   
   int col = 0;
   int idx = 0;

   for(int i=0; i<n_fret_v; i++)
   {
      int g = i + n_fret_fix + (inc_donor ? 1 : 0);

      memset(b+idx, 0, n_meas*sizeof(double));
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