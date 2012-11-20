#include "IRFConvolution.h"
#include "ModelADA.h"


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





void conv_irf_tcspc(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c)
{
   c = exp_irf_cum_buf[gc->irf_max[k*gc->n_t+i]];
   if (gc->pulsetrain_correction && pulse_fact > 0)
      c += exp_irf_cum_buf[(k+1)*gc->n_irf-1] / pulse_fact;
}

void conv_irf_timegate(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c)
{
   int j = k*gc->n_t+i;
   c = exp_irf_cum_buf[gc->irf_max[j]] - 0.5*exp_irf_buf[gc->irf_max[j]];

   if (gc->pulsetrain_correction && pulse_fact > 0)
      c += (exp_irf_cum_buf[(k+1)*gc->n_irf-1] - 0.5*exp_irf_buf[(k+1)*gc->n_irf-1])  / pulse_fact;
}

void conv_irf_deriv_tcspc(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;
   
   c = t * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]];
   
   if (gc->pulsetrain_correction && pulse_fact > 0)
   {
      double c_rep = (t+gc->t_rep) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] ;
      c_rep /= pulse_fact;
      c += c_rep; 
   }
   
}

void conv_irf_deriv_timegate(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   double c_rep;
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;

   c  =        t * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]];
   c -= 0.5 * (t * exp_irf_buf[gc->irf_max[j]] - exp_irf_tirf_buf[gc->irf_max[j]]);
   
   if (gc->pulsetrain_correction && pulse_fact > 0)
   {
      c_rep  =        (t+gc->t_rep) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end];
      c_rep -= 0.5 * ((t+gc->t_rep) * exp_irf_buf[irf_end] -  exp_irf_tirf_buf[irf_end]);
      
      c     += c_rep / pulse_fact;
   }
   
}

void conv_irf_deriv_ref_tcspc(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   double c_rep;
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;

   c = ( t * ref_fact + 1 ) * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]] * ref_fact;
   
   
   if (gc->pulsetrain_correction && pulse_fact > 0)
   {
      c_rep = ( (t+gc->t_rep) * ref_fact + 1 ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact;
      c += c_rep / pulse_fact;
   } 
   
}

void conv_irf_deriv_ref_timegate(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   double c_rep;
   double last = 0;
   int j = k*gc->n_t+i;
   int irf_end = (k+1)*gc->n_irf-1;
   
   c  =        ( t * ref_fact + 1 ) * exp_irf_cum_buf[gc->irf_max[j]] - exp_irf_tirf_cum_buf[gc->irf_max[j]] * ref_fact;
   c -= 0.5 * (( t * ref_fact + 1 ) * exp_irf_buf[gc->irf_max[j]] - exp_irf_tirf_buf[gc->irf_max[j]] * ref_fact);
   
   
   if (gc->pulsetrain_correction && pulse_fact > 0)
   {
      c_rep  =        ( (t+gc->t_rep) * ref_fact + 1 ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact;
      c_rep -= 0.5 * (( (t+gc->t_rep) * ref_fact + 1 ) * exp_irf_buf[irf_end] - exp_irf_tirf_buf[irf_end] * ref_fact);
      c_rep /= pulse_fact;
      c += c_rep;
   }
   
}



