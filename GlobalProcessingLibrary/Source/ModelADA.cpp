#include "ModelADA.h"
#include "FitStatus.h"
#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"

#define PI        3.141592654
#define halfPI    1.570796327
#define invPI     0.318309886


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

double beta2alf(double beta)
{
   return log(beta);
}

double alf2beta(double alf)
{
   return exp(alf);
}

double d_beta_d_alf(double beta)
{
   return 1; //beta;
}



double kappa(double tau2, double tau1)
{
   double kappa_diff_max = 40;
   double kappa_fact = 2;

   double diff = (tau2 - (tau1 + 200)) * kappa_fact;
   diff = diff > kappa_diff_max ? kappa_diff_max : diff;
   double kappa = exp(diff);
   if (kappa > 100)
      kappa = kappa;
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


double norm_chi2(FLIMGlobalFitController* gc, double chi2, int s, bool fixed_param)
{
   return chi2 * chi2 / (gc->n_meas * s - (gc->nl-(int)fixed_param) - s*gc->l);
}

void updatestatus_(int* gc_int, int* thread, int* iter, double* chi2, int* terminate)
{
   FLIMGlobalFitController* gc= (FLIMGlobalFitController*) gc_int;
   int t = gc->status->UpdateStatus(*thread, -1, *iter, *chi2);
   *terminate = t;
/*   int ret;
   DWORD waitResult = WaitForSingleObject(statusMutex,50);
   if (WAIT_OBJECT_0)
   {
      if (*group >= 0)
         status.group = *group;
      status.iter = *iter;
      status.chi2 = *chi2;

      if (status.callback != 0)
      {
         ret = status.callback(status.group,status.iter,status.chi2);
         if (ret == 0)
            status.terminate = 1;
      }

      *terminate = status.terminate;

         ReleaseMutex(statusMutex);

   }
   else
   {
      terminate = 0;
   }
   */
      
}
/*
int UpdateStatus(int group, int iter, double chi2)
{

      int ret;
      DWORD waitResult = WaitForSingleObject(statusMutex,50);
      if (WAIT_OBJECT_0)
      {
         if (group >= 0)
            status.group = group;
         status.iter = iter;
         status.chi2 = chi2;

         if (status.callback != 0)
         {
            ret = status.callback(status.group,status.iter,status.chi2);
            if (ret == 0)
               status.terminate = 1;
         }

         ReleaseMutex(statusMutex);

         if (status.terminate)
            return 1;
      }

      
      return 0;
}
*/


/* ============================================================== */


int ada(int *s, int *lp1, int *nl, int *n, int *nmax, int *ndim, 
        int *lpp2, int *pp1, int *iv, double *a, double *b, int *inc, 
        double *t, double *alf, int *isel, int *gc_int, int *thread)
{	
   
   FLIMGlobalFitController *gc = (FLIMGlobalFitController*) gc_int;

   if (gc == NULL)
      return -1;
	
//   FILE* fx;

	int i,j,k, d_offset, total_n_exp, idx;
   int a_col, inc_row, inc_col, n_exp_col, cur_col;
   
   double kap, ref_lifetime;

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

   int locked_param = gc->locked_param[*thread];
   double locked_value = gc->locked_value[*thread];

	
	if ( gc->fit_t0 )
		t0 = alf[gc->alf_t0_idx];
	else
		t0 = gc->t0_guess;

   if (gc->ref_reconvolution == FIT_GLOBALLY)
      ref_lifetime = alf[gc->alf_ref_idx];
   else
      ref_lifetime = gc->ref_lifetime_guess;

   total_n_exp = gc->n_exp * gc->n_decay_group;
        
		
	switch(*isel)
	{
		case 1:
			
         // Make sure two threads don't try to set up INC
         // - it's shared between all threads!
         
          //scoped_lock<interprocess_mutex> lock(cleanup_mutex);
          //WaitForSingleObject(gc->mutex,INFINITE); 

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
            n_exp_col = gc->beta_global ? 1 : gc->n_v;
            for(i=0; i<gc->n_v; i++)
		      {
               cur_col = gc->beta_global ? 0 : i;
               for(j=0; j<(gc->n_pol_group*gc->n_decay_group); j++)
                  inc[inc_row + (inc_col+j*gc->n_exp_phi+cur_col)*12] = 1;
                                
               //kappa derivative
               if (i>0 && gc->use_kappa)
                  inc[inc_row + gc->l * 12] = 1;

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
               inc[inc_row+(inc_col+i)*12] = 1;
               inc_row++;
            }
			
            // Set elements of incidence matrix for R derivatives
            for(i=0; i<gc->n_fret_v; i++)
            {
				   for(j=0; j<gc->n_exp_phi; j++)
                  inc[inc_row+(inc_col+i*gc->n_exp_phi+j)*12] = 1;
               inc_row++;
            }

            if (gc->ref_reconvolution == FIT_GLOBALLY)
            {
               // Set elements of inc for ref lifetime derivatives
               for(i=0; i<(gc->n_decay_group * gc->n_exp_phi); i++)
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

            if (gc->n_decay_group > 1)
               inc_col += gc->n_decay_group * gc->n_exp_phi;
              
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
            //ReleaseMutex(gc->mutex);

         // Set constant phi values
         //----------------------------

         a_col = 0;
         
         // set constant phi value for offset
         if( gc->fit_offset == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[ i + N*a_col ] = 1;
            a_col++;
         }

         // set constant phi value for scatterer
         if( gc->fit_scatter == FIT_LOCALLY )
         {
            sample_irf(gc, a+N*a_col,gc->n_r,scale_fact);
            a_col++;
         }

         // set constant phi value for tvb
         if( gc->fit_tvb == FIT_LOCALLY )
         {
            for(i=0; i<N; i++)
               a[ i + N*a_col ] = gc->tvb_profile_buf[i];
            a_col++;
         }

		case 2:

         if (locked_param >= 0)
            alf[locked_param] = locked_value;

         a_col = 0;
         
         if (gc->fit_offset == FIT_LOCALLY)
             a_col++;

         if (gc->fit_scatter == FIT_LOCALLY)
             a_col++;

         if (gc->fit_tvb == FIT_LOCALLY)
             a_col++;
         
         // Set tau's
         for(j=0; j<gc->n_v; j++)
         {
            tau_buf[j] = alf2tau(alf[j],gc->tau_min[j],gc->tau_max[j]);
         }
         for(j=0; j<gc->n_fix; j++)
            tau_buf[j+gc->n_v] = gc->tau_guess[j];

         // Set theta's
         for(j=0; j<gc->n_theta_v; j++)
            theta_buf[j] = alf2tau(alf[gc->alf_theta_idx+j],0,1000000);
         for(j=0; j<gc->n_theta_fix; j++)
            theta_buf[j+gc->n_theta_v] = gc->theta_guess[j];


         // Set beta's
         if (gc->fit_beta == FIT_GLOBALLY)
         {
            for(j=0; j<gc->n_beta; j++)
               beta_buf[j] = alf2tau(alf[gc->alf_beta_idx+j],0,10);
            beta_buf[gc->n_beta] = 1;

			//for(j=0; j<gc->n_beta; j++)
            //   beta_buf[j] = alf2beta(alf[gc->alf_beta_idx+j]);
         }
         else if (gc->fit_beta == FIX) 
         {
            for(j=0; j<gc->n_exp; j++)
               beta_buf[j] = gc->fixed_beta[j];
         }


         // Check we don't have two tau's (exactly) the same
         for(j=0; j<gc->n_v; j++)
            for(k=j+1; k<gc->n_exp; k++)
               if (tau_buf[j]==tau_buf[k])
               {
                  tau_buf[j] += 20;
                  j=0;
                  break;
               }
          
         // Set tau's for FRET
         idx = gc->n_exp;
         for(i=0; i<gc->n_fret; i++)
         {
            double iR6,f;
            if (i<gc->n_fret_fix)
               iR6 = pow(gc->R_guess[i],-6.0);
            else
               iR6 = alf2beta(alf[gc->alf_iR6_idx+i-gc->n_fret_fix]);

            double R = pow(iR6,-1.0/6.0);

            f = 1/( 1 + iR6 );

            for(j=0; j<gc->n_exp; j++)
               tau_buf[idx++] = tau_buf[j] * f; // alf[gc->alf_iR6_idx] = iR6
         }

         // Precalculate exponentials
         calc_exps(gc, gc->n_t, t, total_n_exp, tau_buf+gc->tau_start*gc->n_exp, gc->n_theta, theta_buf, exp_buf);
         
         for(i=0; i<gc->n_decay_group; i++)
            a_col += flim_model(gc, gc->n_t, t, exp_buf+i*gc->exp_buf_size, gc->n_exp, tau_buf+(i+gc->tau_start)*gc->n_exp, beta_buf, gc->n_theta, theta_buf, ref_lifetime, N, a+N*a_col, gc->beta_global);
       

         // Set L+1 phi value (without associated beta), to include global offset/scatter
         //----------------------------------------------

         if (gc->no_linear_exps)
         {
            a_col = 0;
         }
         else
         {
            for(i=0; i<N; i++)
               a[ i + N*a_col ] = 0;
         }
            
         // Add scatter
         if (gc->fit_scatter == FIT_GLOBALLY)
         {
            sample_irf(gc, a+N*a_col,gc->n_r,scale_fact);
            for(i=0; i<N; i++)
               a[ i + N*a_col ] = a[ i + N*a_col ] * alf[gc->alf_scatter_idx];
         }

         // Add tvb
         if (gc->fit_tvb == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               a[ i + N*a_col ] += gc->tvb_profile_buf[i] * alf[gc->alf_tvb_idx];
         }

         if (gc->use_kappa)
         {
            kap = 0;
            for(i=1; i<gc->n_v; i++)
               kap += kappa(tau_buf[gc->n_fix+i],tau_buf[gc->n_fix+i-1]);

            for(i=0; i<N; i++)
                  a[ i + N*a_col ] += kap;
         }

         // Add offset
         if (gc->fit_offset == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               a[ i + N*a_col ] += alf[gc->alf_offset_idx];
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
         
         
         if (*isel==2 || gc->getting_fit)
				break;
		
		case 3: 	
		
         int col = 0;
         
         if (gc->fit_fret == FIT)
            col = flim_fret_model_deriv(gc, gc->n_t, t, exp_buf, tau_buf, beta_buf, ref_lifetime, Ndim, b);
         else
            col = flim_model_deriv(gc, gc->n_t, t, exp_buf, gc->n_v, tau_buf, beta_buf, gc->n_theta, theta_buf, ref_lifetime, Ndim, b);

         col += anisotropy_model_deriv(gc, gc->n_t, t, exp_buf, gc->n_exp, tau_buf, beta_buf, gc->n_theta, theta_buf, ref_lifetime, Ndim, b + col*Ndim);

         if (gc->ref_reconvolution == FIT_GLOBALLY)
            col += ref_lifetime_deriv(gc, gc->n_t, t, exp_buf, gc->n_exp, tau_buf, beta_buf, gc->n_theta, theta_buf, ref_lifetime, Ndim, b + col*Ndim);
            

         /*
         fx = fopen("c:\\users\\scw09\\Documents\\dump-b.txt","w");
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
			      b[ d_offset + i ] = 1;
            d_offset += Ndim;
         }
			
         // Set derivatives for scatter 
         if(gc->fit_scatter == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
               b[d_offset+i]=0;
            sample_irf(gc, b+d_offset,gc->n_r,scale_fact);
            d_offset += Ndim;
         }

         // Set derivatives for tvb 
         if(gc->fit_tvb == FIT_GLOBALLY)
         {
            for(i=0; i<N; i++)
			      b[ d_offset + i ] = gc->tvb_profile_buf[i];
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
                  //i = i;
                  //memset(b+(count+i)*Ndim,0,N*sizeof(double));
            }
         }
   }
   
	return 0;
}
