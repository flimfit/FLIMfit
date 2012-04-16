
#include <boost/math/distributions/fisher_f.hpp>
#include <boost/math/tools/minima.hpp>
#include <boost/bind.hpp>
#include <limits>

#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "IRFConvolution.h"



/*===============================================
  ProcessRegion
  ===============================================*/

int FLIMGlobalFitController::ProcessRegion(int g, int region, int thread)
{
   using namespace boost::math;
   using namespace boost::math::tools;

   int n_px = data->n_px;

   int i, j, i_thresh, s_thresh, lin_idx, nlin_idx, lpps1_, guess_idx, itmax, lps_;
   bool swapped;
   double swap_buf;
   int swap_idx_buf;
   
   double c2;
   double ref = 0;
   double tau_ma;

   int ierr_local_binning = 0;
   int ierr_local = 0;
	
   int s1 = 1;

   locked_param[thread] = -1;


   int r_idx = data->GetRegionIndex(g,region);

   /*
   if (use_FMM)
   {
      aux_controller->ProcessRegion(g,region,thread);
      aux_tau[thread] = aux_fit_tau[g*n_px];
   }
   */

   /*
   if (global_mode == MODE_GLOBAL_BINNING)
   {
      int rt=0;
      for(int i=0; i<g; i++)
         rt+=n_regions[i];
      aux_controller->ProcessRegion(rt+region,1,thread);
      aux_tau[thread] = aux_fit_tau[g*n_px];
   }
   */


   int        *mask         = data->mask + g*n_px;
   double *a            = this->a + thread * n * lps;
   double *b            = this->b + thread * ndim * pp2;
   double *y            = this->y + thread * s * n_meas;
   double *ma_decay     = this->ma_decay + thread * n_meas;
   double *lin_params   = this->lin_params + r_idx * n_px * l;
   double *alf          = this->alf + r_idx * nl;
   double *alf_best     = this->alf_best + r_idx * nl;
   double *w            = this->w + thread * n;
   double *sort_buf     = this->sort_buf + thread * n_exp;
   int        *sort_idx_buf = this->sort_idx_buf + thread * n_exp;
   double *grid         = this->grid + thread * grid_positions;
   double *var_min      = this->var_min + thread * nl;
   double *var_max      = this->var_max + thread * nl;
   double *var_buf      = this->var_buf + thread * nl; 
   double *beta_buf     = this->beta_buf + thread * n_exp;
   double *theta_buf    = this->theta_buf + thread * n_theta;
   double *fit_buf      = this->fit_buf + thread * n_meas;
   double *count_buf    = this->count_buf + thread * n_meas;
   double *adjust_buf   = this->adjust_buf + thread * n_meas;
   double *conf_lim     = this->conf_lim + thread * nl;
   double *alf_err      = this->alf_err + thread * nl;

   int idx = 0;
   
   
   double smoothing_correction = 1/data->smoothing_area;
   smoothing_correction = 1;

   SetupAdjust(thread, adjust_buf, (fit_scatter == FIX) ? scatter_guess : 0, 
                                   (fit_offset == FIX)  ? offset_guess  : 0, 
                                   (fit_tvb == FIX)     ? tvb_guess     : 0);

   s_thresh = data->GetRegionData(thread, g, region, adjust_buf, y, w, ma_decay);
   
   int n_meas_res = data->GetResampleNumMeas(thread);

   if (s_thresh == 0)
      goto skip_processing;

   

   tau_ma = CalculateMeanArrivalTime(ma_decay);


   for(j=0; j<n_meas_res; j++)
   {
      w[j] += adjust_buf[j];
      if (s_thresh == 0 || w[j] == 0)
         w[j] = smoothing_correction;   // If we have a zero data point set to 1
      else
         w[j] = smoothing_correction/abs(w[j]); //smoothing_correction / abs(y[j]);
   }

   if (anscombe_tranform)
      for(i=0; i<s_thresh*n_meas_res; i++)
         y[i] = anscombe(y[i]);


   // Check for termination request
   if (status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;


   if (grid_search)
   {
      for(i=0; i<n_v; i++)
      {
         var_min[idx] = tau_min[idx];
         var_max[idx] = tau_max[idx];
         idx++;
      }
      if(fit_beta == FIT_GLOBALLY)
      {
         var_min[idx] = 0;
         var_max[idx] = 100;
         idx++;
      }
      for(i=0; i<n_fret_v; i++)
      {
         var_min[idx] = 0.2;
         var_max[idx] = 3.0;
         idx++;
      }
   }

   if (single_guess)
      guess_idx = 0;
   else
      guess_idx = g * n_v;

   if (estimate_initial_tau)
   {
      if (n_v == 1)
      {
         alf[0] = tau_ma;
      }
      else if (n_v > 1)
      {
         double min_tau  = 0.5*tau_ma;
         double max_tau  = 1.5*tau_ma;
         double tau_step = (max_tau - min_tau)/(n_v-1);

         for(int i=0; i<n_v; i++)
            alf[i] = i*tau_step+min_tau;
      }
   }
   else
   {
      for(int i=0; i<n_v; i++)
         alf[i] = tau_guess[guess_idx+n_fix+i];
   }

   i=0;

   /*
   if (global_mode == MODE_GLOBAL_BINNING)
   {
      for(j=0; j<n_exp; j++)
         tau_guess[j] = aux_tau[j];
   }
   */
   
   if (use_FMM)
   {
//      alf[0] = 1.05*aux_tau[thread]; //tau_guess[0];
//      alf[1] = 0.8;
   }
   else
   {
      for(j=0; j<n_v; j++)
         alf[i++] = TransformRange(alf[j],tau_min[j+n_fix],tau_max[j+n_fix]);
   
      for(j=0; j<n_beta; j++)
         alf[i++] = fixed_beta[j];

      for(j=0; j<n_fret_v; j++)
         alf[i++] = E_guess[j+n_fret_fix];

      for(j=0; j<n_theta_v; j++)
         alf[i++] =  TransformRange(theta_guess[j+n_theta_fix],0,1000000);
   }

   if(fit_t0)
      alf[i++] = t0_guess;

   if(fit_offset == FIT_GLOBALLY)
      alf[i++] = offset_guess;

   if(fit_scatter == FIT_GLOBALLY)
      alf[i++] = scatter_guess;

   if(fit_tvb == FIT_GLOBALLY) 
      alf[i++] = tvb_guess;

   if(ref_reconvolution == FIT_GLOBALLY)
      alf[i++] = ref_lifetime_guess;


   // Update lpps1 which depends on s   
   itmax = 100;


   if (USE_GLOBAL_BINNING_AS_ESTIMATE && s_thresh > 1)
   {
      lpps1_ = l + p + 1 + 1;
      lps_ = l + 1;
      
      varp2_( &s1, &l, &lmax, &nl, &n_meas_res, &nmax, &ndim, &lpps1_, &lps_, &pp2, &iv, 
               t, y, w, (U_fp)ada, a, b, &iprint, &itmax, (int*) this, (int*) &thread, static_store, 
               alf, lin_params, &ierr_local_binning, &c2, &algorithm, alf_best );
   }

   if (global_algorithm == MODE_GLOBAL_BINNING && s_thresh > 1)
      itmax = 0;

   if (grid_search)
   {
      varp2_grid( &s_thresh, &l, &lmax, &nl, &n_meas_res, &nmax, &ndim, &lpps1_, &lps_, &pp2, &iv, 
               t, y, w, (U_fp)ada, a, b, &iprint, (int*) this, (int*) &thread, alf, lin_params, 
               &ierr_local, (double*)chi2+r_idx, (int*)&algorithm,
               var_min, var_max, grid, grid_size, grid_factor, var_buf, grid_iter );
   }
   else
   {
      lpps1_ = l + p + s_thresh + 1;
      lps_ = l + s_thresh;
      varp2_( &s_thresh, &l, &lmax, &nl, &n_meas_res, &nmax, &ndim, &lpps1_, &lps_, &pp2, &iv, 
               t, y, w, (U_fp)ada, a, b, &iprint, &itmax, (int*) this, (int*) &thread, static_store, 
               alf, lin_params, &ierr_local, &c2, &algorithm, alf_best );
   }

   if (global_algorithm == MODE_GLOBAL_BINNING && s_thresh > 1)
      ierr[r_idx] = ierr_local_binning;
   else
      ierr[r_idx] = ierr_local;

   if (ierr[r_idx] < 0)
      ierr[r_idx] += 0;

   if (ierr[r_idx] >= -1 || ierr[r_idx] == -9) // if successful (or failed due to too many iterations) return fit results
   {

      if (chi2 != NULL)
      {
         int lp1 = l+1;
         int lpp2 = l+p+2;
         int
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

skip_processing:


   return 0;
}
