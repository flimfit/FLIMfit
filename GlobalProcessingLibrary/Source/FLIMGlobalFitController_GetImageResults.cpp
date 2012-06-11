#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"
#include "VariableProjection.h"
#include "util.h"

#ifndef NO_OMP   
#include <omp.h>
#endif

using namespace boost::interprocess;

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
            alf2beta(n_exp,alfl+alf_beta_idx,beta_buf);

            double norm = 0;
            for(j=0; j<n_exp; j++)
               norm += beta_buf[j];

            for(j=0; j<n_exp; j++)
               beta[ j*n_px + loc[i] ] = beta_buf[j] / norm;
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

      if (tvb != NULL && fit_scatter == FIT_GLOBALLY)
         tvb[ loc[i] ] = alfl[alf_tvb_idx];

      if (ref_lifetime != NULL && ref_reconvolution == FIT_GLOBALLY)
         ref_lifetime[ loc[i] ] = alfl[alf_ref_idx];
   
      //alf += nl;
   }

   return 0;
}

int FLIMGlobalFitController::ProcessLinearParams(int s, int n_px, int loc[], double lin_params[], double chi2_group[], 
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
            for(int j=0; j<n_decay_group; j++)
               I0[ loc[i] ] += lin_params[ i*l + j + lin_idx ];

            if (gamma != NULL)
               for (int j=0; j<n_decay_group; j++)
                  gamma[ j*n_px + loc[i] ] = lin_params[ i*l + lin_idx + j] / I0[ loc[i] ];
         }
      }
      else
      {
         #pragma omp parallel for
         for(int i=0; i<s; i++)
         {
            I0[ loc[i] ] = 0;
            for(int j=0; j<n_exp; j++)
               I0[ loc[i] ] += lin_params[ i*l + j + lin_idx ];

            if (beta != NULL)
               for(int j=0; j<n_exp; j++)
                  beta[ j*n_px + loc[i] ] = lin_params[ i*l + j + lin_idx] / I0[ loc[i] ];
         }
      }

      // While this deviates from the definition of I0 in the model, it is closer to the intuitive 'I0', i.e. the peak of the decay
      #pragma omp parallel for
      for(int i=0; i<s; i++)
         I0[ loc[i] ] *= t_g;  
//      if (ref_reconvolution)
//         I0[ g*n_px + i ] /= ref;   // accounts for the amplitude of the reference in the model, since we've normalised the IRF to 1
   }
   return 0;
}


double FLIMGlobalFitController::CalculateChi2(int s, int n_meas_res, float y[], double a[], double lin_params[], float adjust_buf[], double fit_buf[], double chi2[])
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
            wj = 1/abs(yj);

            if (yj < 0)
            wj = wj;

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


// calculate errors: 
/*
int calculate_errs, double tau_err[], double beta_err[], double E_err[], double theta_err[],
                     double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[]
                     */

int FLIMGlobalFitController::GetImageResults(int im, uint8_t ret_mask[], float chi2[], float tau[], float I0[], float beta[], float E[], 
           float gamma[], float theta[], float r[], float t0[], float offset[], float scatter[], float tvb[], float ref_lifetime[])
{

   int thread = 0;

   int s0 = 0;

   int n_px = data->n_x * data->n_y;

   int n_p = data->n_px;

   int iml = im;
   uint8_t *im_mask = data->mask + iml*n_px;
   uint8_t *mask = data->mask;
   int group;
   int r_idx, r_min, r_max, ri;
   int s;

   int *loc = new int[n_px];
   double *alf_group, *lin_group, *chi2_group;
   int *ierr_group; 
   
   
   #ifndef NO_OMP
   omp_set_num_threads(n_thread);
   #endif
   
   for(int i=0; i<n_px; i++)
      ret_mask[i] = im_mask[i];

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
   SetNaN(gamma,   n_px*n_decay_group);
   SetNaN(chi2,    n_px);

   if (data->global_mode == MODE_PIXELWISE)
   {
      for(int i=0; i<n_px; i++)
         loc[i] = i;

      alf_group = alf + nl * n_px * im;
      lin_group = lin_params + l * n_px * im;
      ierr_group = ierr + n_px * im;
      chi2_group = this->chi2 + n_px * im;
      

      int nr = data->n_regions_total;
      std::size_t chi2_offset = (im * n_px                      ) * sizeof(double);
      std::size_t alf_offset  = (nr * n_p + nl * n_px * im      ) * sizeof(double);
      std::size_t lin_offset  = (nr * (n_p + nl) + l * n_px * im) * sizeof(double);

      mapped_region chi2_map_view = mapped_region(result_map_file, read_write, chi2_offset, n_px * sizeof(double));
      mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * n_px * sizeof(double));
      mapped_region lin_map_view  = mapped_region(result_map_file, read_write, lin_offset,  n_px * l * sizeof(double));

      chi2_group = (double*) chi2_map_view.get_address();
      alf_group  = (double*) alf_map_view.get_address();
      lin_group  = (double*) lin_map_view.get_address();




      ProcessLinearParams(n_px, n_px, loc, lin_group, chi2_group, I0, beta, gamma, r, offset, scatter, tvb, chi2);
      ProcessNonLinearParams(n_px, n_px, loc, alf_group, tau, beta, E, theta, offset, scatter, tvb, ref_lifetime);
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
            for(int i=0; i<n_px*iml; i++)
               lin_start += mask[i] == rg;
         }

         int ii = 0;
         for(int i=0; i<n_px; i++)
            if(im_mask[i] == rg)
               loc[ii++] = i;
         s = ii;

         int n_p = data->n_px;

         alf_group = alf + nl * r_idx;
         lin_group = lin_params + l * (data->n_px * r_idx + lin_start);
         chi2_group = this->chi2 + data->n_px * r_idx + lin_start;


         int nr = data->n_regions_total; 
         std::size_t chi2_offset = (r_idx * n_p + lin_start          ) * sizeof(double);
         std::size_t alf_offset  = (nr * n_p + r_idx * nl            ) * sizeof(double);
         std::size_t lin_offset  = (nr * (n_p + nl) + r_idx * l * n_p + l * lin_start) * sizeof(double);

         mapped_region chi2_map_view = mapped_region(result_map_file, read_write, chi2_offset, n_px * sizeof(double));
         mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * sizeof(double));
         mapped_region lin_map_view  = mapped_region(result_map_file, read_write, lin_offset,  n_px * l * sizeof(double));

         chi2_group = (double*) chi2_map_view.get_address();
         alf_group  = (double*) alf_map_view.get_address();
         lin_group  = (double*) lin_map_view.get_address();


         ProcessLinearParams(s, n_px, loc, lin_group, chi2_group, I0, beta, gamma, r, offset, scatter, tvb, chi2);
         ProcessNonLinearParams(1, 1, &s0, alf_group, tau+ri*n_exp, beta+ri*n_exp, E+ri*n_fret, theta+ri*n_theta, offset+ri, scatter+ri, tvb+ri, ref_lifetime+ri);

      }
   }

   delete[] loc;

   return 0;

}



int FLIMGlobalFitController::GetPixelFit(double a[], double lin_params[], float adjust[], int n, double fit[])
{
   for(int i=0; i<n; i++)
   {
      fit[i] = adjust[i];
      for(int j=0; j<l; j++)
         fit[i] += a[n*j+i] * lin_params[j];

      fit[i] += a[n*l+i];
   }

   return 0;
}



/*===============================================
  GetFit
  ===============================================*/

int FLIMGlobalFitController::GetFit(int im, int n_t, double t[], int n_fit, int fit_loc[], double fit[])
{
   if (!status->HasFit())
      return ERR_FIT_IN_PROGRESS;


   int n_px = data->n_x * data->n_y;

   int iml = im; ///data->GetImLoc(im);
   uint8_t* mask = data->mask + iml*n_px;
   

   int thread = 0;

   int s0 = 0;
   int s1 = 1;

   int group;
   int r_idx, r_min, r_max;

   int *loc = new int[n_px];
   double *alf_group;


   int n_t_buf = this->n_t;
   double* t_buf = this->t;
   
   this->n_t = n_t;
   this->n_meas = n_t*n_chan;
   this->n = n_meas;
   this->nmax = this->n_meas;
   this->t = t;

   getting_fit = true;
   
   irf_max       = new int[ n_meas ];
   resampled_irf = new double[ n_meas ];

   int* resample_idx = new int[ n_t ];

   for(int i=0; i<n_t-1; i++)
      resample_idx[i] = 1;
   resample_idx[n_t-1] = 0;

   data->SetExternalResampleIdx(n_meas, resample_idx);

   CalculateIRFMax(n_t,t);
   CalculateResampledIRF(n_t,t);

   float *adjust = new float[n_meas];
   SetupAdjust(0, adjust, (fit_scatter == FIX) ? scatter_guess : 0, 
                          (fit_offset == FIX)  ? offset_guess  : 0, 
                          (fit_tvb == FIX )    ? tvb_guess     : 0);

   
   int s = n_px;
   int lp1 = l+p+1;
   int lps = l+s+1;
   int pp3 = p+3;
    
   int isel = 1;

   double *a, *lin_params;

   a = new double[ n_meas * lps ];
   lin_params = new double[ n_px*l ];
   y = new float[ n_meas * n_px ];

   SetNaN(fit,n_fit*n_meas);

   int idx = 0;
   int ii = 0;

   if (data->global_mode == MODE_PIXELWISE)
   {
      alf_group = alf + nl * n_px * iml;

      int n_p = data->n_px;
      int nr = data->n_regions_total; 
      std::size_t alf_offset  = (nr * n_p + nl * n_px * im) * sizeof(double);
      mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * n_px * sizeof(double));
      alf_group  = (double*) alf_map_view.get_address();

      for(int i=0; i<n_fit; i++)
      {
         idx = fit_loc[i];
         if (mask[idx] > 0)
         {
            local_irf[thread] = irf_buf + idx * n_irf * n_chan;
          
            data->GetRegionData(thread, n_px*iml+idx, 1, adjust_buf, y, w, ma_decay);
            
            #ifdef USE_W
            ws[0] = 1;
            #endif

            lmvarp_getlin(&s1, &l, &nl, &n_meas, &nmax, &ndim, &p, t, y, w, ws, (S_fp) ada, a, b, c, (int*) this, &thread, static_store, alf_group + idx*nl, lin_params);

            GetPixelFit(a,lin_params,adjust,n_meas,fit+n_meas*i);
         }
      }

   }
   else
   {
      local_irf[thread] = irf_buf;

      if (data->global_mode == MODE_IMAGEWISE)
         group = iml;
      else
         group = 0;

      r_min = data->GetMinRegion(group);
      r_max = data->GetMaxRegion(group);

      int idx = 0;
      for(int rg=r_min; rg<=r_max; rg++)
      {

         r_idx = data->GetRegionIndex(group, rg);
         alf_group = alf + nl * r_idx;
         int sr = data->GetSelectedPixels(0, iml, rg, n_fit, fit_loc, adjust_buf, y, w);


         int n_p = data->n_px;
         int nr = data->n_regions_total; 
         std::size_t alf_offset  = (nr * n_p + r_idx * nl            ) * sizeof(double);
         
         mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * sizeof(double));
         alf_group  = (double*) alf_map_view.get_address();
         
         #ifdef USE_W
         #pragma omp parallel for
         for(int i=0; i<sr; i++)
         {
            ws[i] = 0;
            for(int j=0; j<n_meas; j++)
               ws[i] += y[i*n_meas + j];
            ws[i] = sqrt(1 / ws[i]);
         }
         #endif


         lmvarp_getlin(&sr, &l, &nl, &n, &nmax, &ndim, &p, t, y, w, ws, (S_fp) ada, a, b, c, (int*) this, &thread, static_store, alf_group, lin_params);

         #pragma omp parallel for
         for(int i=0; i<sr; i++)
            GetPixelFit(a,lin_params+i*l,adjust,n_meas,fit+n_meas*(idx+i));

         idx += sr;

     }
   }

   getting_fit = false;

   ClearVariable(lin_params);
   ClearVariable(y);
   ClearVariable(a);
   ClearVariable(irf_max);
   ClearVariable(resampled_irf);
   ClearVariable(resample_idx);

   delete[] adjust;

   this->n_t = n_t_buf;
   this->n_meas = this->n_t * n_chan;
   this->nmax = n_meas;
   this->t = t_buf;
   this->n = this->n_meas;
   
   return 0;

}
/*
int FLIMGlobalFitController::GetFit(int ret_group_start, int n_ret_groups, int n_fit, int fit_mask[], int n_t, double t[], double fit[])
{
   int px_thresh, idx, r_idx, group, process_group;

   if (!status->HasFit())
      return ERR_FIT_IN_PROGRESS;
   
   return 0;

   int n_t_buf = this->n_t;
   double* t_buf = this->t;
   
   this->n_t = n_t;
   this->n_meas = n_t*n_chan;
   this->n = n_meas;
   this->nmax = this->n_meas;
   this->t = t;

   int n_group = data->n_group;
   int n_px = data->n_px;

   getting_fit = true;

   exp_dim = max(n_irf*n_chan,n_meas);
   exp_buf_size = n_exp * exp_dim * n_pol_group * N_EXP_BUF_ROWS;

   exp_buf       = new double[ n_decay_group * exp_buf_size ];
   irf_max       = new int[ n_meas ];
   resampled_irf = new double[ n_meas ];

   int* resample_idx = new int[ n_t ];

   for(int i=0; i<n_t-1; i++)
      resample_idx[i] = 1;
   resample_idx[n_t-1] = 0;

   data->SetExternalResampleIdx(n_meas, resample_idx);

   CalculateIRFMax(n_t,t);
   CalculateResampledIRF(n_t,t);

   double *adjust = new double[n_meas];
   SetupAdjust(0, adjust, (fit_scatter == FIX) ? scatter_guess : 0, 
                          (fit_offset == FIX)  ? offset_guess  : 0, 
                          (fit_tvb == FIX )    ? tvb_guess     : 0);

   
   int s = 1;
   int lp1 = l+p+1;
   int lps = l+s+1;
   int pp3 = p+3;
    
   int inc[96];
   int isel = 1;
   int thread = 0;

   double *a = 0, *b = 0, *kap;

   int ndim;
   ndim   = max( n_meas, 2*nl+3 );
   ndim   = max( ndim, s*n_meas - (s-1)*l );

   double* at = new double[ n_meas * lps ];
   double* bt = new double[ ndim * pp3 ];

   kap = bt + ndim * (pp3-1);

   SetNaN(fit,n_fit*n_meas);

   idx = 0;

   for (int g=0; g<n_ret_groups; g++)
   {
      group = ret_group_start + g;
      for(int r=data->GetMinRegion(group); r<=data->GetMaxRegion(group); r++)
      {
         process_group = false;
         for(int i=0; i<n_px; i++)
         {
            if (fit_mask[n_px*g+i] && data->mask[group*n_px+i] == r)
            {
               process_group = true;
               break;
            }
         }

         if (process_group)
         {

            r_idx = data->GetRegionIndex(group,r);
            ada(&s,&lp1,&nl,(int*)&n_meas,&nmax,(int*)&n_meas,&p,at,bt,NULL,inc,t,alf+r_idx*nl,&isel,(int*)this, &thread);

            px_thresh = 0;
            for(int k=0; k<n_px; k++)
            {
               if (fit_mask[n_px*g+k])
               {
         
                  if (data->mask[group*n_px+k] == r)
                  {
                     for(int i=0; i<n_meas; i++)
                     {
                        fit[idx*n_meas + i] = adjust[i];
                        for(int j=0; j<l; j++)
                           fit[idx*n_meas + i] += at[n_meas*j+i] * lin_params[r_idx*n_px*l + l*px_thresh +j];

                        fit[idx*n_meas + i] += at[n_meas*l+i];

                        if (anscombe_tranform)
                           fit[idx*n_meas + i] = inv_anscombe(fit[idx*n_meas + i]);
                     }
                     idx++;
                     if (idx == n_fit)
                        goto max_reached;
                  }
            
               }

               if (data->mask[group*n_px+k] == r)
                  px_thresh++;

            }
         }
      }
   }

max_reached:   

   getting_fit = false;

   ClearVariable(at);
   ClearVariable(bt);
   ClearVariable(exp_buf);
   ClearVariable(irf_max);
   ClearVariable(resampled_irf);
   ClearVariable(resample_idx);

   delete[] adjust;

   this->n_t = n_t_buf;
   this->n_meas = this->n_t * n_chan;
   this->nmax = n_meas;
   this->t = t_buf;
   this->n = this->n_meas;
   
   return 0;

}
*/