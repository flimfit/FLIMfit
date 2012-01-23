#include "IRFConvolution.h"
#include "ModelADA.h"

void alf2beta(int n, double alf[], double beta[])
{

   for(int i=0; i<n; i++)
      beta[i] = 1;

   for(int i=0; i<n-1; i++)
   {
      beta[i] *= alf[i];
      for(int j=i+1; j<n; j++)
         beta[j] *= 1-alf[i];
   }

}

double beta_derv(int n_beta, int alf_idx, int beta_idx, double alf[])
{
   double d;

   if(beta_idx<=alf_idx)
      d = 1;
   else if (beta_idx<n_beta-1)
      d = -alf[beta_idx];
   else
      d = -1;

   for(int k=0; k<(beta_idx-1); k++)
   {
      d *= (1-alf[k]);
   }

   return d;
}

/*
void beta_derv(int n, double alf[], double d[])
{

   for(int i=0; i<n-1; i++)
   {
      for(int j=i; j<n;   j++)
      {
         if(j<=i)
            d[i][j] = 1;
         else if (j<n-1)
            d[i][j] = -alf[j];
         else
            d[i][j] = -1;

         for(int k=0; k<(j-1); k++)
         {
               d[i][j] *= (1-alf[k]);
         }
   }

}
*/



void calc_exps(FLIMGlobalFitController *gc, int n_t, double t[], int total_n_exp, double tau[], int n_theta, double theta[], double exp_buf[])
{
   double e0, de, ej, cum, tcspc_fact, inv_theta, rate;
   int i,j,k,m, idx, next_idx, n_no_theta;
   int row = gc->n_pol_group*total_n_exp*N_EXP_BUF_ROWS;

   // Calculate in reverse order so we don't overwrite.
   n_no_theta = gc->n_pol_group - n_theta;
   for(m=gc->n_pol_group-1; m>=0; m--)
   {
      if (m>0)
         inv_theta = 1/theta[m-1];
      else
         inv_theta = 0;

      for(i=total_n_exp-1; i>=0; i--)
      {
         row--;

         if (gc->use_magic_decay)
            rate = inv_theta;
         else
            rate = 1/tau[i] + inv_theta;

         // IRF exponential factor

         e0 = exp( (gc->t_irf[0] + gc->t0_guess) * rate ) * gc->t_g;
         de = exp( + gc->t_g * rate );
         ej = e0;

         for(j=0; j<gc->n_irf; j++)
         {
            for(k=0; k<gc->n_chan; k++)
            {
               exp_buf[j+k*gc->n_irf+row*gc->exp_dim] = ej * gc->irf[j+k*gc->n_irf]; //* gc->magic_decay[j];
            }
            ej *= de;
         }

         row--;

         // Cumulative IRF expontial
         for(k=0; k<gc->n_chan; k++)
         {
            next_idx = row*gc->exp_dim + k*gc->n_irf;
            idx = next_idx + gc->exp_dim;
            cum = exp_buf[idx++];
            for(j=0; j<gc->n_irf; j++)
            {
   	         exp_buf[next_idx++] = cum;
               cum += exp_buf[idx++];
            }
         }

         row--;

         // IRF exponential factor * t_irf
         for(k=0; k<gc->n_chan; k++)
         {
            next_idx = row*gc->exp_dim + k*gc->n_irf;
            idx = next_idx + 2*gc->exp_dim;
            for(j=0; j<gc->n_irf; j++)
            {
   	         exp_buf[next_idx++] = exp_buf[idx++] * (gc->t_irf[j] + gc->t0_guess);
            }
         }

         row--;

         // Cumulative IRF expontial * t_irf
         for(k=0; k<gc->n_chan; k++)
         {
            next_idx = row*gc->exp_dim + k*gc->n_irf;
            idx = next_idx + gc->exp_dim;
            cum = exp_buf[idx++];
            for(j=0; j<gc->n_irf; j++)
            {
   	         exp_buf[next_idx++] = cum;
               cum += exp_buf[idx++];
            }
         }

         row--;

         /*
         // Previous contribution
         next_idx = row*gc->exp_dim;
         idx = (row+4)*gc->exp_dim;
         exp_rep = exp( - gc->t_rep / tau[i] );
         for(j=0; j<gc->n_irf; j++)
         {
   	      exp_buf[next_idx++] = exp_buf[idx++] * exp_rep;
         }
         */

         row--;
      
         // Actual decay
         if (gc->data_type == DATA_TYPE_TCSPC) // !gc->ref_reconvolution)
            tcspc_fact = ( 1 - exp( - (gc->t[1] - gc->t[0]) * rate ) ) / rate;
         else
            tcspc_fact = 1;
      
         for(k=0; k<gc->n_chan; k++)
         {
            for(j=0; j<n_t; j++)
            {
               exp_buf[j+k*gc->n_t+row*gc->exp_dim] = tcspc_fact * exp( - t[j] * rate ) * gc->chan_fact[m*gc->n_chan+k]; //* gc->magic_decay[j];
            }
         }

      }
   }
}

void conv_irf_tcspc(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double& c)
{
   c = exp_irf_cum_buf[gc->irf_max[k*gc->n_t+i]];
   if (gc->pulsetrain_correction)
      c += exp_irf_cum_buf[(k+1)*gc->n_irf-1] / ( exp( gc->t_rep * rate ) - 1 );
}

void conv_irf_timegate(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double& c)
{
   int j = k*gc->n_t+i;
   c = exp_irf_cum_buf[gc->irf_max[j]] - 0.5*exp_irf_buf[gc->irf_max[j]];

   if (gc->pulsetrain_correction)
      c += (exp_irf_cum_buf[(k+1)*gc->n_irf-1] - 0.5*exp_irf_buf[(k+1)*gc->n_irf-1])  / ( exp( gc->t_rep * rate ) - 1 );
}

void conv_irf_deriv_tcspc(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c)
{
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;
   
   c = t * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]];
   if (gc->pulsetrain_correction)
      c += ((t + gc->t_rep) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end])  / ( exp( gc->t_rep * rate ) - 1 );
}

void conv_irf_deriv_timegate(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c)
{
   double c_rep;
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;

   c  =        t * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]];
   c -= 0.5 * (t * exp_irf_buf[gc->irf_max[j]] - exp_irf_tirf_buf[gc->irf_max[j]]);
   
   if (gc->pulsetrain_correction)
   {
      c_rep  =        (t+gc->t_rep) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end];
      c_rep -= 0.5 * ((t+gc->t_rep) * exp_irf_buf[irf_end] -  exp_irf_tirf_buf[irf_end]);
      
      
      c     += c_rep / ( exp( gc->t_rep * rate ) - 1 );
   }

}

void conv_irf_deriv_ref_tcspc(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c)
{
   double c_rep;
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;

   c = ( t * ref_fact + 1 ) * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]] * ref_fact;
   
   if (gc->pulsetrain_correction)
   {
      c_rep = ( (t+gc->t_rep) * ref_fact + 1 ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact;
      c += c_rep / ( exp( gc->t_rep * rate ) - 1 );
   }  
}

void conv_irf_deriv_ref_timegate(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c)
{
   double c_rep;
   double last = 0;
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;
   
   c  =        ( t * ref_fact + 1 ) * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]] * ref_fact;
   c -= 0.5 * (( t * ref_fact + 1 ) * exp_irf_buf[gc->irf_max[j]] - exp_irf_tirf_buf[gc->irf_max[j]] * ref_fact);
   
   if (gc->pulsetrain_correction)
   {
      c_rep  =        ( (t+gc->t_rep) * ref_fact + 1 ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact;
      c_rep -= 0.5 * (( (t+gc->t_rep) * ref_fact + 1 ) * exp_irf_buf[irf_end] - exp_irf_tirf_buf[irf_end] * ref_fact);
      c_rep /= ( exp( gc->t_rep * rate ) - 1 );
      c += c_rep;
   }

   c = c;
}


int flim_model(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double beta[], int n_theta, double theta[], 
               double ref_lifetime, int dim, double a[], int add_components, int inc_beta_fact, int inc_ref_deriv_fact)
{
   double c, fact, rate, inv_theta;
   double *exp_model_buf, *exp_irf_buf, *exp_irf_cum_buf, *exp_irf_tirf_buf, *exp_irf_tirf_cum_buf, *exp_irf_rep_buf;
   int row;
   int idx;
  
   bool inc_irf_component = (gc->ref_reconvolution && !inc_ref_deriv_fact);

   if (add_components)
      memset(a, 0, gc->n_meas*gc->n_pol_group*sizeof(double)); 
   else
      for(int j=0; j<total_n_exp; j++)
         memset(a+j*dim, 0, gc->n_meas*sizeof(double));

   for(int p=0; p<gc->n_pol_group; p++)
   {
      
      if (inc_irf_component && add_components)
         sample_irf(gc, a+p*dim, p);
         
      for(int j=0; j<total_n_exp ; j++)
      {
         idx = p*dim + ((add_components) ? 0 : j*dim);
   
         row = N_EXP_BUF_ROWS*(j+p*gc->n_exp);
   
         exp_model_buf         = exp_buf +  row   *gc->exp_dim;
         exp_irf_rep_buf       = exp_buf + (row+1)*gc->exp_dim;
         exp_irf_tirf_cum_buf  = exp_buf + (row+2)*gc->exp_dim;
         exp_irf_tirf_buf      = exp_buf + (row+3)*gc->exp_dim;
         exp_irf_cum_buf       = exp_buf + (row+4)*gc->exp_dim;
         exp_irf_buf           = exp_buf + (row+5)*gc->exp_dim;

         c = 0;
         
         if (inc_irf_component && !add_components)
            sample_irf(gc, a+idx, p);
            
         if (p<n_theta)
            inv_theta = 1/theta[p];
         else
            inv_theta = 0;

         rate = 1/tau[j] + inv_theta;

         if (inc_ref_deriv_fact == 0)
            fact = gc->ref_reconvolution ? (1/ref_lifetime - rate)   : 1;
         else
            fact = - 1 / (ref_lifetime * ref_lifetime);

         if (inc_beta_fact)
            int ax = 1;

         //fact *= inc_beta_fact         ? d_beta_d_alf(beta[j])       : 1;
         fact *= inc_beta_fact         ? d_tau_d_alf(beta[j],0,10)    : 1;
         fact *= add_components        ? beta[j]                       : 1;



         for(int k=0; k<gc->n_chan; k++)
         {
            for(int i=0; i<n_t; i++)
            {
               gc->Convolve(gc, rate, exp_irf_buf, exp_irf_cum_buf, k, i, c);
               a[idx] += exp_model_buf[k*n_t+i] * c * fact;
               idx++;
            }
            
         }

	   }
   }


   return (gc->n_pol_group * (add_components ? 1 : total_n_exp));
}



int flim_model_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int n_tau, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double b[], int inc_tau, double donor_tau[])
{
   double c, tau_recp, fact, ref_fact, theta_recp, rate;
   int row, idx;
   double *exp_model_buf, *exp_irf_buf, *exp_irf_cum_buf, *exp_irf_tirf_buf, *exp_irf_tirf_cum_buf, *exp_irf_rep_buf;

   int col = 0;

   int fret_derivatives =  (!inc_tau && gc->beta_global);

   if (fret_derivatives)
   {
      memset(b, 0, gc->n_meas*sizeof(double));
      col = 1;
   }
   
   for(int j=0; j<n_tau; j++)
   {

      tau_recp = 1/tau[j];

      for(int p=0; p<gc->n_pol_group; p++)
      {
         if (fret_derivatives)
            idx = 0;
         else
            idx = (j*gc->n_pol_group+p)*dim;

         if (!fret_derivatives)
            memset(b+idx, 0, gc->n_meas*sizeof(double));

         if (p<n_theta)
            theta_recp = 1/theta[p];
         else
            theta_recp = 0;
      
         row = N_EXP_BUF_ROWS*(j+p*n_tau);

         exp_model_buf         = exp_buf +  row   *gc->exp_dim;
         exp_irf_rep_buf       = exp_buf + (row+1)*gc->exp_dim;
         exp_irf_tirf_cum_buf  = exp_buf + (row+2)*gc->exp_dim;
         exp_irf_tirf_buf      = exp_buf + (row+3)*gc->exp_dim;
         exp_irf_cum_buf       = exp_buf + (row+4)*gc->exp_dim;
         exp_irf_buf           = exp_buf + (row+5)*gc->exp_dim;

      
         if (inc_tau)
            fact = tau_recp * tau_recp * d_tau_d_alf(tau[j],gc->tau_min[j],gc->tau_max[j]);
         else
            fact = - tau_recp * tau_recp * donor_tau[j];

         fact *= gc->beta_global ? beta[j] : 1;

         rate = theta_recp + tau_recp;
         ref_fact = gc->ref_reconvolution ? (1/ref_lifetime - rate) : 1;

         for(int k=0; k<gc->n_chan; k++)
         {
            for(int i=0; i<n_t; i++)
            {
               gc->ConvolveDerivative(gc, t[i], rate, exp_irf_buf, exp_irf_cum_buf, exp_irf_tirf_buf, exp_irf_tirf_cum_buf, k, i, ref_fact, c);
               b[idx++] += exp_model_buf[k*n_t+i] * c * fact;
            }
         }

         if (!fret_derivatives)
            col++;

      }

      
      if (gc->use_kappa)
      {
         double dkap; // maintains order of taus
         if (j>0 && j < gc->n_v)
         {
            dkap = d_kappa_d_tau(tau[j],tau[j-1]);
            for(int i=0; i<gc->n_meas; i++)
               b[i+col*dim] = dkap;
            dkap = dkap;
            col++;
         }
      }
   }

   if (gc->fit_beta == FIT_GLOBALLY)
   {
      col += flim_model(gc, n_t, t, exp_buf, gc->n_beta, tau, beta, n_theta, theta, ref_lifetime, dim, b+col*dim, 0, 1);
   }

   return col;

}


int anisotropy_model_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int n_tau, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double b[])
{
   double c, tau_recp, fact, ref_fact, theta_recp, rate;
   int row, idx;
   double *exp_model_buf, *exp_irf_buf, *exp_irf_cum_buf, *exp_irf_tirf_buf, *exp_irf_tirf_cum_buf, *exp_irf_rep_buf;

   int col = 0;

   
   for(int p=0; p<gc->n_theta_v; p++)
   {
      memset(b+col*dim, 0, gc->n_meas*sizeof(double));

      theta_recp = 1/theta[p];

      for(int j=0; j<n_tau; j++)
      {
         idx = col*dim;

         tau_recp = 1/tau[j];
      
         row = N_EXP_BUF_ROWS*(j+p*n_tau);

         exp_model_buf         = exp_buf +  row   *gc->exp_dim;
         exp_irf_rep_buf       = exp_buf + (row+1)*gc->exp_dim;
         exp_irf_tirf_cum_buf  = exp_buf + (row+2)*gc->exp_dim;
         exp_irf_tirf_buf      = exp_buf + (row+3)*gc->exp_dim;
         exp_irf_cum_buf       = exp_buf + (row+4)*gc->exp_dim;
         exp_irf_buf           = exp_buf + (row+5)*gc->exp_dim;

      
         fact  = theta_recp * theta_recp * beta[j] * d_tau_d_alf(theta[p],0,1000000);

         rate = theta_recp + tau_recp;
         ref_fact = gc->ref_reconvolution ? (1/ref_lifetime - rate) : 1;

         for(int k=0; k<gc->n_chan; k++)
         {
            for(int i=0; i<n_t; i++)
            {
               gc->ConvolveDerivative(gc, t[i], theta[p], exp_irf_buf, exp_irf_cum_buf, exp_irf_tirf_buf, exp_irf_tirf_cum_buf, k, i, ref_fact, c);
               b[idx++] += exp_model_buf[k*n_t+i] * c * fact;
            }
         }
      }
      col++;
   }

   return col;

}




int flim_fret_model_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], double tau[], double beta[], double ref_lifetime, int dim, double b[])
{
   double *cur_exp_buf;
   int b_offset, col, tau_group, exp_group;
  
   col = 0;
   for(int i=0; i<gc->n_decay_group; i++)
   {
      col += flim_model_deriv(gc, n_t, t, exp_buf+i*gc->exp_buf_size, gc->n_v, tau+gc->tau_start*gc->n_exp, beta, 0, NULL, ref_lifetime, dim*gc->n_decay_group, b+i*dim, 1); // d(phi)/d(tau)
   }
   
   for(int i=0; i<gc->n_fret_v; i++)
   {
      b_offset = dim * col;
      exp_group = i+gc->inc_donor+gc->n_fret_fix;
      tau_group = i+1+gc->n_fret_fix;
      cur_exp_buf = exp_buf+exp_group*gc->exp_buf_size;
      col += flim_model_deriv(gc, n_t, t, cur_exp_buf, gc->n_exp, tau+gc->n_exp*tau_group, beta, 0, NULL, ref_lifetime, dim, b+b_offset, 0, tau); // d(phi_fret)/d(E) <- this actually depends on tau too.     
   }

   return col;
}


int ref_lifetime_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double b[])
{
   return flim_model(gc, n_t,t,exp_buf,total_n_exp,tau,beta,n_theta,theta,ref_lifetime,dim,b,gc->beta_global,0,1);
}

void sample_irf(FLIMGlobalFitController *gc, double a[],int pol_group, double* scale_fact)
{
   int k=0;
   double scale;

   for(int i=0; i<gc->n_chan; i++)
   {
      scale = (scale_fact == NULL) ? 1 : scale_fact[i];
      for(int j=0; j<gc->n_t; j++)
      {
         a[k] += (gc->resampled_irf[k]) * gc->chan_fact[pol_group*gc->n_chan+i] * scale;
         k++;
      }
   }
}

void conv_irf_diff_t0(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double a[], double ac[])
{
   double c, c_rep, c_interp, tau_inv_j;
   int k;
   int idx = 0;
   int row;

   for(int j=0; j<total_n_exp ; j++)
   {
      row = N_EXP_BUF_ROWS*j;
   
      c = 0;
      c_rep = 0;

      if (gc->pulsetrain_correction)
         for(k=0; k<gc->n_irf; k++)
            c_rep += exp_buf[k+(row+1)*gc->exp_dim] * gc->irf[k];

      tau_inv_j = 1/tau[j];
         
      k = 0;
      for(int i=0; i<n_t; i++)
      {
         while(k < gc->n_irf && (t[i] - gc->t_irf[k] - gc->t0_guess) >= 0)
         {
            c += exp_buf[k+(row+2)*gc->exp_dim] * gc->irf[k];
            k++;
         }

         c_interp = 0;
         if (k < gc->n_irf && k > 0)
         {
            c_interp = exp_buf[k+(row+2)*gc->exp_dim] * gc->irf[k] * (t[i] - gc->t_irf[k-1] - gc->t0_guess) / ( gc->t_irf[k] - gc->t_irf[k-1] ); 
         }


	      a[idx] = exp_buf[i+row*gc->exp_dim] * (c + c_rep + c_interp);

         idx++;
      }
	}
}



/*

for(i=0; i<n_tau; i++)
   beta[i] = 1;

for(i=0; i<(n_tau-1); i++)
{
   beta[i] *= alf[i];
   for(j=(i+1); j<n_tau; j++)
      beta[j] *= (1-alf[i]);
}

for(i=0; i<(n_tau-1); i++)
for(j=i; j<n_tau;     j++)
{
   if(j<=i)
      d[i][j] = 1;
   else if (j<(n_tau-1))
      d[i][j] = -alf[j];

   for(k=0; k<j; k++)
   {
      if k>
      d[i][j] *= (1-alf[k]);
   }



      if (k==i)
         d[i][j] *= 1;
      else if (k<j)
         d[i][j] *= ();
      else
         d[i][j] *= (1-alf[k]);
   }
}

}

*/


