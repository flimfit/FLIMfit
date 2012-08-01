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

      if (tvb != NULL && fit_tvb == FIT_GLOBALLY)
         tvb[ loc[i] ] = alfl[alf_tvb_idx];

      if (ref_lifetime != NULL && ref_reconvolution == FIT_GLOBALLY)
         ref_lifetime[ loc[i] ] = alfl[alf_ref_idx];
   
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
         else  {
            double debug = fabs(yj);
            wj = 1/abs(yj);
         }

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
   int s;

   int *loc = new int[n_px]; //ok
   double *alf_group, *lin_group, *chi2_group;
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
   SetNaN(gamma,   n_px*n_decay_group);
   SetNaN(chi2,    n_px);

   if (data->global_mode == MODE_PIXELWISE)
   {
      for(int i=0; i<n_px; i++)
         loc[i] = i;

      ierr_group = ierr + n_px * im;
      
      if (memory_map_results)
      {
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
      }
      else
      {
         chi2_group = this->chi2 + n_px * im;
         alf_group = alf + nl * n_px * im;
         lin_group = lin_params + l * n_px * im;
      }



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

         if (memory_map_results)
         {
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
         }
         else
         {
            alf_group = alf + nl * r_idx;
            lin_group = lin_params + l * (data->n_px * r_idx + lin_start);
            chi2_group = this->chi2 + data->n_px * r_idx + lin_start;
         }

         ProcessLinearParams(s, n_px, loc, lin_group, chi2_group, I0, beta, gamma, r, offset, scatter, tvb, chi2);
         ProcessNonLinearParams(1, 1, &s0, alf_group, tau+ri*n_exp, beta+ri*n_exp, E+ri*n_fret, theta+ri*n_theta, offset+ri, scatter+ri, tvb+ri, ref_lifetime+ri);

      }
   }

   delete[] loc;

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

   uint8_t* mask = data->mask + im*n_px;

   int iml = data->GetImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;
   
   int thread = 0;

   int group, lin_idx, idx, last_idx;
   int r_idx, r_min, r_max;

   double *alf_group, *lin_group;

   int n_t_buf = this->n_t;
   double* t_buf = this->t;
   
   this->n_t = n_t;
   this->n_meas = n_t*n_chan;
   this->n = n_meas;
   this->nmax = this->n_meas;
   this->t = t;

   getting_fit = true;

   float *adjust = new float[n_meas]; //ok
   SetupAdjust(0, adjust, (fit_scatter == FIX) ? scatter_guess : 0, 
                          (fit_offset == FIX)  ? offset_guess  : 0, 
                          (fit_tvb == FIX )    ? tvb_guess     : 0);


   SetNaN(fit,n_fit*n_meas);


   if (data->global_mode == MODE_PIXELWISE)
   {
      if (memory_map_results)
      {
         int n_p = data->n_px;
         int nr = data->n_regions_total; 
         std::size_t alf_offset  = (nr * n_p + nl * n_px * im) * sizeof(double);
         mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * n_px * sizeof(double));
         alf_group  = (double*) alf_map_view.get_address();
      }
      else
      {
         alf_group = alf + nl * n_px * iml;
         lin_group = lin_params + l * n_px * iml;
      }

      for(int i=0; i<n_fit; i++)
      {
         idx = fit_loc[i];
         if (mask[idx] > 0)
            projectors[0].GetFit(idx, alf_group + idx*nl, lin_params + idx*l, adjust_buf, fit+n_meas*i);
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

         if (memory_map_results)
         {
            int n_p = data->n_px;
            int nr = data->n_regions_total; 
            std::size_t alf_offset  = (nr * n_p + r_idx * nl            ) * sizeof(double);
         
            mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * sizeof(double));
            alf_group  = (double*) alf_map_view.get_address();
         }
         else
         {
            alf_group = alf + nl * r_idx;
            lin_group = lin_params + l * n_px * r_idx;
         }

         last_idx = 0;
         lin_idx = 0;
         for(int i=0; i<n_fit; i++)
         {
            idx = fit_loc[i];
            if (mask[idx] > 0)
            {
               for(int j=last_idx; j<idx; j++)
                  lin_idx += (mask[j] == rg);
               projectors[0].GetFit(idx, alf_group, lin_params + lin_idx*l, adjust_buf, fit+n_meas*i);
            }
            last_idx = idx;
         }

         /*
         for(int i=0; i<sr; i++)
         {
            idx = fit_loc[i];
            if (mask[idx] > 0)
            {            
               projectors[0].GetFit(1, &irf_idx[i], alf_group, lin_params + i*l, adjust_buf, fit+n_meas*idx);
            }
         }
         */
     }
   }

   getting_fit = false;

   ClearVariable(adjust);

   //ClearVariable(irf_max);
   //ClearVariable(resample_idx);
   //ClearVariable(resampled_irf);

   this->n_t = n_t_buf;
   this->n_meas = this->n_t * n_chan;
   this->nmax = n_meas;
   this->t = t_buf;
   this->n = this->n_meas;
   
   return 0;

}
