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

#include "ModelADA.h"
#include "DecayModel.h"
#include "IRFConvolution.h"

#include <cmath>
#include <algorithm>

using std::min;
using std::max;


void DecayModel::SetupIncMatrix(int* inc)
{
   int i, j, n_exp_col, cur_col;

   // Set up incidence matrix
   //----------------------------------------------------------------------

   int inc_row = 0;   // each row represents a non-linear variable
   int inc_col = 0;   // each column represents a phi, eg. exp(...)

   // Set incidence matrix zero
   for(i=0; i<96; i++)
      inc[i] = 0;

      
   // Set inc for local offset if required
   // Independent of all variables
   if( fit_offset == FIT_LOCALLY )
      inc_col++;

   // Set inc for local scatter if required
   // Independent of all variables
   if( fit_scatter == FIT_LOCALLY )
      inc_col++;

   if( fit_tvb == FIT_LOCALLY )
      inc_col++;
            
   // Set diagonal elements of incidence matrix for variable tau's   
   n_exp_col = beta_global ? 1 : n_exp;
   cur_col = beta_global ? 0 : n_fix;
   for(i=n_fix; i<n_exp; i++)
   {
      if (decay_group_buf[i] > cur_col)
         cur_col++;
      for(j=0; j<(n_pol_group*n_fret_group); j++)
         inc[inc_row + (inc_col+j*n_exp_phi+cur_col)*12] = 1;
      if (!beta_global)
         cur_col++;
      inc_row++;
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   cur_col = 0;
   for(i=0; i<n_beta; i++)
   {
      if (decay_group_buf[i+1+cur_col] > cur_col)
         cur_col++;    
      for(j=0; j<(n_pol_group*n_fret_group); j++)
         inc[inc_row + (inc_col+j*n_exp_phi+cur_col)*12] = 1;
                        
      inc_row++;
   }

   // Variable Thetas
   for(i=0; i<n_theta_v; i++)
   {
      inc[inc_row+(inc_col+i+1+n_theta_fix)*12] = 1;
      inc_row++;
   }
         
   // Set elements of incidence matrix for E derivatives
   for(i=0; i<n_fret_v; i++)
   {
      for(j=0; j<n_exp_phi; j++)
         inc[inc_row+(inc_donor+n_fret_fix+inc_col+i*n_exp_phi+j)*12] = 1;
      inc_row++;
   }

   if (ref_reconvolution == FIT_GLOBALLY)
   {
      // Set elements of inc for ref lifetime derivatives
      for(i=0; i<( n_pol_group* n_fret_group * n_exp_phi ); i++)
      {
         inc[inc_row+(inc_col+i)*12] = 1;
      }
      inc_row++;
   }

   inc_col += n_pol_group * n_fret_group * n_exp_phi;
              
   // Both global offset and scatter are in col L+1

   if( fit_offset == FIT_GLOBALLY )
   {
      inc[inc_row + inc_col*12] = 1;
      inc_row++;
   }

   if( fit_scatter == FIT_GLOBALLY )
   {
      inc[inc_row + inc_col*12] = 1;
      inc_row++;
   }

   if( fit_tvb == FIT_GLOBALLY )
   {
      inc[inc_row + inc_col*12] = 1;
      inc_row++;
   }


}





/* ============================================================== */
int DecayModel::CalculateModel(Buffers& wb, double *a, int adim, double *b, int bdim, double *kap, const double *alf, int irf_idx, int isel)
{

   int i,j,k, d_offset, total_n_exp, idx;
   int a_col;
   
   double ref_lifetime;
   
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   int getting_fit = false; //TODO

   double t0;
   
   if ( fit_t0 )
      t0 = alf[alf_t0_idx];
   else
      t0 = t0_guess;

   if (ref_reconvolution == FIT_GLOBALLY)
      ref_lifetime = alf[alf_ref_idx];
   else
      ref_lifetime = ref_lifetime_guess;

   total_n_exp = n_exp * n_fret_group;
             

   switch(isel)
   {
      case 1:
      case 2:

         // Set constant phi values
         //----------------------------
         a_col = 0;
         
         // set constant phi value for offset
         if( fit_offset == FIT_LOCALLY )
         {
            for(i=0; i<n_meas; i++)
               a[adim*a_col+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+adim*a_col] += 1;
                  idx++;
               }
            }
            a_col++;
         }

         // set constant phi value for scatterer
         if( fit_scatter == FIT_LOCALLY )
         {
            for(i=0; i<n_meas; i++)
               a[adim*a_col+i]=0;
            add_irf(wb.irf_buf, irf_idx, a+adim*a_col,n_r,scale_fact);
            a_col++;
         }

         // set constant phi value for tvb
         if( fit_tvb == FIT_LOCALLY )
         {
            for(i=0; i<n_meas; i++)
               a[adim*a_col+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+adim*a_col] += tvb_profile[k*n_t+i];
                  idx++;
               }
            }
            a_col++;
         }

         // Set tau's
         double buf; 
         for(j=0; j<n_fix; j++)
            wb.tau_buf[j] = tau_guess[j];
         for(j=0; j<n_v; j++)
         {
            buf = InverseTransformRange(alf[j],tau_min[j+n_fix],tau_max[j+n_fix]);
            wb.tau_buf[j+n_fix] = max(buf,60.0);
         }
         // Set theta's
         for(j=0; j<n_theta_fix; j++)
            wb.theta_buf[j] = theta_guess[j];
         for(j=0; j<n_theta_v; j++)
         {
            buf = InverseTransformRange(alf[alf_theta_idx+j],0,1000000);
            wb.theta_buf[j+n_theta_fix] = max(buf,60.0);
         }


         // Set beta's
         if (fit_beta == FIT_GLOBALLY)
         {

            int group_start = 0;
            int group_end = 0;
            int d_idx = 0;

            for(int d=0; d<n_decay_group; d++)
            {
               int n_group = 0;
               while(d_idx < n_exp && decay_group_buf[d_idx]==d)
               {
                  d_idx++;
                  n_group++;
                  group_end++;
               }
               alf2beta(n_group,alf+alf_beta_idx+group_start-d,wb.beta_buf+group_start);
               
               group_start = group_end;

            }

         }
         else if (fit_beta == FIX) 
         {
            for(j=0; j<n_exp; j++)
               wb.beta_buf[j] = fixed_beta[j];
         }
         
         // Set tau's for FRET
         idx = n_exp;
         for(i=0; i<n_fret; i++)
         {
            double E;
            if (i<n_fret_fix)
               E = E_guess[i];
            else
            {
               E = alf[alf_E_idx+i-n_fret_fix]; //alf[alf_E_idx+i-n_fret_fix];
            }
            for(j=0; j<n_exp; j++)
            {
               double Ej = wb.tau_buf[j]/wb.tau_buf[0]*E;
               Ej = Ej / (1-E+Ej);

                wb.tau_buf[idx++] = wb.tau_buf[j] * (1-Ej);
            }
         }

         // Precalculate exponentials
         if (check_alf_mod(wb, alf, irf_idx))
            calculate_exponentials(wb, irf_idx);

         a_col += flim_model(wb, irf_idx, ref_lifetime, isel == 1, a+a_col*adim, adim);


         // Set L+1 phi value (without associated beta), to include global offset/scatter
         //----------------------------------------------
         
         for(i=0; i<n_meas; i++)
            a[ i + adim*a_col ] = 0;
            
         // Add scatter
         if (fit_scatter == FIT_GLOBALLY)
         {
            add_irf(wb.irf_buf, irf_idx, a+adim*a_col,n_r,scale_fact);
            for(i=0; i<n_meas; i++)
               a[ i + adim*a_col ] = a[ i + adim*a_col ] * alf[alf_scatter_idx];
         }

         // Add tvb
         if (fit_tvb == FIT_GLOBALLY)
         {
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+adim*a_col] += tvb_profile[k*n_t+i] * alf[alf_tvb_idx];
                  idx++;
               }
            }
         }

         // Add offset
         
         if (fit_offset == FIT_GLOBALLY)
         {
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+adim*a_col] += alf[alf_offset_idx];
                  idx++;
               }
            }
         }

         if (use_kappa && kap != NULL)
         {
            kap[0] = 0;
            for(i=1; i<n_v; i++)
               kap[0] += kappa_spacer(alf[i],alf[i-1]);
            for(i=0; i<n_v; i++)
               kap[0] += kappa_lim(alf[i]);
            for(i=0; i<n_theta_v; i++)
               kap[0] += kappa_lim(alf[alf_theta_idx+i]);
         }

         /*
         fx = fopen("c:\\users\\scw09\\Documents\\dump-a.txt","w");
         if (fx!=NULL)
         {
            for(j=0; j<n_meas; j++)
            {
               for(i=0; i<a_col; i++)
               {
                  fprintf(fx,"%f\t",a[i*N+j]);
               }
               fprintf(fx,"\n");
            }
            fclose(fx);
         }
         */

         for(i=0; i<adim*(a_col+1); i++)
            a[i] *= photons_per_count; 
         
         if (isel==2 || getting_fit)
            break;
      
      case 3:    
      
         int col = 0;
         
         col += tau_derivatives(wb, ref_lifetime, b+col*bdim, bdim);
         
         if (fit_beta == FIT_GLOBALLY)
            col += beta_derivatives(wb, ref_lifetime, b+col*bdim, bdim);
         
         col += E_derivatives(wb, ref_lifetime, b+col*bdim, bdim);
         col += theta_derivatives(wb, ref_lifetime, b+col*bdim, bdim);

         if (ref_reconvolution == FIT_GLOBALLY)
            col += ref_lifetime_derivatives(wb, ref_lifetime, b+col*bdim, bdim);
                  
         /*
         FILE* fx = fopen("c:\\users\\scw09\\Documents\\dump-b.txt","w");
         if (fx!=NULL)
         {
            for(j=0; j<n_meas; j++)
            {
               for(i=0; i<col; i++)
               {
                  fprintf(fx,"%f\t",b[i*ndim+j]);
               }
               fprintf(fx,"\n");
            }
            fclose(fx);
         }
         */


         d_offset = bdim * col;

          // Set derivatives for offset 
         if(fit_offset == FIT_GLOBALLY)
         {
            for(i=0; i<n_meas; i++)
               b[d_offset+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  b[d_offset + idx] += 1;
                  idx++;
               }
            }
            d_offset += bdim;
            col++;
         }
         
         // Set derivatives for scatter 
         if(fit_scatter == FIT_GLOBALLY)
         {
            for(i=0; i<n_meas; i++)
               b[d_offset+i]=0;
            add_irf(wb.irf_buf, irf_idx, b+d_offset,n_r,scale_fact);
            d_offset += bdim;
            col++;
         }

         // Set derivatives for tvb 
         if(fit_tvb == FIT_GLOBALLY)
         {
            for(i=0; i<n_meas; i++)
               b[d_offset+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  b[ d_offset + idx ] += tvb_profile[k*n_t+i];
                  idx ++;
               }
            }
            d_offset += bdim;
            col++;
         }

        for(i=0; i<col*bdim; i++)
            b[i] *= photons_per_count; 

         if (use_kappa && kap != NULL)
         {
            double *kap_derv = kap+1;

            for(i=0; i<nl; i++)
               kap_derv[i] = 0;

            for(i=0; i<n_v; i++)
            {
               kap_derv[i] = -kappa_lim(wb.tau_buf[n_fix+i]);
               if (i<n_v-1)
                  kap_derv[i] += kappa_spacer(wb.tau_buf[n_fix+i+1],wb.tau_buf[n_fix+i]);
               if (i>0)
                  kap_derv[i] -= kappa_spacer(wb.tau_buf[n_fix+i],wb.tau_buf[n_fix+i-1]);
            }
            for(i=0; i<n_theta_v; i++)
            {
               kap_derv[alf_theta_idx+i] =  -kappa_lim(wb.theta_buf[n_theta_fix+i]);
            }

            
         }
   }

   return 0;
}


void DecayModel::GetWeights(Buffers& wb, float* y, double* a, const double *alf, float* lin_params, double* w, int irf_idx)
{

   int i, l_start;
   double F0, ref_lifetime;

   if ( ref_reconvolution && lin_params != NULL)
   {
      if (ref_reconvolution == FIT_GLOBALLY)
         ref_lifetime = alf[alf_ref_idx];
      else
         ref_lifetime = ref_lifetime_guess;


      // Don't include stray light in weighting
      l_start = (fit_offset  == FIT_LOCALLY) + 
                (fit_scatter == FIT_LOCALLY) + 
                (fit_tvb     == FIT_LOCALLY);

      F0 = 0;
      for(i=l_start; i<l; i++)
         F0 = lin_params[i];
      
      for(i=0; i<n_meas; i++)
         w[i] /= ref_lifetime;

      add_irf(wb.irf_buf, irf_idx, w, n_r, &F0);
     
      // Variance = (D + F0 * D_r);

   }

}

float* DecayModel::GetConstantAdjustment()
{
   return adjust_buf;
}