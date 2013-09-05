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


#include "IRFConvolution.h"
#include "DecayModel.h"
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


// TODO: can we eliminate requirement for irf_max?


void DecayModelWorkingBuffers::conv_irf_tcspc(double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c)
{
   c = exp_irf_cum_buf[irf_max[k*n_t+i]];
   if (pulsetrain_correction && pulse_fact > 0)
      c += exp_irf_cum_buf[(k+1)*n_irf-1] / pulse_fact;
}

void DecayModelWorkingBuffers::conv_irf_timegate(double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c)
{
   int j = k*n_t+i;
   c = exp_irf_cum_buf[irf_max[j]] - 0.5*exp_irf_buf[irf_max[j]];

   if (pulsetrain_correction && pulse_fact > 0)
      c += (exp_irf_cum_buf[(k+1)*n_irf-1] - 0.5*exp_irf_buf[(k+1)*n_irf-1])  / pulse_fact;
}

void DecayModelWorkingBuffers::conv_irf_deriv_tcspc(double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   int j = k*n_t+i;
   int irf_end = (k+1)*n_irf-1;
   
   c = t * exp_irf_cum_buf[irf_max[j]] - exp_irf_tirf_cum_buf[irf_max[j]];
   
   if (pulsetrain_correction && pulse_fact > 0)
   {
      double c_rep = (t+t_rep) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] ;
      c_rep /= pulse_fact;
      c += c_rep; 
   }
   
}

void DecayModelWorkingBuffers::conv_irf_deriv_timegate(double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   double c_rep;
   int j = k*n_t+i;
   int irf_end = (k+1)*n_irf-1;

   c  =        t * exp_irf_cum_buf[irf_max[j]] - exp_irf_tirf_cum_buf[irf_max[j]];
   c -= 0.5 * (t * exp_irf_buf[irf_max[j]] - exp_irf_tirf_buf[irf_max[j]]);
   
   if (pulsetrain_correction && pulse_fact > 0)
   {
      c_rep  =        (t+t_rep) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end];
      c_rep -= 0.5 * ((t+t_rep) * exp_irf_buf[irf_end] -  exp_irf_tirf_buf[irf_end]);
      
      c     += c_rep / pulse_fact;
   }
   
}

void DecayModelWorkingBuffers::conv_irf_deriv_ref_tcspc(double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   double c_rep;
   int j = k*n_t+i;
   int irf_end = (k+1)*n_irf-1;

   c = ( t * ref_fact + 1 ) * exp_irf_cum_buf[irf_max[j]] - exp_irf_tirf_cum_buf[irf_max[j]] * ref_fact;
   
   
   if (pulsetrain_correction && pulse_fact > 0)
   {
      c_rep = ( (t+t_rep) * ref_fact + 1 ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact;
      c += c_rep / pulse_fact;
   } 
   
}

void DecayModelWorkingBuffers::conv_irf_deriv_ref_timegate(double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c)
{
   double c_rep;
   int j = k*n_t+i;
   int irf_end = (k+1)*n_irf-1;
   
   c  =        ( t * ref_fact + 1 ) * exp_irf_cum_buf[irf_max[j]] - exp_irf_tirf_cum_buf[irf_max[j]] * ref_fact;
   c -= 0.5 * (( t * ref_fact +  1 ) * exp_irf_buf[irf_max[j]] - exp_irf_tirf_buf[irf_max[j]] * ref_fact);
   
   
   if (pulsetrain_correction && pulse_fact > 0)
   {
      c_rep  =        ( (t+t_rep) * ref_fact + 1 ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact;
      c_rep -= 0.5 * (( (t+t_rep) * ref_fact + 1 ) * exp_irf_buf[irf_end] - exp_irf_tirf_buf[irf_end] * ref_fact);
      c_rep /= pulse_fact;
      c += c_rep;
   }
   
}



