
#include <boost/math/distributions/fisher_f.hpp>
#include <boost/math/tools/minima.hpp>
#include <boost/bind.hpp>
#include <limits>

#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "IRFConvolution.h"
//#include "VariableProjection.h"
#include "util.h"

using namespace boost::interprocess;

/*===============================================
  ProcessRegion
  ===============================================*/

int FLIMGlobalFitController::ProcessRegion(int g, int region, int thread)
{
   using namespace boost::math;
   using namespace boost::math::tools;

   int i, j, s_thresh, itmax;

   double ref = 0;
   double tau_ma;

   int ierr_local_binning = 0;
   int ierr_local = 0;

   int n_px = data->n_px;
   int s1 = 1;

   //locked_param[thread] = -1;

   int r_idx = data->GetRegionIndex(g,region);

   int lps = l+s;
   int pp3 = p+3;

   uint8_t *mask         = data->mask + g*n_px;
   float   *y            = this->y + thread * s * n_meas;
   float   *ma_decay     = this->ma_decay + thread * n_meas;
   double  *lin_params   = this->lin_params + r_idx * n_px * l;
   double  *chi2         = this->chi2 + r_idx * n_px;
   double  *alf          = this->alf + r_idx * nl;
   float   *w            = this->w + thread * n;
   float   *adjust_buf   = this->adjust_buf + thread * n_meas;
   
   double  *beta_buf     = this->beta_buf + thread * n_exp;
   double  *theta_buf    = this->theta_buf + thread * n_theta;
   double  *fit_buf      = this->fit_buf + thread * n_meas;
   double  *count_buf    = this->count_buf + thread * n_meas;
   double  *conf_lim     = this->conf_lim + thread * nl;
   double  *alf_err      = this->alf_err + thread * nl;
   
   double *alf_local     = this->alf_local + thread * nl;
   double *lin_local     = this->lin_local + thread * l;

   int    *irf_idx       = this->irf_idx + thread * n_px;

   
   int pi = g % (data->n_x*data->n_y);
   local_irf[thread] = irf_buf + pi * n_irf * n_chan;

   if (memory_map_results)
   {
      int nr = data->n_regions_total; 
      std::size_t chi2_offset = (r_idx * n_px                       ) * sizeof(double);
      std::size_t alf_offset  = (nr * n_px + r_idx * nl             ) * sizeof(double);
      std::size_t lin_offset  = (nr * (n_px + nl) + r_idx * l * n_px) * sizeof(double);

      mapped_region chi2_map_view = mapped_region(result_map_file, read_write, chi2_offset, n_px * sizeof(double));
      mapped_region alf_map_view  = mapped_region(result_map_file, read_write, alf_offset,  nl * sizeof(double));
      mapped_region lin_map_view  = mapped_region(result_map_file, read_write, lin_offset,  n_px * l * sizeof(double));

      chi2       = (double*) chi2_map_view.get_address();
      alf        = (double*) alf_map_view.get_address();
      lin_params = (double*) lin_map_view.get_address();
   }


   SetupAdjust(thread, adjust_buf, (fit_scatter == FIX) ? scatter_guess : 0, 
                                   (fit_offset == FIX)  ? offset_guess  : 0, 
                                   (fit_tvb == FIX)     ? tvb_guess     : 0);
                                    
   s_thresh = data->GetRegionData(thread, g, region, adjust_buf, y, w, irf_idx, ma_decay);
   
   int n_meas_res = data->GetResampleNumMeas(thread);

   for(i=0; i<n_meas; i++)
      w[i] = sqrt(w[i]);

   SetNaN(alf, nl);
   SetNaN(lin_params, n_px*l);
   SetNaN(chi2, n_px );

   // Check for termination requestion and that we have at least one px to fit
   //-------------------------------
   if (s_thresh == 0 || status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;




   // Estimate lifetime from mean arrival time if requested
   //------------------------------
   if (estimate_initial_tau)
   {
      tau_ma = CalculateMeanArrivalTime(ma_decay, pi);

      if (n_v == 1)
      {
         alf_local[0] = tau_ma;
      }
      else if (n_v > 1)
      {
         double min_tau  = 0.5*tau_ma;
         double max_tau  = 1.5*tau_ma;
         double tau_step = (max_tau - min_tau)/(n_v-1);

         for(int i=0; i<n_v; i++)
            alf_local[i] = max_tau-i*tau_step;
      }
   }
   else
   {
      for(int i=0; i<n_v; i++)
         alf_local[i] = tau_guess[n_fix+i];
   }



   // Assign initial guesses to nonlinear variables
   //------------------------------
   i=0;
   for(j=0; j<n_v; j++)
      alf_local[i++] = TransformRange(alf_local[j],tau_min[j+n_fix],tau_max[j+n_fix]);
   
   for(j=0; j<n_beta; j++)
      alf_local[i++] = fixed_beta[j];

   for(j=0; j<n_fret_v; j++)
      alf_local[i++] = E_guess[j+n_fret_fix];

   for(j=0; j<n_theta_v; j++)
      alf_local[i++] =  TransformRange(theta_guess[j+n_theta_fix],0,1000000);

   if(fit_t0)
      alf_local[i++] = t0_guess;

   if(fit_offset == FIT_GLOBALLY)
      alf_local[i++] = offset_guess;

   if(fit_scatter == FIT_GLOBALLY)
      alf_local[i++] = scatter_guess;

   if(fit_tvb == FIT_GLOBALLY) 
      alf_local[i++] = tvb_guess;

   if(ref_reconvolution == FIT_GLOBALLY)
      alf_local[i++] = ref_lifetime_guess;

   if(algorithm == ALG_ML)
   {

      double mx = 0;
      for(int j=0; j<n; j++)
      {
         if (y[j]>mx)
            mx = y[j]; 
      }

      for(int j=0; j<l; j++)
         alf_local[i++] = mx/l;
   }

   itmax = 100;

   int use_global_binning = global_algorithm == MODE_GLOBAL_BINNING && s_thresh > 1;

   if (use_global_binning)
   {
      projectors[thread].Fit(s1, n_meas_res, ma_decay, w, NULL, alf_local, lin_local, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   }
   else
   {
         projectors[thread].Fit(s_thresh, n_meas_res, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
      
   }

   for(int i=0; i<nl; i++)
      alf[i] = alf_local[i];

   if (use_global_binning)
      ierr[r_idx] = ierr_local_binning;
   else
      ierr[r_idx] = ierr_local;

/*
   if (ierr[r_idx] >= -1 || ierr[r_idx] == -9) // if successful (or failed due to too many iterations) return fit results
   {

      if (chi2 != NULL)
      {
         int lp1 = l+1;
         c2 = CalculateChi2(thread, region, s_thresh, y, w, a, lin_params, adjust_buf, fit_buf, mask, chi2+g*n_px);

         // calculate errors
         if (calculate_errs)
         {
            ErrMinParams pr;
            pr.gc = this;
            pr.s_thresh = s_thresh;
            pr.r_idx = r_idx;
            pr.region = region;
            pr.group = g;
            pr.chi2 = c2;
            pr.thread = thread;
            std::pair<double , double> ans;

            for(i=0; i<nl; i++)
            {
               locked_param[thread] = i;
               pr.param_value = alf[i];

               double f[3] = {0.1, 0.5, 1.0};

               for(int k=0; k<3; k++)
               {
                  for(j=0; j<nl; j++)
                     alf_err[j] = alf[j];

                  ans = brent_find_minima(boost::bind(&FLIMGlobalFitController::ErrMinFcn,this,_1,pr), 
                                                 0.0, f[k]*pr.param_value, 9);
               
                  if (ans.second < 1)
                     break;   
               }

               if (ans.second > 1)
                  ans.first = 0;
            
               conf_lim[i] = pr.param_value + ans.first;
            }

            locked_param[thread] = -1;

         }
      }

      // Determine order of variable tau's
      //----------------------------
      for (i=0; i<n_v; i++)
         sort_buf[i] = alf[i];

      for (i=0; i<n_v; i++)
         sort_idx_buf[i] = i;

      // just do a bubble sort, we've only got a handful of exponentials
      do
      {
         swapped = false;
         for(i=0; i<n_v-1; i++)
         {
            if (sort_buf[i] < sort_buf[i+1])
            {
               swap_buf = sort_buf[i];
               swap_idx_buf = sort_idx_buf[i];

               sort_buf[i] = sort_buf[i+1];
               sort_buf[i+1] = swap_buf;

               sort_idx_buf[i] = sort_idx_buf[i+1];
               sort_idx_buf[i+1] = swap_idx_buf;

               swapped = true;
            }
         }
      } while(swapped);
      

      // Calculate I0, rescale beta's and remap onto image from mask
      //----------------------------

      i_thresh = 0;
      for(i=0; i<n_px; i++)
      {
 
         if(mask[i] == region)
         {

            lin_idx = 0;
            nlin_idx = n_v;

            if (tau != NULL)
            {
               if (use_FMM)
               {
                  tau[ (g*n_px+i)*n_exp + j + 0 ] = tau_buf[0];
                  tau[ (g*n_px+i)*n_exp + j + 1 ] = tau_buf[1];
               }
               else
               {
                  for(j=0; j<n_fix; j++)
                     tau[ (g*n_px+i)*n_exp + j ] = tau_guess[j];
                  for(j=0; j<n_v; j++)
                     tau[ (g*n_px+i)*n_exp + j + n_fix ] = InverseTransformRange(alf[sort_idx_buf[j]],tau_min[sort_idx_buf[j]+n_fix],tau_max[sort_idx_buf[j]+n_fix]);

                  if (calculate_errs && tau_err != NULL)
                     for(j=0; j<n_v; j++)
                        tau_err[ (g*n_px+i)*n_exp + j + n_fix ] = abs(InverseTransformRange(conf_lim[sort_idx_buf[j]],tau_min[sort_idx_buf[j]+n_fix],tau_max[sort_idx_buf[j]+n_fix]) - tau[ (g*n_px+i)*n_exp + j + n_fix ]);
               }
            }

            if (theta != NULL)
            {
               for(j=0; j<n_theta_fix; j++)
                  theta[ (g*n_px+i)*n_theta + j ] =  theta_guess[ j ];
               for(j=0; j<n_theta_v; j++)
                  theta[ (g*n_px+i)*n_theta + j + n_theta_fix ] = InverseTransformRange(alf[alf_theta_idx + j], 0, 1000000);
               if (calculate_errs && theta_err != NULL)
                  for(j=0; j<n_theta_v; j++)
                     theta_err[ (g*n_px+i)*n_theta + j ] =  abs(InverseTransformRange(conf_lim[alf_theta_idx + j], 0, 1000000) - theta[ (g*n_px+i)*n_theta + j ]);
            }

            if (E != NULL)
            {
               for(j=0; j<n_fret_fix; j++)
                  E[ g*n_px*n_fret + i*n_fret + j ] = E_guess[j];
               for(j=0; j<n_fret_v; j++)
                  E[ g*n_px*n_fret + i*n_fret + j + n_fret_fix ] = alf[alf_E_idx+j];
               if (calculate_errs && E_err != NULL)
                  for(j=0; j<n_fret_v; j++)
                     E_err[ g*n_px*n_fret + i*n_fret + j + n_fret_fix ] = abs(conf_lim[alf_E_idx+j] - E[ g*n_px*n_fret + i*n_fret + j + n_fret_fix ]);
            }

            if (offset != NULL)
            {
               switch(fit_offset)
               {
               case FIX:
                  offset[ g*n_px + i ] = offset_guess;
                  break;
               case FIT_LOCALLY:
                  offset[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx ];
                  lin_idx++;
                  break;
               case FIT_GLOBALLY:
                  offset[ g*n_px + i ] = alf[alf_offset_idx];
                  if (calculate_errs && offset_err != NULL)
                     offset_err[ g*n_px + i ] = abs(conf_lim[alf_offset_idx] - offset[ g*n_px + i ]);

                  nlin_idx++;
                  break;
               }
            }

            if (scatter != NULL)
            {
               switch(fit_scatter)
               {
               case FIX:
                  scatter[ g*n_px + i ] = scatter_guess;
                  break;
               case FIT_LOCALLY:
                  scatter[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx ];
                  lin_idx++;
                  break;
               case FIT_GLOBALLY:
                  scatter[ g*n_px + i ] = alf[alf_scatter_idx];
                  if (calculate_errs && scatter_err != NULL)
                     scatter_err[ g*n_px + i ] = abs(conf_lim[alf_scatter_idx] - scatter[ g*n_px + i ]);
                  nlin_idx++;
                  break;
               }
            }

            if (tvb != NULL)
            {
               switch(fit_tvb)
               {
               case FIX:
                  tvb[ g*n_px + i ] = tvb_guess;
                  break;
               case FIT_LOCALLY:
                  tvb[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx ];
                  lin_idx++;
                  break;
               case FIT_GLOBALLY:
                  tvb[ g*n_px + i ] = alf[alf_tvb_idx];
                  if (calculate_errs && tvb_err != NULL)
                     tvb_err[ g*n_px + i ] = abs(conf_lim[alf_tvb_idx] - tvb[ g*n_px + i ]);
                  nlin_idx++;
                  break;
               }
            }

            if (ref_lifetime != NULL)
            {
               if (ref_reconvolution == FIT_GLOBALLY)
               {
                  ref = alf[alf_ref_idx];
                  ref_lifetime[ g*n_px + i ] = ref;
                  if (calculate_errs && ref_lifetime_err != NULL)
                     ref_lifetime_err[ g*n_px + i ] = abs(conf_lim[alf_ref_idx] - ref_lifetime[ g*n_px + i ]);
               }
               else if (ref_reconvolution)
               {
                  ref = ref_lifetime_guess;
                  ref_lifetime[ g*n_px + i ] = ref;
               }
               else
                  ref_lifetime[ g*n_px + i ] = 0;
            }
            else
            {
               if (ref_reconvolution == FIT_GLOBALLY)
                  ref = alf[alf_ref_idx];
               else if (ref_reconvolution)
                  ref = ref_lifetime_guess;
            }

            if (I0 != NULL)
            {
               if (polarisation_resolved)
               {
                  I0[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx ];
               
                  for(j=0; j<n_r; j++)
                     r[ g*n_px*n_r + i*n_r + j ] = lin_params[ i_thresh*l + j + lin_idx + 1 ] / I0[ g*n_px + i ];

                  double norm = 0;
                  for(j=0; j<n_exp; j++)
                     norm += beta_buf[j];
                  
                  if ( beta != NULL )
                  {
                     for(j=0; j<n_v; j++)
                        beta[ g*n_px*n_exp + i*n_exp + j ] = beta_buf[sort_idx_buf[j]+n_fix] / norm;
                     for(j=0; j<n_fix; j++)
                        beta[ g*n_px*n_exp + i*n_exp + j + n_v ] = beta_buf[j] / norm;
                  }
               }
               else
               {
                  if (fit_fret)
                  {
                     I0[ g*n_px + i ] = 0;
                     for(j=0; j<n_decay_group; j++)
                        I0[ g*n_px + i ] += lin_params[ i_thresh*l + j + lin_idx ];

                     if (gamma != NULL)
                     {
                        for (j=0; j<n_decay_group; j++)
                           gamma[ g*n_px*n_decay_group + i*n_decay_group + j] = lin_params[ i_thresh*l + lin_idx + j] / I0[ g*n_px + i ];
                     }
                  }

                  if (beta_global)
                  {
                     double norm = 0;
                     for(j=0; j<n_exp; j++)
                        norm += beta_buf[j];
                  
                     I0[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx ];

                     if (beta != NULL)
                     {
                        for(j=0; j<n_v; j++)
                           beta[ g*n_px*n_exp + i*n_exp + j ] = beta_buf[sort_idx_buf[j]+n_fix] / norm;

                        if (calculate_errs && beta_err != NULL)
                        {
                           beta_err[ g*n_px*n_exp + i*n_exp + n_beta ] = 0;
                           for(j=0; j<n_beta; j++)
                           {
                              beta_err[ g*n_px*n_exp + i*n_exp + j ] = conf_lim[alf_beta_idx+sort_idx_buf[j]] / norm - beta[ g*n_px*n_exp + i*n_exp + j ];
                              beta_err[ g*n_px*n_exp + i*n_exp + n_beta ] += beta_err[ g*n_px*n_exp + i*n_exp + j ];
                           }
                     
                        }

                        for(j=0; j<n_fix; j++)
                           beta[ g*n_px*n_exp + i*n_exp + j + n_v ] = beta_buf[j] / norm;
                     }

                  }
                  else
                  {
                     I0[ g*n_px + i ] = 0;
                     for(j=0; j<n_exp; j++)
                     {               
                        I0[ g*n_px + i ] += lin_params[ i_thresh*l + j + lin_idx ];
                     }

                     if (beta != NULL)
                     {
                        for(j=0; j<n_v; j++)
                           beta[ g*n_px*n_exp + i*n_exp + j + n_fix ] = lin_params[ i_thresh*l + sort_idx_buf[j] + n_fix + lin_idx] / I0[ g*n_px + i ];
                        for(j=0; j<n_fix; j++)
                           beta[ g*n_px*n_exp + i*n_exp + j ] = lin_params[ i_thresh*l + j + lin_idx] / I0[ g*n_px + i ];
                     }
                  }

               }

               // While this deviates from the definition of I0 in the model, it is closer to the intuitive 'I0', i.e. the peak of the decay
               I0[ g*n_px + i ] *= t_g;  
               if (ref_reconvolution)
                  I0[ g*n_px + i ] /= ref;   // accounts for the amplitude of the reference in the model, since we've normalised the IRF to 1
            }

            i_thresh++;
         }

      }
   }
   */
   return 0;
}
