#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"
#include "util.h"

#ifndef NO_OMP   
#include <omp.h>
#endif

using namespace boost::interprocess;

#include "TrimmedMean.h"

void CalculateRegionStats(int n, int s, float data[], float region_mean[], float region_std[])
{
   for(int i=0; i<n; i++)
   {
      int K = 0.01 * s;
      TrimmedMean(data+i, n, s, K, region_mean[i], region_std[i]);
   }
}


int FLIMGlobalFitController::ProcessNonLinearParams(int n, int n_px, int loc[], double alf[], float tau[], float beta[], float E[], float theta[], float offset[], float scatter[], float tvb[], float ref_lifetime[])
{

   #pragma omp parallel for
   for(int i=0; i<n; i++)
   {
      int j;
      double* alfl = alf + i*nl;
      if (tau != NULL)
      {
         for(j=0; j<n_fix; j++)
            tau[ j*n_px + loc[i] ] = tau_guess[j];
         for(j=0; j<n_v; j++)
            tau[ (j+n_fix)*n_px + loc[i] ] = alfl[j];
      }

      if (beta != NULL && beta_global)
      {
         if (fit_beta == FIX)
         {
            for(j=0; j<n_exp; j++)
               beta[ j*n_px + loc[i] ] = fixed_beta[j];
         }
         else
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
               alf2beta(n_group,alfl+alf_beta_idx+group_start-d,beta_buf+group_start);
               
               group_start = group_end;

            }

            double norm = 0;
            for(j=0; j<n_exp; j++)
               norm += beta_buf[j];

            for(j=0; j<n_exp; j++)
               beta[ j*n_px + loc[i] ] = beta_buf[j];// / norm;
         }
      }

      if (theta != NULL)
      {
         for(j=0; j<n_theta_fix; j++)
            theta[ j*n_px + loc[i] ] =  theta_guess[ j ];
         for(j=0; j<n_theta_v; j++)
            theta[ (j + n_theta_fix)*n_px + loc[i] ] = alfl[alf_theta_idx + j];
      }

      if (E != NULL)
      {
         for(j=0; j<n_fret_fix; j++)
            E[ j*n_px + loc[i] ] = E_guess[j];
         for(j=0; j<n_fret_v; j++)
            E[ (j + n_fret_fix)*n_px + loc[i] ] = alfl[alf_E_idx+j];
      }

      if (offset != NULL && fit_offset == FIT_GLOBALLY)
         offset[ loc[i] ] = alfl[alf_offset_idx];

      if (scatter != NULL && fit_scatter == FIT_GLOBALLY)
         scatter[ loc[i] ] = alfl[alf_scatter_idx];

      if (tvb != NULL && fit_tvb == FIT_GLOBALLY)
         tvb[ loc[i] ] = alfl[alf_tvb_idx];

      if (ref_lifetime != NULL && ref_reconvolution == FIT_GLOBALLY)
         ref_lifetime[ loc[i] ] = alfl[alf_ref_idx];
   
   }

   return 0;
}

#define GET_PARAM(param,n,p)  if (p < n) return (param)[p]; else (p-=n)

float FLIMGlobalFitController::GetNonLinearParam(int param, float alf[])
{
   int p = param;

   GET_PARAM(tau_guess,n_fix,p);
   GET_PARAM(alf,n_v,p);

   if (beta_global)
   {
      if (fit_beta == FIX)
      {
         GET_PARAM(fixed_beta,n_exp,p);
      }
      else
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
            alf2beta(n_group,alf+alf_beta_idx+group_start-d,beta_buf+group_start);
               
            group_start = group_end;

         }

         double norm = 0;
         for(int j=0; j<n_exp; j++)
            norm += beta_buf[j];

         GET_PARAM(beta_buf,n_exp,p);
      }
   }

   GET_PARAM(theta_guess,n_theta_fix,p);
   GET_PARAM(alf+alf_theta_idx,n_theta_v,p);

   GET_PARAM(E_guess,n_fret_fix,p);
   GET_PARAM(alf+alf_E_idx,n_fret_v,p);

   if (fit_offset == FIT_GLOBALLY)
      GET_PARAM(alf+alf_offset_idx,1,p);
   
   if (fit_scatter == FIT_GLOBALLY)
      GET_PARAM(alf+alf_scatter_idx,1,p);
      
   if (fit_tvb == FIT_GLOBALLY)
      GET_PARAM(alf+alf_tvb_idx,1,p);
   
   if (ref_reconvolution == FIT_GLOBALLY)
      GET_PARAM(alf+alf_ref_idx,1,p);

   float nan;
   SetNaN(&nan,1);
   return nan;
}


int FLIMGlobalFitController::ProcessNonLinearParams(float alf[], float output[])
{
   int idx = 0;

   int j;

   for(j=0; j<n_fix; j++)
      output[idx++] = tau_guess[j];
   for(j=0; j<n_v; j++)
      output[idx++] = alf[j];

   if (beta_global)
   {
      if (fit_beta == FIX)
      {
         for(j=0; j<n_exp; j++)
            output[idx++] = fixed_beta[j];
      }
      else
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
            alf2beta(n_group,alf+alf_beta_idx+group_start-d,beta_buf+group_start);
               
            group_start = group_end;

         }

         double norm = 0;
         for(j=0; j<n_exp; j++)
            norm += beta_buf[j];

         for(j=0; j<n_exp; j++)
            output[idx++] = beta_buf[j];// / norm;
      }
   }


   for(j=0; j<n_theta_fix; j++)
      output[idx++] =  theta_guess[ j ];
   for(j=0; j<n_theta_v; j++)
      output[idx++] = alf[alf_theta_idx + j];

   for(j=0; j<n_fret_fix; j++)
      output[idx++] = E_guess[j];
   for(j=0; j<n_fret_v; j++)
      output[idx++] = alf[alf_E_idx+j];


   if (fit_offset == FIT_GLOBALLY)
      output[idx++] = alf[alf_offset_idx];

   if (fit_scatter == FIT_GLOBALLY)
      output[idx++] = alf[alf_scatter_idx];

   if (fit_tvb == FIT_GLOBALLY)
      output[idx++] = alf[alf_tvb_idx];

   if (ref_reconvolution == FIT_GLOBALLY)
      output[idx++] = alf[alf_ref_idx];

   return idx;
}




int FLIMGlobalFitController::ProcessLinearParams(int s, int n_px, int loc[], float lin_params[], float chi2_group[], 
            float I0[], float beta[], float gamma[], float r[], float offset[], float scatter[], float tvb[], float chi2[])
{

   int lin_idx = 0;

   if (chi2 != NULL)
   {
      #pragma omp parallel for
      for(int i=0; i<s; i++)
         chi2[ loc[i] ] = chi2_group[ i ];
   }

   if (offset != NULL && fit_offset == FIT_LOCALLY)
   {
      #pragma omp parallel for
      for(int i=0; i<s; i++)
         offset[ loc[i] ] = lin_params[ i*l + lin_idx ];
      lin_idx++;
   }

   if (scatter != NULL && fit_scatter == FIT_LOCALLY)
   {
      #pragma omp parallel for
      for(int i=0; i<s; i++)
         scatter[ loc[i] ] = lin_params[ i*l + lin_idx ];
      lin_idx++;
   }

   if (tvb != NULL && fit_tvb == FIT_LOCALLY)
   {
      for(int i=0; i<s; i++)
         tvb[ loc[i] ] = lin_params[ i*l + lin_idx ];
      lin_idx++;
   }

   if (I0 != NULL)
   {
      if (polarisation_resolved)
      {
         #pragma omp parallel for
         for(int i=0; i<s; i++)
         {
            I0[ loc[i] ] = lin_params[ i*l + lin_idx ];
            
            if (r != NULL)
               for(int j=0; j<n_r; j++)
                  r[ j*n_px + loc[i] ] = lin_params[ i*l + j + lin_idx + 1 ] / I0[ loc[i] ];

         }
      }
      else if (fit_fret)
      {
         #pragma omp parallel for
         for(int i=0; i<s; i++)
         {
            I0[ loc[i] ] = 0;
            for(int j=0; j<n_fret_group; j++)
               I0[ loc[i] ] += lin_params[ i*l + j + lin_idx ];

            if (gamma != NULL)
               for (int j=0; j<n_fret_group; j++)
                  gamma[ j*n_px + loc[i] ] = lin_params[ i*l + lin_idx + j] / I0[ loc[i] ];

         }
      }
      else if (!beta_global)
      {
         #pragma omp parallel for
         for(int i=0; i<s; i++)
         {
            I0[ loc[i] ] = 0;
            for(int j=0; j<n_exp_phi; j++)
               I0[ loc[i] ] += lin_params[ i*l + j + lin_idx ];

            if (beta != NULL)
               for(int j=0; j<n_exp_phi; j++)
                  beta[ j*n_px + loc[i] ] = lin_params[ i*l + j + lin_idx] / I0[ loc[i] ];

         }
      }
      else
      {
         #pragma omp parallel for
         for(int i=0; i<s; i++)
         {
            I0[ loc[i] ] = 0;
            for(int j=0; j<n_exp_phi; j++)
               I0[ loc[i] ] += lin_params[ i*l + j + lin_idx ];

            if (gamma != NULL)
               for(int j=0; j<n_exp_phi; j++)
                  gamma[ j*n_px + loc[i] ] = lin_params[ i*l + j + lin_idx] / I0[ loc[i] ];
         }
      }

      // While this deviates from the definition of I0 in the model, it is closer to the intuitive 'I0', i.e. the peak of the decay
/*
      #pragma omp parallel for
      for(int i=0; i<s; i++)
         I0[ loc[i] ] *= t_g;  
         */
//      if (ref_reconvolution)
//         I0[ g*n_px + i ] /= ref;   // accounts for the amplitude of the reference in the model, since we've normalised the IRF to 1
   }
   return 0;
}

/*
double FLIMGlobalFitController::CalculateChi2(int s, int n_meas_res, float y[], double a[], float lin_params[], float adjust_buf[], double fit_buf[], float chi2[])
{
   double chi2_tot = 0;

   #pragma omp parallel for reduction(+:chi2_tot)
   for(int i=0; i<s; i++)
   {
      for(int j=0; j<n_meas_res; j++)
      {
         double wj, yj, ft;
         ft = 0;
         for(int k=0; k<l; k++)
            ft += a[n_meas_res*k+j] * lin_params[ i*l + k ];

         ft += a[n_meas_res*l+j];

         yj = y[i*n_meas_res + j] + adjust_buf[j];

         if ( yj == 0 )
            wj = 1;
         else  
            wj = 1/fabs(yj);
         

         fit_buf[j] = (ft - y[i*n_meas_res + j] ) ;
         fit_buf[j] *= fit_buf[j] * data->smoothing_area * wj;  // account for averaging while smoothing

         if (j>0)
            fit_buf[j] += fit_buf[j-1];
      }

      if (chi2 != NULL)
      {
         chi2[i] = fit_buf[n_meas_res-1] / (n_meas_res - nl/s - l);
      }

      chi2_tot += fit_buf[n_meas_res-1];

   }

   return chi2_tot;

}
*/

// calculate errors: 
/*
int calculate_errs, double tau_err[], double beta_err[], double E_err[], double theta_err[],
                     double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[]
                     */


int FLIMGlobalFitController::GetAverageImageResults(int im, uint8_t ret_mask[], int& n_regions, int regions[], int region_size[], float params_mean[], float params_std[])
{
   int start, s_local;
   int r_idx;

   int n_px = data->n_px;

   int thread = 0;

   // Get mask
   uint8_t *im_mask = data->mask + im*n_px;  
   
   if (ret_mask)
      memcpy(ret_mask, im_mask, n_px * sizeof(uint8_t));

   int iml = data->GetImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;

   float* nl_output;
   if (data->global_mode == MODE_PIXELWISE)
      nl_output = new float[ n_nl_output_params * n_px ];
   else
      nl_output = NULL;

   float *alf_group, *lin_group, *chi2_group, *I_group;
   int *ierr_group; 
   
   
   #ifndef NO_OMP
   omp_set_num_threads(n_thread);
   #endif
   
   int idx = 0;
   for(int rg=1; rg<MAX_REGION; rg++)
   {
      r_idx = data->GetRegionIndex(im, rg);

      if (r_idx > -1)
      {
         start = data->GetRegionPos(im,rg);
         s_local   = data->GetRegionCount(im,rg);

         regions[idx] = rg;
         region_size[idx] = s_local;
         
         int n_output = 0;

         if (data->global_mode == MODE_PIXELWISE)
         {
            alf_group = alf + start * nl; 

            for(int i=0; i<s_local; i++)
               ProcessNonLinearParams(alf_group + i*nl, nl_output + i*n_nl_output_params);

            CalculateRegionStats(n_nl_output_params, s_local, nl_output, params_mean, params_std);
         }
         else
         {
            alf_group = alf + nl * r_idx;
            ProcessNonLinearParams(alf_group,params_mean);
         }

         params_mean += n_nl_output_params;
         params_std  += n_nl_output_params; 

         lin_group    = lin_params + start * lmax;
         chi2_group   = chi2       + start;
         I_group      = I          + start;

         CalculateRegionStats(lmax, s_local, lin_group, params_mean, params_std);

         params_mean += lmax;
         params_std  += lmax; 

         CalculateRegionStats(1, s_local, I_group, params_mean, params_std);

         params_mean += 1;
         params_std  += 1; 

         CalculateRegionStats(1, s_local, chi2_group, params_mean, params_std);

         params_mean += 1;
         params_std  += 1;
         
         idx++;
      }
   }

   n_regions = idx;

   ClearVariable(nl_output);

   return 0;

}


int FLIMGlobalFitController::GetImage(int im, int param, uint8_t ret_mask[], float image_data[])
{
   int start, s_local;
   int r_idx;

   int n_px =  data->n_px;

   float* param_data;
   int span;

   int thread = 0;

   if (param >= n_output_params || param < 0)
      return -1;

   // Get mask
   uint8_t *im_mask = data->mask + im*n_px;  
   
   if (ret_mask)
      memcpy(ret_mask, im_mask, n_px * sizeof(uint8_t));

   int iml = data->GetImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;

   SetNaN(image_data, n_px);

   int idx = 0;
   for(int rg=1; rg<MAX_REGION; rg++)
   {
      r_idx = data->GetRegionIndex(im, rg);

      if (r_idx > -1)
      {         
         start = data->GetRegionPos(im,rg);
         s_local   = data->GetRegionCount(im,rg);

         if (param < n_nl_output_params)
         {
            if (data->global_mode == MODE_PIXELWISE)
            {
               param_data = alf + start * nl;
               
               int j = 0;
               for(int i=0; i<n_px; i++)
                  if(im_mask[i] == rg)
                     image_data[i] = GetNonLinearParam(param, param_data + i*nl) ;

            }
            else
            {
               param_data = alf + r_idx * nl;
               float p = GetNonLinearParam(param, param_data);
               
               int j = 0;
               for(int i=0; i<n_px; i++)
                  if(im_mask[i] == rg)
                     image_data[i] = p;

            }
         }
         else
         {
            if (param == n_output_params -1) // chi2
            {
               param_data = chi2 + start;
               span = 1;
            }
            if (param == n_output_params -2) // I0
            {
               param_data = I + start;
               span = 1;
            }
            else
            {
               param_data = lin_params + start * lmax + param - n_nl_output_params;
               span = lmax;
            }
         
            int j = 0;
            for(int i=0; i<n_px; i++)
               if(im_mask[i] == rg)
                  image_data[i] = param_data[span*(j++)];
          }

      }
   }

   return 0;
}


int FLIMGlobalFitController::GetImageResults(int im, uint8_t ret_mask[], float chi2[], float tau[], float I0[], float beta[], float E[], 
           float gamma[], float theta[], float r[], float t0[], float offset[], float scatter[], float tvb[], float ref_lifetime[])
{
return 0;
/*
   int thread = 0;

   int s0 = 0;

   int n_px = data->n_px;;

   int n_p = data->n_px;

   uint8_t *im_mask = data->mask + im*n_px;  
   
   if (ret_mask)
      for(int i=0; i<n_px; i++)
         ret_mask[i] = im_mask[i];


   int iml = data->GetImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;



   uint8_t *mask = data->mask;
   int group;
   int r_idx, r_min, r_max, ri;
   //int s;

   int *loc = new int[n_px]; //ok
   float *alf_group;
   float *lin_group, *chi2_group;
   int *ierr_group; 
   
   
   #ifndef NO_OMP
   omp_set_num_threads(n_thread);
   #endif
   


   // Set default values for regions lying outside of mask
   //------------------------------------------------------
   if (fit_offset == FIT_LOCALLY)
      SetNaN(offset,  n_px);
   if (fit_scatter == FIT_LOCALLY)
      SetNaN(scatter, n_px);
   if (fit_tvb == FIT_LOCALLY)
      SetNaN(tvb,     n_px);
   if (fit_beta == FIT_LOCALLY)
      SetNaN(beta,    n_px*n_exp);

   SetNaN(I0,      n_px);
   SetNaN(r,       n_px*n_r);
   SetNaN(gamma,   n_px*n_fret_group);
   SetNaN(chi2,    n_px);

   if (data->global_mode == MODE_PIXELWISE)
   {
      for(int i=0; i<n_px; i++)
         loc[i] = i;

      ierr_group = ierr + n_px * im;
      chi2_group = this->chi2 + n_px * im;
      alf_group = alf + nl * n_px * im;
      lin_group = lin_params + l * n_px * im;

      ProcessNonLinearParams(n_px, n_px, loc, alf_group, tau, beta, E, theta, offset, scatter, tvb, ref_lifetime);
      ProcessLinearParams(n_px, n_px, loc, lin_group, chi2_group, I0, beta, gamma, r, offset, scatter, tvb, chi2);
   }
   else
   {
      if (data->global_mode == MODE_IMAGEWISE)
         group = iml;
      else
         group = 0;

      r_min = data->GetMinRegion(group);
      r_max = data->GetMaxRegion(group);

      for(int rg=r_min; rg<=r_max; rg++)
      {
         ri = rg-r_min;
         r_idx = data->GetRegionIndex(group, rg);

         int lin_start = 0;

         if (data->global_mode == MODE_GLOBAL)
         {
            lin_start = 0;
            for(int j=0; j<iml; j++)
               lin_start += data->region_count[j*MAX_REGION+rg];
         }

         int ii = 0;
         for(int i=0; i<n_px; i++)
            if(im_mask[i] == rg)
               loc[ii++] = i;
         int s_local = ii;

         int n_p = data->n_px;

         alf_group  = alf + nl * r_idx;
         lin_group  = lin_params + l * (s * r_idx + lin_start);
         chi2_group = chi2 + s * r_idx + lin_start;

         ProcessNonLinearParams(1, 1, &s0, alf_group, tau+ri*n_exp, beta+ri*n_exp, E+ri*n_fret, theta+ri*n_theta, offset+ri, scatter+ri, tvb+ri, ref_lifetime+ri);
         ProcessLinearParams(s_local, n_px, loc, lin_group, chi2_group, I0, beta, gamma, r, offset, scatter, tvb, chi2);

      }
   }

   delete[] loc;

   return 0;
   */
}



/*===============================================
  GetFit
  ===============================================*/

int FLIMGlobalFitController::GetFit(int im, int n_t, double t[], int n_fit, int fit_loc[], double fit[])
{
return 0;
/*
   if (!status->HasFit())
      return ERR_FIT_IN_PROGRESS;

   int n_px = data->n_px;;

   uint8_t* mask = data->mask + im*n_px;

   int iml = data->GetImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;
   
   int thread = 0;

   int group, lin_idx, idx, last_idx;
   int r_idx, r_min, r_max;

   float *alf_group;
   float *lin_group;

   int n_t_buf = this->n_t;
   double* t_buf = this->t;
   
   this->n_t = n_t;
   this->n_meas = n_t*n_chan;
   this->n = n_meas;
   this->nmax = this->n_meas;
   this->t = t;

   getting_fit = true;


   SetNaN(fit,n_fit*n_meas);


   if (data->global_mode == MODE_PIXELWISE)
   {
      alf_group = alf + nl * s * iml;
      lin_group = lin_params + l * s * iml;

      for(int i=0; i<n_fit; i++)
      {
         idx = fit_loc[i];
         if (mask[idx] > 0)
            projectors[0].GetFit(idx, alf_group + idx*nl, lin_params + idx*l, adjust_buf, data->counts_per_photon, fit+n_meas*i);
      }

   }
   else
   {
      //local_irf[thread] = irf_buf;

      if (data->global_mode == MODE_IMAGEWISE)
         group = iml;
      else
         group = 0;

      r_min = data->GetMinRegion(group);
      r_max = data->GetMaxRegion(group);

      int idx = 0;
      for(int rg=r_min; rg<=r_max; rg++)
      {

        int lin_start = 0;
   
         if (data->global_mode == MODE_GLOBAL)
         {
            for(int j=0; j<iml; j++)
               lin_start += data->region_count[j*MAX_REGION+rg];
         }

         r_idx = data->GetRegionIndex(group, rg);

         alf_group = alf + nl * r_idx;
         lin_group = lin_params + l * (s * r_idx + lin_start);

         last_idx = 0;
         lin_idx = 0;
         for(int i=0; i<n_fit; i++)
         {
            idx = fit_loc[i];
            if (mask[idx] > 0)
            {
               for(int j=last_idx; j<idx; j++)
                  lin_idx += (mask[j] == rg);
               projectors[0].GetFit(idx, alf_group, lin_group + lin_idx*l, adjust_buf, data->counts_per_photon, fit+n_meas*i);
            }
            last_idx = idx;
         }
     }
   }

   getting_fit = false;

   //ClearVariable(adjust);

   this->n_t = n_t_buf;
   this->n_meas = this->n_t * n_chan;
   this->nmax = n_meas;
   this->t = t_buf;
   this->n = this->n_meas;
   
   return 0;
   */
}
