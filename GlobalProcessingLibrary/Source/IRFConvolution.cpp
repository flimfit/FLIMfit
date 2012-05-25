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



void sample_irf(int thread, FLIMGlobalFitController *gc, float a[], int pol_group, double* scale_fact)
{
   int k=0;
   double scale;
   int idx = 0;

   int* resample_idx = gc->data->GetResampleIdx(thread);

   for(int i=0; i<gc->n_chan; i++)
   {
      scale = (scale_fact == NULL) ? 1 : scale_fact[i];
      for(int j=0; j<gc->n_t; j++)
      {
         a[idx] += (gc->resampled_irf[j]) * gc->chan_fact[pol_group*gc->n_chan+i] * scale;
         idx += resample_idx[j];
      }
      idx++;
   }
}


void sample_irf(int thread, FLIMGlobalFitController *gc, double a[], int pol_group, double* scale_fact)
{
   int k=0;
   double scale;
   int idx = 0;

   int* resample_idx = gc->data->GetResampleIdx(thread);

   for(int i=0; i<gc->n_chan; i++)
   {
      scale = (scale_fact == NULL) ? 1 : scale_fact[i];
      for(int j=0; j<gc->n_t; j++)
      {
         a[idx] += (gc->resampled_irf[j]) * gc->chan_fact[pol_group*gc->n_chan+i] * scale;
         idx += resample_idx[j];
      }
      idx++;
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


