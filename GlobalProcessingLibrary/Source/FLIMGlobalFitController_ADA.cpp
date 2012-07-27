#include "ModelADA.h"
#include "FlimGlobalFitController.h"
#include "IRFConvolution.h"



void FLIMGlobalFitController::SetupIncMatrix(int* inc)
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
   for(i=n_fix; i<n_exp; i++)
   {
      cur_col = beta_global ? 0 : i;
      for(j=0; j<(n_pol_group*n_decay_group); j++)
         inc[inc_row + (inc_col+j*n_exp_phi+cur_col)*12] = 1;

      inc_row++;
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   for(i=0; i<n_beta; i++)
   {
      for(j=0; j<(n_pol_group*n_decay_group); j++)
         inc[inc_row + (inc_col+j*n_exp_phi)*12] = 1;
                                
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
      for(i=0; i<( n_pol_group* n_decay_group * n_exp_phi ); i++)
      {
         inc[inc_row+(inc_col+i)*12] = 1;
      }
      inc_row++;
   }

   /*
   // Set inc elements for t0 if required
   if( fit_t0 )
   {
      for(i=0; i<n_exp; i++)
            inc[inc_row+(inc_col+i)*12] = 1;
      inc_row++;
   }
   */

   inc_col += n_pol_group * n_decay_group * n_exp_phi;
              
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
int FLIMGlobalFitController::ada(double *a, double *b, double *kap, const double *alf, int isel, int thread)
{

   int i,j,k, d_offset, total_n_exp, idx;
   int a_col;
   
   double ref_lifetime;
   
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   int N = n;

   double t0;

   int n_meas = data->GetResampleNumMeas(thread);
                               
   double *exp_buf   = this->exp_buf + thread * n_decay_group * exp_buf_size;
   double *tau_buf   = this->tau_buf + thread * n_exp * (n_fret + 1);
   double *beta_buf  = this->beta_buf + thread * n_exp;
   double *theta_buf = this->theta_buf + thread * n_theta;
   float  *w         = this->w + thread * n;
   float  *y         = this->y + thread * n * (s+1);

   int locked_param = -1;//locked_param[*thread];
   double locked_value = 0;//locked_value[*thread];

   
   if ( fit_t0 )
      t0 = alf[alf_t0_idx];
   else
      t0 = t0_guess;

   if (ref_reconvolution == FIT_GLOBALLY)
      ref_lifetime = alf[alf_ref_idx];
   else
      ref_lifetime = ref_lifetime_guess;

   total_n_exp = n_exp * n_decay_group;
        

   int* resample_idx = data->GetResampleIdx(thread);
      

   switch(isel)
   {
      case 1:
         // Set constant phi values
         //----------------------------
         a_col = 0;
         
         // set constant phi value for offset
         if( fit_offset == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[N*a_col+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+N*a_col] += 1;
                  idx += resample_idx[i];
               }
               idx++;
            }
            a_col++;
         }

         // set constant phi value for scatterer
         if( fit_scatter == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[N*a_col+i]=0;
            sample_irf(thread, a+N*a_col,n_r,scale_fact);
            a_col++;
         }

         // set constant phi value for tvb
         if( fit_tvb == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[N*a_col+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+N*a_col] += tvb_profile[k*n_t+i];
                  idx += resample_idx[i];
               }
               idx++;
            }
            a_col++;
         }

      case 2:

//         if (locked_param >= 0)
//            alf[locked_param] = locked_value;

         a_col = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
         

         // Set tau's
         for(j=0; j<n_fix; j++)
            tau_buf[j] = tau_guess[j];
         for(j=0; j<n_v; j++)
         {
            tau_buf[j+n_fix] = InverseTransformRange(alf[j],tau_min[j+n_fix],tau_max[j+n_fix]);
            tau_buf[j+n_fix] = max(tau_buf[j+n_fix],60);
         }
         // Set theta's
         for(j=0; j<n_theta_fix; j++)
            theta_buf[j] = theta_guess[j];
         for(j=0; j<n_theta_v; j++)
         {
            theta_buf[j+n_theta_fix] = InverseTransformRange(alf[alf_theta_idx+j],0,1000000);
            theta_buf[j+n_theta_fix] = max(theta_buf[j+n_theta_fix],60);
         }


         // Set beta's
         if (fit_beta == FIT_GLOBALLY)
         {
            alf2beta(n_exp,alf+alf_beta_idx,beta_buf);
         }
         else if (fit_beta == FIX) 
         {
            for(j=0; j<n_exp; j++)
               beta_buf[j] = fixed_beta[j];
         }
         
         // Set tau's for FRET
         idx = n_exp;
         for(i=0; i<n_fret; i++)
         {
            double E;
            if (i<n_fret_fix)
               E = E_guess[i];
            else
               E = alf[alf_E_idx+i-n_fret_fix]; //alf[alf_E_idx+i-n_fret_fix];

            for(j=0; j<n_exp; j++)
               tau_buf[idx++] = tau_buf[j] * (1-E);
         }

         // Precalculate exponentials
         if (check_alf_mod(thread, alf))
            calculate_exponentials(thread, tau_buf, theta_buf);

         a_col += flim_model(thread, tau_buf, beta_buf, theta_buf, ref_lifetime, isel == 1, a+a_col*N);


         // Set L+1 phi value (without associated beta), to include global offset/scatter
         //----------------------------------------------
         
         for(i=0; i<N; i++)
            a[ i + N*a_col ] = 0;
            
         // Add scatter
         if (fit_scatter == FIT_GLOBALLY)
         {
            sample_irf(thread, a+N*a_col,n_r,scale_fact);
            for(i=0; i<N; i++)
               a[ i + N*a_col ] = a[ i + N*a_col ] * alf[alf_scatter_idx];
         }

         // Add tvb
         if (fit_tvb == FIT_GLOBALLY)
         {
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+N*a_col] += tvb_profile[k*n_t+i] * alf[alf_tvb_idx];
                  idx += resample_idx[i];
               }
               idx++;
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

         // Add offset
         
         if (fit_offset == FIT_GLOBALLY)
         {
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  a[idx+N*a_col] += alf[alf_offset_idx];
                  idx += resample_idx[i];
               }
               idx++;
            }
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
         
         if (isel==2 || getting_fit)
            break;
      
      case 3:    
      
         int col = 0;
         
         col += tau_derivatives(thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*ndim);
         
         if (fit_beta == FIT_GLOBALLY)
            col += beta_derivatives(thread, tau_buf, alf+alf_beta_idx, theta_buf, ref_lifetime, b+col*ndim);
         
         col += E_derivatives(thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*ndim);
         col += theta_derivatives(thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*ndim);

         if (ref_reconvolution == FIT_GLOBALLY)
            col += ref_lifetime_derivatives(thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*ndim);
                  
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


         d_offset = ndim * col;

          // Set derivatives for offset 
         if(fit_offset == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  b[d_offset + idx] += 1;
                  idx += resample_idx[i];
               }
               idx++;
            }
            d_offset += ndim;
         }
         
         // Set derivatives for scatter 
         if(fit_scatter == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            sample_irf(thread, b+d_offset,n_r,scale_fact);
            d_offset += ndim;
         }

         // Set derivatives for tvb 
         if(fit_tvb == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            idx = 0;
            for(k=0; k<n_chan; k++)
            {
               for(i=0; i<n_t; i++)
               {
                  b[ d_offset + idx ] += tvb_profile[k*n_t+i];
                  idx += resample_idx[i];
               }
               idx++;
            }
            d_offset += ndim;
         }

         if (use_kappa && kap != NULL)
         {
            double *kap_derv = kap+1;

            for(i=0; i<nl; i++)
               kap_derv[i] = 0;

            for(i=0; i<n_v; i++)
            {
               kap_derv[i] = -kappa_lim(tau_buf[n_fix+i]);
               if (i<n_v-1)
                  kap_derv[i] += kappa_spacer(tau_buf[n_fix+i+1],tau_buf[n_fix+i]);
               if (i>0)
                  kap_derv[i] -= kappa_spacer(tau_buf[n_fix+i],tau_buf[n_fix+i-1]);
            }
            for(i=0; i<n_theta_v; i++)
            {
               kap_derv[alf_theta_idx+i] =  -kappa_lim(theta_buf[n_theta_fix+i]);
            }

            
         }
/*
         if (locked_param >= 0)
         {
            idx = 0; 
            int count = 0;
            for(i=0; i<locked_param; i++)
               for(j=0; j<12; j++)
                  count += inc[idx++];

            int i_inc = 0;
            for(i=0; i<12; i++)
            {
               if(inc[i+12*locked_param])
               {
                  for(j=0; j<N; j++)
                     b[ (count+i_inc)*ndim + j ] *= 1e-10;
                  i_inc++;
               }
            }
         }
         */
   }

   return 0;
}


void FLIMGlobalFitController::sample_irf(int thread, float a[], int pol_group, double* scale_fact)
{
   int k=0;
   double scale;
   int idx = 0;

   int* resample_idx = data->GetResampleIdx(thread);

   for(int i=0; i<n_chan; i++)
   {
      scale = (scale_fact == NULL) ? 1 : scale_fact[i];
      for(int j=0; j<n_t; j++)
      {
         a[idx] += (resampled_irf[j]) * chan_fact[pol_group*n_chan+i] * scale;
         idx += resample_idx[j];
      }
      idx++;
   }
}


void FLIMGlobalFitController::sample_irf(int thread, double a[], int pol_group, double* scale_fact)
{
   int k=0;
   double scale;
   int idx = 0;

   int* resample_idx = data->GetResampleIdx(thread);

   for(int i=0; i<n_chan; i++)
   {
      scale = (scale_fact == NULL) ? 1 : scale_fact[i];
      for(int j=0; j<n_t; j++)
      {
         a[idx] += (resampled_irf[j]) * chan_fact[pol_group*n_chan+i] * scale;
         idx += resample_idx[j];
      }
      idx++;
   }
}