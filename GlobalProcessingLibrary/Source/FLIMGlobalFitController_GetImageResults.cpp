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

//
//  Provide routines for getting image results from FitController
//


#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"
#include "util.h"

#include <cmath>
#include <algorithm>

#include <boost/math/special_functions/fpclassify.hpp>

#include "omp_stub.h"

#include "ConcurrencyAnalysis.h"

using namespace boost::interprocess;
#include "TrimmedMean.h"


int CalculateRegionStats(int n, int s, float data[], float intensity[], ImageStats<float>& stats, int region, double conf_factor, float buf[])
{
   using namespace boost::math;

   for(int i=0; i<n; i++)
   {
      int idx = 0;
      for(int j=0; j<s; j++)
      {
         // Only include finite numbers
         if ( isfinite(data[i+j*n]) && isfinite(data[i+j*n]*data[i+j*n]) )
            buf[idx++] = data[i+j*n];
      }
      int K = int (0.05 * idx);
      TrimmedMean(buf, intensity, idx, K, (float) conf_factor, stats, region);
   }
   return n;
}



float FLIMGlobalFitController::GetNonLinearParam(int param, float alf[])
{
   #define GET_PARAM(param,n,p)  {if (p < n) return ((float)(param)[p]); else (p-=n);}

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

   return (float) NaN();
}

int FLIMGlobalFitController::ProcessNonLinearParams(float alf[], float alf_err_lower[], float alf_err_upper[], float param[], float err_lower[], float err_upper[])
{
   #define SET_PARAM(i) {param[idx] = alf[i]; err_lower[idx] = alf_err_lower[i]; err_upper[idx] = alf_err_upper[i]; idx++;}
   #define SET_FIXED(p) {param[idx] = p; err_lower[idx] = NaN(); err_upper[idx] = NaN(); idx++;}

   int idx = 0;

   int j;

   for(j=0; j<n_fix; j++)
      SET_FIXED( (float) tau_guess[j] );
   for(j=0; j<n_v; j++)
      SET_PARAM( j );

   if (beta_global)
   {
      if (fit_beta == FIX)
      {
         for(j=0; j<n_exp; j++)
            SET_FIXED( (float) fixed_beta[j] );
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

         for(j=0; j<n_exp; j++)
            SET_FIXED( (float) beta_buf[j] );
      }
   }


   for(j=0; j<n_theta_fix; j++)
      SET_FIXED( (float) theta_guess[ j ] );
   for(j=0; j<n_theta_v; j++)
      SET_PARAM( alf_theta_idx + j );

   for(j=0; j<n_fret_fix; j++)
      SET_FIXED( (float) E_guess[j] );
   for(j=0; j<n_fret_v; j++)
      SET_PARAM( alf_E_idx+j );


   if (fit_offset == FIT_GLOBALLY)
      SET_PARAM( alf_offset_idx );

   if (fit_scatter == FIT_GLOBALLY)
      SET_PARAM( alf_scatter_idx );

   if (fit_tvb == FIT_GLOBALLY)
      SET_PARAM( alf_tvb_idx );

   if (ref_reconvolution == FIT_GLOBALLY)
      SET_PARAM( alf_ref_idx );

   return idx;
}


int FLIMGlobalFitController::GetImageStats(int& n_regions, int image[], int regions[], int region_size[], float success[], int iterations[], float params[])
{
   INIT_CONCURRENCY;
   
   int n_px = data->n_px;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Calculating Result Statistics");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   ImageStats<float> stats(data->n_output_regions_total, n_output_params, params);

   _ASSERTE( _CrtCheckMemory( ) );

   int buf_size = std::max(n_px, n_nl_output_params);

   float* param_buf_ = new float[buf_size * n_thread];
   float* err_lower_buf_ = new float[buf_size * n_thread];
   float* err_upper_buf_ = new float[buf_size * n_thread];

   float* nl_output_ = NULL;
   float* err_lower_output_ = NULL;
   float* err_upper_output_ = NULL;
   if (data->global_mode == MODE_PIXELWISE)
   {
      nl_output_ = new float[ n_nl_output_params * n_px * n_thread ];
      err_lower_output_ = new float[ n_nl_output_params * n_px * n_thread ];
      err_upper_output_ = new float[ n_nl_output_params * n_px * n_thread ];
   }

   float* nan_buf_ = new float[nl * n_thread];
   SetNaN(nan_buf_, nl * n_thread);

   omp_set_num_threads(n_thread);
   


   #pragma omp parallel for
   for(int im=0; im<data->n_im_used; im++)
   {
      int thread = omp_get_thread_num();

      float *alf_group, *lin_group; 
      float *alf_err_lower_group, *alf_err_upper_group;

      float* param_buf     = param_buf_     + buf_size * thread;
      float* err_lower_buf = err_lower_buf_ + buf_size * thread;
      float* err_upper_buf = err_upper_buf_ + buf_size * thread;

      float* nl_output        = nl_output_        + n_nl_output_params * n_px * thread;
      float* err_lower_output = err_lower_output_ + n_nl_output_params * n_px * thread;
      float* err_upper_output = err_upper_output_ + n_nl_output_params * n_px * thread;

      float* nan_buf = nan_buf_ + nl * thread;

      for(int rg=1; rg<MAX_REGION; rg++)
      {
         int r_idx = data->GetRegionIndex(im, rg);
         int idx = data->GetOutputRegionIndex(im, rg);

         if (r_idx > -1)
         {
         
            int start = data->GetRegionPos(im,rg);
            int s_local   = data->GetRegionCount(im,rg);
            float* intensity = I+start;
         
            image[idx] = data->use_im[im];
            regions[idx] = rg;
            region_size[idx] = s_local;
            iterations[idx] = ierr[r_idx];
            success[idx] = this->success[r_idx];
         
            if (data->global_mode == MODE_PIXELWISE)
               success[idx] /= s_local;
         
            if (data->global_mode == MODE_PIXELWISE)
            {
               alf_group = alf + start * nl; 

               if (calculate_errors)
               {
                  alf_err_lower_group = alf_err_lower + start * nl; 
                  alf_err_upper_group = alf_err_upper + start * nl; 

                  for(int i=0; i<s_local; i++)
                     ProcessNonLinearParams(alf_group + i*nl, alf_err_lower_group + i*nl, alf_err_upper_group + i*nl, 
                                            nl_output + i*n_nl_output_params, err_lower_output + i*n_nl_output_params, err_upper_output + i*n_nl_output_params);
               }
               else
               {

                  for(int i=0; i<s_local; i++)
                     ProcessNonLinearParams(alf_group + i*nl, nan_buf, nan_buf, 
                                            nl_output + i*n_nl_output_params, err_lower_output + i*n_nl_output_params, err_upper_output + i*n_nl_output_params);
               }

               CalculateRegionStats(n_nl_output_params, s_local, nl_output, intensity, stats, idx, conf_factor, param_buf);
            }
            else
            {  
               alf_group = alf + nl * r_idx;
          
            
               if (calculate_errors)
               {
                  alf_err_lower_group = alf_err_lower + nl * r_idx; 
                  alf_err_upper_group = alf_err_upper + nl * r_idx; 
            
                  ProcessNonLinearParams(alf_group, alf_err_lower_group, alf_err_upper_group, 
                                         param_buf, err_lower_buf, err_upper_buf);

                  for(int i=0; i<n_nl_output_params; i++)
                     stats.SetNextParam(idx,param_buf[i],err_lower_buf[i],err_upper_buf[i]);
               }
               else
               {
                  ProcessNonLinearParams(alf_group, nan_buf, nan_buf, 
                                      param_buf, err_lower_buf, err_upper_buf);

                  for(int i=0; i<n_nl_output_params; i++)
                     stats.SetNextParam(idx,param_buf[i]);  
               }
            }

        
            lin_group    = lin_params + start * lmax;

            CalculateRegionStats(lmax, s_local, lin_group, intensity, stats, idx, conf_factor, param_buf);

            CalculateRegionStats(1, s_local, I+start, intensity, stats, idx, conf_factor, param_buf);

            if (data->has_acceptor)
               CalculateRegionStats(1, s_local, acceptor+start, intensity, stats, idx, conf_factor, param_buf);

            if (calculate_mean_lifetimes)
            {
               CalculateRegionStats(1, s_local, mean_tau+start,   intensity, stats, idx, conf_factor, param_buf);         
               CalculateRegionStats(1, s_local, w_mean_tau+start, intensity, stats, idx, conf_factor, param_buf);
            }

           if (polarisation_resolved)
               CalculateRegionStats(1, s_local, r_ss+start, intensity, stats, idx, conf_factor, param_buf);         

            CalculateRegionStats(1, s_local, chi2+start, intensity, stats, idx, conf_factor, param_buf);
         
         }
      }
   }  

   _ASSERTE( _CrtCheckMemory( ) );


   //n_regions = idx;

   ClearVariable(nl_output_);
   ClearVariable(err_lower_output_);
   ClearVariable(err_upper_output_);
   ClearVariable(param_buf_);
   ClearVariable(err_lower_buf_);
   ClearVariable(err_upper_buf_);
   ClearVariable(nan_buf_);

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return 0;

}


int FLIMGlobalFitController::GetParameterImage(int im, int param, uint8_t ret_mask[], float image_data[])
{

   int start, s_local;
   int r_idx;

   int n_px =  data->n_px;

   float* param_data = NULL;
   int span;

   if (   param < 0 || param >= n_output_params
       || im    < 0 || im    >= data->n_im )
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

   for(int rg=1; rg<MAX_REGION; rg++)
   {
      int r_param = param;

      r_idx = data->GetRegionIndex(im, rg);

      start = data->GetRegionPos(im,rg);
      s_local   = data->GetRegionCount(im,rg);


      if (r_idx > -1)
      {         

         if (r_param < n_nl_output_params)
         {
            if (data->global_mode == MODE_PIXELWISE)
            {
               param_data = alf + start * nl;
               
               int j = 0;
               for(int i=0; i<n_px; i++)
                  if(im_mask[i] == rg)
                  {
                     image_data[i] = GetNonLinearParam(r_param, param_data + j*nl);
                     j++;
                  }

            }
            else
            {
               param_data = alf + r_idx * nl;
               float p = GetNonLinearParam(r_param, param_data);
               
               for(int i=0; i<n_px; i++)
                  if(im_mask[i] == rg)
                     image_data[i] = p;

            }
         }
         else
         {
            r_param -= n_nl_output_params;

            span = 1;

            if (r_param < lmax)
            {
               param_data = lin_params + start * lmax + r_param;
               span = lmax;
            } r_param-=lmax;


            if (r_param == 0) 
               param_data = I + start;
            r_param-=1;

            if (acceptor != NULL)
            {
               if (r_param == 0) 
                  param_data = acceptor + start;
               r_param-=1;
            }

            if (calculate_mean_lifetimes)
            {
               if (r_param == 0)
                  param_data = mean_tau + start;
               r_param-=1;
            
               if (r_param == 0) 
                  param_data = w_mean_tau + start;
               r_param-=1;
            }

            if (polarisation_resolved)
            {
               if (r_param == 0) 
                  param_data = r_ss + start;
               r_param-=1;
            }

            if (r_param == 0)
               param_data = chi2 + start;
            r_param-=1;

            int j = 0;
            if (param_data != NULL)
               for(int i=0; i<n_px; i++)
                  if(im_mask[i] == rg)
                     image_data[i] = param_data[span*(j++)];
          }

      }
   }

   return 0;
}


/*===============================================
  GetFit
  ===============================================*/

int FLIMGlobalFitController::GetFit(int im, int n_t, double t[], int n_fit, int fit_loc[], double fit[], int& n_valid)
{
   
   if (!status->HasFit())
      return ERR_FIT_IN_PROGRESS;

   int start, s_local;
   int n_px = data->n_px;;

   uint8_t* mask = data->mask + im*n_px;

   int iml = data->GetImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;
   
   int thread = 0;

   int lin_idx, idx, last_idx;
   int r_idx;

   float *alf_group;
   float *lin_group;

   int n_t_buf = this->n_t;
   double* t_buf = this->t;
   
   this->n_t = n_t;
   this->n_meas = n_t*n_chan;
   this->n = n_meas;
   this->nmax = this->n_meas;
   this->t = t;

   int* resample_idx  = new int[ n_t ]; //ok

   for(int i=0; i<n_t-1; i++)
      resample_idx[i] = 1;
   resample_idx[n_t-1] = 0;

   data->SetExternalResampleIdx(n_meas, resample_idx);

   CalculateIRFMax(n_t,t);
   
   getting_fit = true;


   SetNaN(fit,n_fit*n_meas);

   int ispx = (data->global_mode == MODE_PIXELWISE);

   idx = 0;
   n_valid = 0;
   for(int rg=1; rg<MAX_REGION; rg++)
   {
      r_idx = data->GetRegionIndex(im, rg);

      if (r_idx > -1)
      {         
         start   = data->GetRegionPos(im,rg);
         s_local = data->GetRegionCount(im,rg);

         if (data->global_mode == MODE_PIXELWISE)
            alf_group = alf + start * nl;
         else
            alf_group = alf + r_idx * nl;
         
         lin_group = lin_params + start * lmax;
        
         lin_idx = 0;
         last_idx = 0;
         for(int i=0; i<n_fit; i++)
         {
            idx = fit_loc[i];
            if (mask[idx] == rg)
            {
               for(int j=last_idx; j<idx; j++)
                  lin_idx += (mask[j] == rg);
               last_idx = idx;

               for(int j=0; j<nl; j++)
                  alf_local[j] = alf_group[lin_idx*nl*ispx+j];

               DenormaliseLinearParams(1, lin_group + lin_idx*lmax, lin_local);

               projectors[0].GetFit(n_meas, idx, alf_local, lin_local, adjust_buf, data->counts_per_photon, fit+n_meas*i);
               n_valid++;
            }
            
         }


      }
   }


   getting_fit = false;

   this->n_t = n_t_buf;
   this->n_meas = this->n_t * n_chan;
   this->nmax = n_meas;
   this->t = t_buf;
   this->n = this->n_meas;
   
   delete[] resample_idx;

   return 0;
}
