#include "ModelADA.h"
#include "FitStatus.h"
#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"

#define PI        3.141592654
#define halfPI    1.570796327
#define invPI     0.318309886

double TransformRange(double v, double v_min, double v_max)
{
   return v;
//   return log(v);

   double diff = v_max - v_min;
   return tan( PI*(v-v_min)/diff - halfPI );
}

double InverseTransformRange(double t, double v_min, double v_max)
{
   return t;
//   return exp(t);

   double diff = v_max - v_min;
   return invPI*diff*( atan(t) + halfPI ) + v_min;
}

double TransformRangeDerivative(double v, double v_min, double v_max)
{
   return 1;
//   return v;

   double t = TransformRange(v,v_min,v_max);
   double diff = v_max - v_min;
   return invPI*diff/(t*t+1);
}
/*
double tau2alf(double tau, double tau_min, double tau_max)
{
   return tau;

   double diff = tau_max - tau_min;
   return tan( PI*(tau-tau_min)/diff - halfPI );
}

double alf2tau(double alf, double tau_min, double tau_max)
{
   return alf;

   double diff = tau_max - tau_min;
   return invPI*diff*( atan(alf) + halfPI ) + tau_min;
}

double d_tau_d_alf(double tau, double tau_min, double tau_max)
{
   return 1;

   double alf = tau2alf(tau,tau_min,tau_max);
   double diff = tau_max - tau_min;
   return invPI*diff/(alf*alf+1);
}
*/
double beta2alf(double beta)
{
   return beta; //log(beta);
}

double alf2beta(double alf)
{
   return alf; //exp(alf);
}

double d_beta_d_alf(double beta)
{
   return 1; //beta;
}



double kappa_spacer(double tau2, double tau1)
{
   double diff_max = 40;
   double spacer = 400;

   double diff = tau2 - tau1 + spacer;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double kappa_lim(double tau)
{
   double diff_max = 40;
   double tau_min = 50;

   double diff = - tau + tau_min;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double d_kappa_d_tau(double tau2, double tau1)
{
   double kappa_diff_max = 40;
   double kappa_fact = 2;

   double diff = (tau2 - (tau1 + 200)) * kappa_fact;
   diff = diff > kappa_diff_max ? kappa_diff_max : diff;
   double d = kappa_fact * exp(diff); 
   if (d > 100)
      d = d;
   return d;
}

void updatestatus_(int* gc_int, int* thread, int* iter, double* chi2, int* terminate)
{
   FLIMGlobalFitController* gc= (FLIMGlobalFitController*) gc_int;
   int t = gc->status->UpdateStatus(*thread, -1, *iter, *chi2);
   *terminate = t;
}


/* ============================================================== */
int ada(int *s, int *lp1, int *nl, int *n, int *nmax, int *ndim, 
        int *pp2, double *a, double *b, double *kap, int *inc, 
        double *t, double *alf, int *isel, int *gc_int, int *thread)
{   
   FILE* fx;

   FLIMGlobalFitController *gc = (FLIMGlobalFitController*) gc_int;

   if (gc == NULL)
      return -1;

   int i,j,k, d_offset, total_n_exp, idx;
   int a_col, inc_row, inc_col, n_exp_col, cur_col;
   
   double ref_lifetime;

   int S    = *s;
   int N    = *n;
   int Ndim = *ndim;

   
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

    
   double t0;

   int n_meas = N;
                               
   double *exp_buf = gc->exp_buf + *thread * gc->n_decay_group * gc->exp_buf_size;
   double *tau_buf = gc->tau_buf + *thread * gc->n_exp * (gc->n_fret + 1);
   double *beta_buf = gc->beta_buf + *thread * gc->n_exp;
   double *theta_buf = gc->theta_buf + *thread * gc->n_theta;
   double *w = gc->w + *thread * N;
   double *y = gc->y + *thread * N * (S+1);

   int locked_param = -1;//gc->locked_param[*thread];
   double locked_value = 0;//gc->locked_value[*thread];

   
   if ( gc->fit_t0 )
      t0 = alf[gc->alf_t0_idx];
   else
      t0 = gc->t0_guess;

   if (gc->ref_reconvolution == FIT_GLOBALLY)
      ref_lifetime = alf[gc->alf_ref_idx];
   else
      ref_lifetime = gc->ref_lifetime_guess;

   total_n_exp = gc->n_exp * gc->n_decay_group;
        

   int* resample_idx = gc->data->GetResampleIdx(*thread);
      
   switch(*isel)
   {
      case 1:
         
         // Make sure two threads don't try to set up INC
         // - it's shared between all threads!
         
         if (gc->first_call)
         {
            gc->mutex.lock();

            if (gc->first_call)
            {


               // Set up incidence matrix
               //----------------------------------------------------------------------

               inc_row = 0;   // each row represents a non-linear variable
               inc_col = 0;   // each column represents a phi, eg. exp(...)

               // Set incidence matrix zero
               for(i=0; i<96; i++)
                  inc[i] = 0;

      
               // Set inc for local offset if required
               // Independent of all variables
               if( gc->fit_offset == FIT_LOCALLY )
                  inc_col++;

               // Set inc for local scatter if required
               // Independent of all variables
               if( gc->fit_scatter == FIT_LOCALLY )
                  inc_col++;

               if( gc->fit_tvb == FIT_LOCALLY )
                  inc_col++;
            
               // Set diagonal elements of incidence matrix for variable tau's   
               n_exp_col = gc->beta_global ? 1 : gc->n_exp;
               for(i=gc->n_fix; i<gc->n_exp; i++)
               {
                  cur_col = gc->beta_global ? 0 : i;
                  for(j=0; j<(gc->n_pol_group*gc->n_decay_group); j++)
                     inc[inc_row + (inc_col+j*gc->n_exp_phi+cur_col)*12] = 1;
                                
                  //kappa derivative
                  //if (i>0 && gc->use_kappa)
                  //   inc[inc_row + gc->l * 12] = 1;

                  inc_row++;
               }

               // Set diagonal elements of incidence matrix for variable beta's   
               for(i=0; i<gc->n_beta; i++)
               {
                  for(j=0; j<(gc->n_pol_group*gc->n_decay_group); j++)
                     inc[inc_row + (inc_col+j*gc->n_exp_phi)*12] = 1;
                                
                  inc_row++;
               }

               for(i=0; i<gc->n_theta_v; i++)
               {
                  inc[inc_row+(inc_col+i+1+gc->n_theta_fix)*12] = 1;
                  inc_row++;
               }
         
               // Set elements of incidence matrix for E derivatives
               for(i=0; i<gc->n_fret_v; i++)
               {
                  for(j=0; j<gc->n_exp_phi; j++)
                     inc[inc_row+(gc->inc_donor+gc->n_fret_fix+inc_col+i*gc->n_exp_phi+j)*12] = 1;
                  inc_row++;
               }

               if (gc->ref_reconvolution == FIT_GLOBALLY)
               {
                  // Set elements of inc for ref lifetime derivatives
                  for(i=0; i<( gc->n_pol_group* gc->n_decay_group * gc->n_exp_phi ); i++)
                  {
                     inc[inc_row+(inc_col+i)*12] = 1;
                  }
                  inc_row++;
               }

               /*
               // Set inc elements for t0 if required
               if( gc->fit_t0 )
               {
                  for(i=0; i<gc->n_exp; i++)
                        inc[inc_row+(inc_col+i)*12] = 1;
                  inc_row++;
               }
               */

               inc_col += gc->n_pol_group * gc->n_decay_group * gc->n_exp_phi;
              
               // Both global offset and scatter are in col L+1

               if( gc->fit_offset == FIT_GLOBALLY )
               {
                  inc[inc_row + inc_col*12] = 1;
                  inc_row++;
               }

               if( gc->fit_scatter == FIT_GLOBALLY )
               {
                  inc[inc_row + inc_col*12] = 1;
                  inc_row++;
               }

               if( gc->fit_tvb == FIT_GLOBALLY )
               {
                  inc[inc_row + inc_col*12] = 1;
                  inc_row++;
               }

               gc->first_call = false;
            }

              gc->mutex.unlock();  
         }

         // Set constant phi values
         //----------------------------
         a_col = 0;
         
         // set constant phi value for offset
         if( gc->fit_offset == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[N*a_col+i]=0;
            idx = 0;
            for(k=0; k<gc->n_chan; k++)
            {
               for(i=0; i<gc->n_t; i++)
               {
                  a[idx+N*a_col] += 1;
                  idx += resample_idx[i];
               }
               idx++;
            }
            a_col++;
         }

         // set constant phi value for scatterer
         if( gc->fit_scatter == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[N*a_col+i]=0;
            sample_irf(*thread, gc, a+N*a_col,gc->n_r,scale_fact);
            a_col++;
         }

         // set constant phi value for tvb
         if( gc->fit_tvb == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[N*a_col+i]=0;
            idx = 0;
            for(k=0; k<gc->n_chan; k++)
            {
               for(i=0; i<gc->n_t; i++)
               {
                  a[idx+N*a_col] += gc->tvb_profile[k*gc->n_t+i] * alf[gc->alf_tvb_idx];
                  idx += resample_idx[i];
               }
               idx++;
            }
            a_col++;
         }

      case 2:

         if (locked_param >= 0)
            alf[locked_param] = locked_value;

         a_col = (gc->fit_offset == FIT_LOCALLY) + (gc->fit_scatter == FIT_LOCALLY) + (gc->fit_tvb == FIT_LOCALLY);
         

         // Set tau's
         for(j=0; j<gc->n_fix; j++)
            tau_buf[j] = gc->tau_guess[j];
         for(j=0; j<gc->n_v; j++)
            tau_buf[j+gc->n_fix] = InverseTransformRange(alf[j],gc->tau_min[j+gc->n_fix],gc->tau_max[j+gc->n_fix]);

         // Set theta's
         for(j=0; j<gc->n_theta_fix; j++)
            theta_buf[j] = gc->theta_guess[j];
         for(j=0; j<gc->n_theta_v; j++)
            theta_buf[j+gc->n_theta_fix] = InverseTransformRange(alf[gc->alf_theta_idx+j],0,1000000);


         // Set beta's
         if (gc->fit_beta == FIT_GLOBALLY)
         {
            alf2beta(gc->n_exp,alf+gc->alf_beta_idx,beta_buf);
         }
         else if (gc->fit_beta == FIX) 
         {
            for(j=0; j<gc->n_exp; j++)
               beta_buf[j] = gc->fixed_beta[j];
         }
         
         // Set tau's for FRET
         idx = gc->n_exp;
         for(i=0; i<gc->n_fret; i++)
         {
            double E;
            if (i<gc->n_fret_fix)
               E = gc->E_guess[i];
            else
               E = alf[gc->alf_E_idx+i-gc->n_fret_fix]; //alf[gc->alf_E_idx+i-gc->n_fret_fix];

            for(j=0; j<gc->n_exp; j++)
               tau_buf[idx++] = tau_buf[j] * (1-E);
         }

         // Precalculate exponentials
         gc->calculate_exponentials(*thread, tau_buf, theta_buf);

         a_col += gc->flim_model(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, *isel == 1, a+a_col*N);


         // Set L+1 phi value (without associated beta), to include global offset/scatter
         //----------------------------------------------
         
         for(i=0; i<N; i++)
            a[ i + N*a_col ] = 0;
            
         // Add scatter
         if (gc->fit_scatter == FIT_GLOBALLY)
         {
            sample_irf(*thread, gc, a+N*a_col,gc->n_r,scale_fact);
            for(i=0; i<N; i++)
               a[ i + N*a_col ] = a[ i + N*a_col ] * alf[gc->alf_scatter_idx];
         }

         // Add tvb
         if (gc->fit_tvb == FIT_GLOBALLY)
         {
            idx = 0;
            for(k=0; k<gc->n_chan; k++)
            {
               for(i=0; i<gc->n_t; i++)
               {
                  a[idx+N*a_col] += gc->tvb_profile[k*gc->n_t+i] * alf[gc->alf_tvb_idx];
                  idx += resample_idx[i];
               }
               idx++;
            }
         }

         if (gc->use_kappa && kap != NULL)
         {
            kap[0] = 0;
            for(i=1; i<gc->n_v; i++)
               kap[0] += kappa_spacer(tau_buf[gc->n_fix+i],tau_buf[gc->n_fix+i-1]);
            for(i=0; i<gc->n_v; i++)
               kap[0] += kappa_lim(tau_buf[gc->n_fix+i]);
         }

         // Add offset
         
         if (gc->fit_offset == FIT_GLOBALLY)
         {
            idx = 0;
            for(k=0; k<gc->n_chan; k++)
            {
               for(i=0; i<gc->n_t; i++)
               {
                  a[idx+N*a_col] += alf[gc->alf_offset_idx];
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
         /*
         if (gc->l==1 && gc->y != NULL)
         {
            double wt = 0;
            double yt = 0;
            double at = 0;
            for(i=0; i<N; i++)
            {
               at += a[i];
               w[i] = 1/a[i];
               yt += y[i];
               wt += w[i];
            }
            for(i=0; i<N; i++)
            {
               w[i] *= ((at/yt) / 10000);
            }

         }
         */

/*
         if (gc->anscombe_tranform)
         {
            memcpy(a_cpy,a,n_meas*(gc->l+1)*sizeof(double));
            for(i=0; i<N; i++)
               a[i] = anscombe(a[i]);
         }
*/
         
         if (*isel==2 || gc->getting_fit)
            break;
      
      case 3:    
      
         int col = 0;
         
         col += gc->tau_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);
         
         if (gc->fit_beta == FIT_GLOBALLY)
            col += gc->beta_derivatives(*thread, tau_buf, alf+gc->alf_beta_idx, theta_buf, ref_lifetime, b+col*Ndim);
         
         col += gc->E_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);
         col += gc->theta_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);

         if (gc->ref_reconvolution == FIT_GLOBALLY)
            col += gc->ref_lifetime_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);

            /*
         if (gc->anscombe_tranform)
            for(j=0; j<col; j++)
               for(i=0; i<N; i++)
                  b[i+j*Ndim] *= anscombe_diff(a_cpy[i]);
              */    
                  
         /*
         FILE* fx = fopen("c:\\users\\scw09\\Documents\\dump-b.txt","w");
         if (fx!=NULL)
         {
            for(j=0; j<n_meas; j++)
            {
               for(i=0; i<col; i++)
               {
                  fprintf(fx,"%f\t",b[i*Ndim+j]);
               }
               fprintf(fx,"\n");
            }
            fclose(fx);
         }
         */


         d_offset = Ndim * col;

          // Set derivatives for offset 
         if(gc->fit_offset == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            idx = 0;
            for(k=0; k<gc->n_chan; k++)
            {
               for(i=0; i<gc->n_t; i++)
               {
                  b[d_offset + idx] += 1;
                  idx += resample_idx[i];
               }
               idx++;
            }
            d_offset += Ndim;
         }
         
         // Set derivatives for scatter 
         if(gc->fit_scatter == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            sample_irf(*thread, gc, b+d_offset,gc->n_r,scale_fact);
            d_offset += Ndim;
         }

         // Set derivatives for tvb 
         if(gc->fit_tvb == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            idx = 0;
            for(k=0; k<gc->n_chan; k++)
            {
               for(i=0; i<gc->n_t; i++)
               {
                  b[ d_offset + idx ] += gc->tvb_profile[k*gc->n_t+i];
                  idx += resample_idx[i];
               }
               idx++;
            }
            d_offset += Ndim;
         }

         if (gc->use_kappa && kap != NULL)
         {
            
            for(i=0; i<gc->n_v; i++)
            {
               kap[ i + 1 ] = -kappa_lim(tau_buf[gc->n_fix+i]);
               if (i<gc->n_v-1)
                  kap[ i + 1 ] += kappa_spacer(tau_buf[gc->n_fix+i+1],tau_buf[gc->n_fix+i]);
               if (i>0)
                  kap[ i + 1 ] -= kappa_spacer(tau_buf[gc->n_fix+i],tau_buf[gc->n_fix+i-1]);
            }
            for(i=i; i<*nl; i++)
            {
               kap[i+1] = 0;
            }
            
         }

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
                     b[ (count+i_inc)*Ndim + j ] *= 1e-10;
                  i_inc++;
               }
            }
         }
   }
   
   return 0;
}
