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
#include "ExponentialPrecomputationBuffer.h"
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


void DecayModelWorkingBuffers::Convolve(double rate, int row, int k, int i, double pulse_fact, int bin_shift, double& c)
{
   const auto& exp_irf_cum_buf = exp_buffer[row].cum_irf_exp_factor[k];
   const auto& exp_irf_buf = exp_buffer[row].irf_exp_factor[k];

   int j = k*n_t+i;
   int idx = irf_max[j] + bin_shift;

   idx = idx < 0 ? 0 : idx;
   idx = idx >= n_irf ? n_irf-1 : idx;

   c = exp_irf_cum_buf[idx] - 0.5*exp_irf_buf[idx];

   if (pulsetrain_correction && pulse_fact > 0)
      c += (exp_irf_cum_buf[n_irf-1] - 0.5*exp_irf_buf[n_irf-1])  / pulse_fact;
}



void DecayModelWorkingBuffers::ConvolveDerivative(double t, double rate, int row, int k, int i, double pulse_fact, double ref_fact_a, double ref_fact_b, double& c)
{
   const auto& exp_model_buf = exp_buffer[row].model_decay[k];
   const auto& exp_irf_tirf_cum_buf = exp_buffer[row].cum_irf_exp_t_factor[k];
   const auto& exp_irf_tirf_buf = exp_buffer[row].irf_exp_t_factor[k];
   const auto& exp_irf_cum_buf = exp_buffer[row].cum_irf_exp_factor[k];
   const auto& exp_irf_buf = exp_buffer[row].irf_exp_factor[k];

   double c_rep;
   
   int idx = irf_max[k*n_t + i];
   int irf_end = n_irf - 1;

   c  =        ( t * ref_fact_a + ref_fact_b ) * exp_irf_cum_buf[idx] - exp_irf_tirf_cum_buf[idx] * ref_fact_a;
   c -= 0.5 * (( t * ref_fact_a +  ref_fact_b ) * exp_irf_buf[idx] - exp_irf_tirf_buf[idx] * ref_fact_a);
   
   
   if (pulsetrain_correction && pulse_fact > 0)
   {
      c_rep  =        ( (t+t_rep) * ref_fact_a + ref_fact_b ) * exp_irf_cum_buf[irf_end] - exp_irf_tirf_cum_buf[irf_end] * ref_fact_a;
      c_rep -= 0.5 * (( (t+t_rep) * ref_fact_a + ref_fact_b ) * exp_irf_buf[irf_end] - exp_irf_tirf_buf[irf_end] * ref_fact_a);
      c_rep /= pulse_fact;
      c += c_rep;
   }
   
}



