#include "ModelADA.h"
#include "FitStatus.h"
#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"

#define PI        3.141592654
#define halfPI    1.570796327
#define invPI     0.318309886

#define MIN_LIFETIME 50

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
   double diff_max = 30;
   double spacer = 400;

   double diff = tau2 - tau1 + spacer;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double kappa_lim(double tau)
{
   double diff_max = 30;
   double tau_min = 50;

   double diff = - tau + tau_min;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double d_kappa_d_tau(double tau2, double tau1)
{
   double kappa_diff_max = 30;
   double kappa_fact = 2;

   double diff = (tau2 - (tau1 + 200)) * kappa_fact;
   diff = diff > kappa_diff_max ? kappa_diff_max : diff;
   double d = kappa_fact * exp(diff); 
   return d;
}

void updatestatus_(int* gc_int, int* thread, int* iter, double* chi2, int* terminate)
{
   FLIMGlobalFitController* gc= (FLIMGlobalFitController*) gc_int;
   int t = gc->status->UpdateStatus(*thread, -1, *iter, *chi2);
   *terminate = t;
}


int GenerateDerivMatrix()
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
      for(j=0; j<n_pol_group*n_decay_group; j++)
         inc[inc_row + (inc_col+j*n_exp_phi+cur_col)*12] = 1;

      inc_row++;
   }

   // Set diagonal elements of incidence matrix for variable beta's   
   for(i=0; i<n_beta; i++)
   {
      for(j=0; j<n_pol_group*n_decay_group; j++)
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

int FLIMModel::Funcs(double *alf, double *func, int func_dim double *fjac, int fjac_dim, int mode )
{

   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   if (ref_reconvolution == FIT_GLOBALLY)
      ref_lifetime = alf[gc->alf_ref_idx];
   else
      ref_lifetime = gc->ref_lifetime_guess;

   total_n_exp = gc->n_exp * gc->n_decay_group;
        
   int* resample_idx = gc->data->GetResampleIdx(*thread);
      
   switch(mode)
   {
   case 1:
   //--------------------------------------------
   // Set constant function values
   //--------------------------------------------

      col = 0;
      cur_func = funcs;

      // Offset for fitting locally
      // Add constant value
      //-----------------------------------------
      if( gc->fit_offset == FIT_LOCALLY )
      {
         for(i=0; i<n_meas; i++)
            cur_func[i]=0;
         
         idx = 0;
         for(k=0; k<gc->n_chan; k++)
         {
            for(i=0; i<gc->n_t; i++)
            {
               cur_func[idx] += 1;
               idx += resample_idx[i];
            }
            idx++;
         }
         col++;
         cur_func += dim;
      }

      // Scatter contribution for fitting locally
      // Add IRF contribution
      //-----------------------------------------
      if( fit_scatter == FIT_LOCALLY )
      {
         for(i=0; i<n_meas; i++)
            cur_func[i]=0;

         sample_irf(cur_func, n_r, scale_fact);
         
         col++;
         cur_func += dim;
      }

      // TVB contribution for fitting locally
      // Add sample from TVB
      //-----------------------------------------
      if( fit_tvb == FIT_LOCALLY )
      {
         for(i=0; i<n_meas; i++)
           cur_func[i]=0;

         idx = 0;
         for(k=0; k<gc->n_chan; k++)
         {
            for(i=0; i<gc->n_t; i++)
            {
               cur_func[idx] += tvb_profile[k*gc->n_t+i];
               idx += resample_idx[i];
            }
            idx++;
         }

         col++;
         cur_func += dim;
      }

   case 2:

      if (locked_param >= 0)
         alf[locked_param] = locked_value;

      col = (gc->fit_offset == FIT_LOCALLY)  + 
            (gc->fit_scatter == FIT_LOCALLY) + 
            (gc->fit_tvb == FIT_LOCALLY);
     
      cur_func = funcs[col*dim];

      // Determine lifetimes
      //-----------------------------------
      // Get fixed lifetimes
      idx = 0;
      for(j=0; j<n_fix; j++)
         tau_buf[idx++] = tau_guess[j];

      // Get variable lifetimes
      for(j=0; j<n_v; j++)
      {
         // Apply transformation to keep within range & constrain to prevent overflows 
         tau_buf[idx] = InverseTransformRange(alf[j],gc->tau_min[idx],gc->tau_max[idx]);
         tau_buf[idx] = max(tau_buf[idx],MIN_LIFETIME);
         idx++;
      }

      // Get FRETing lifetimes
      for(i=0; i<n_fret; i++)
      {
         double E;
         if (i<n_fret_fix)
            E = gc->E_guess[i];
         else
            E = alf[gc->alf_E_idx+i-gc->n_fret_fix];

         // Set lifetime for each donor in this fret state
         for(j=0; j<gc->n_exp; j++)
            tau_buf[idx++] = tau_buf[j] * (1-E);
      }

      // Determine correlation times
      //-----------------------------------
      // Get fixed correlation times
      for(j=0; j<n_theta_fix; j++)
         theta_buf[idx] = gc->theta_guess[j];

      // Get variable correlation times
      for(j=0; j<n_theta_v; j++)
      {
         // Apply transformation to keep within range & constrain to prevent overflows 
         theta_buf[j+gc->n_theta_fix] = InverseTransformRange(alf[gc->alf_theta_idx+j],0,1000000);
         theta_buf[j+gc->n_theta_fix] = max(theta_buf[j+gc->n_theta_fix],MIN_LIFETIME);
      }

      // Determine contributions of lifetimes, if global
      //-----------------------------------
      if (gc->fit_beta == FIT_GLOBALLY)
         for(j=0; j<gc->n_exp; j++)
            beta_buf[j] = alf[alf_beta_idx+j];

      if (gc->fit_beta == FIX) 
         for(j=0; j<gc->n_exp; j++)
            beta_buf[j] = gc->fixed_beta[j];
         

      // Precalculate exponentials
      //----------------------------------
      calculate_exponentials(*thread, tau_buf, theta_buf);

      // Add columns for flim model
      //----------------------------------
      col += flim_model(tau_buf, beta_buf, theta_buf, ref_lifetime, mode == 1, cur_func);
      cur_func = col * dim;


      // Set last function (without associated beta), to include global offset/scatter
      //----------------------------------------------
      for(i=0; i<N; i++)
         a[ i + N*a_col ] = 0;
       

      // Add scatter - this needs to be first as we'll scale in place
      if (gc->fit_scatter == FIT_GLOBALLY)
      {
         sample_irf(*thread, gc, a+N*a_col,gc->n_r,scale_fact);
         for(i=0; i<n_meas; i++)
            cur_func[i] *= alf[gc->alf_scatter_idx];
      }

      // Add offset
      if (fit_offset == FIT_GLOBALLY)
      {
         idx = 0;
         for(k=0; k<n_chan; k++)
         {
            for(i=0; i<n_t; i++)
            {
               cur_func[idx] += alf[gc->alf_offset_idx];
               idx += resample_idx[i];
            }
            idx++;
         }
      }

      // Add TVB
      if (fit_tvb == FIT_GLOBALLY)
      {
         idx = 0;
         for(k=0; k<n_chan; k++)
         {
            for(i=0; i<n_t; i++)
            {
               cur_func[idx] += gc->tvb_profile[k*gc->n_t+i] * alf[gc->alf_tvb_idx];
               idx += resample_idx[i];
            }
            idx++;
         }
      }

      // Set Kappa, which we use to impose lifetime contraints
      if (gc->use_kappa && kap != NULL)
      {
         kap[0] = 0;

         // Ensure that lifetimes are increasing
         // This cuts down our parameter space
         for(i=1; i<gc->n_v; i++)
            kap[0] += kappa_spacer(alf[i],alf[i-1]);
         
         // Impose lifetime limits on tau
         for(i=0; i<gc->n_v; i++)
            kap[0] += kappa_lim(alf[i]);
         
         // Impose lifetime limits on theta
         for(i=0; i<gc->n_theta_v; i++)
            kap[0] += kappa_lim(alf[gc->alf_theta_idx+i]);
      }
   }
}




int FLIMModel::Jacobian(double *alf, double *func, int func_dim double *fjac, int fjac_dim, int mode )
{




      case 3:    
      
         int col = 0;
         
         col += gc->tau_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);
         
         if (gc->fit_beta == FIT_GLOBALLY)
            col += gc->beta_derivatives(*thread, tau_buf, alf+gc->alf_beta_idx, theta_buf, ref_lifetime, b+col*Ndim);
         
         col += gc->E_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);
         col += gc->theta_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);

         if (gc->ref_reconvolution == FIT_GLOBALLY)
            col += gc->ref_lifetime_derivatives(*thread, tau_buf, beta_buf, theta_buf, ref_lifetime, b+col*Ndim);
                  
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
            double *kap_derv = kap+1;

            for(i=0; i<*nl; i++)
               kap_derv[i] = 0;

            for(i=0; i<gc->n_v; i++)
            {
               kap_derv[i] = -kappa_lim(tau_buf[gc->n_fix+i]);
               if (i<gc->n_v-1)
                  kap_derv[i] += kappa_spacer(tau_buf[gc->n_fix+i+1],tau_buf[gc->n_fix+i]);
               if (i>0)
                  kap_derv[i] -= kappa_spacer(tau_buf[gc->n_fix+i],tau_buf[gc->n_fix+i-1]);
            }
            for(i=0; i<gc->n_theta_v; i++)
            {
               kap_derv[gc->alf_theta_idx+i] =  -kappa_lim(theta_buf[gc->n_theta_fix+i]);
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


int ada(int *s, int *lp1, int *nl, int *n, int *nmax, int *ndim, 
        int *pp2, double *a, double *b, double *kap, int *inc, 
        double *t, double *alf, int *isel, int *gc_int, int *thread)
{   
   FILE* fx;

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
   float  *w = gc->w + *thread * N;
   float  *y = gc->y + *thread * N * (S+1);

   int locked_param = -1;//gc->locked_param[*thread];
   double locked_value = 0;//gc->locked_value[*thread];

   
   if ( gc->fit_t0 )
      t0 = alf[gc->alf_t0_idx];
   else
      t0 = gc->t0_guess;


}
