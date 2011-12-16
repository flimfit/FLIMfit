#include <boost/interprocess/mapped_region.hpp>
#include <boost/math/distributions/fisher_f.hpp>
#include <boost/math/tools/minima.hpp>
#include <boost/bind.hpp>
#include <limits>

#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"



/*===============================================
  ProcessRegion
  ===============================================*/

int FLIMGlobalFitController::ProcessRegion(int g, int region, int thread)
{
   using namespace boost::math;
   using namespace boost::math::tools;
   using namespace boost::interprocess;

   int i, j, i_thresh, s_thresh, lin_idx, nlin_idx, lpps1_, guess_idx, itmax;
   bool swapped;
   double swap_buf;
   int swap_idx_buf;
   double c2;

   double *data; 
   mapped_region data_map_view;

   locked_param[thread] = -1;

   int r_idx = r_start[g] + (region-1);

   int map_offset, aligned_offset, correcting_offset, buf_size;

   if (data_mode == DATA_MAPPED)
   {
      buf_size = n_px * n_meas * sizeof(double);
      map_offset = g * n_px * n_meas * sizeof(double);
      aligned_offset = (map_offset / 65536) * 65536;       // memmap must be aligned to 64k chucks
      buf_size += (map_offset - aligned_offset);
      correcting_offset = (map_offset - aligned_offset) / sizeof(double);

      data_map_view = mapped_region(data_map_file, read_only, aligned_offset, buf_size);
      data = (double*) data_map_view.get_address();

      data += correcting_offset;

   }
   else
   {
      data = this->data + g*n_px*n_meas;
   }

   int        *mask_buf = this->mask_buf + g*n_px;
   doublereal *a = this->a + thread * n_meas * lps;
   doublereal *b = this->b + thread * ndim * pp2;
   doublereal *y = this->y + thread * s * n_meas;
   doublereal *lin_params = this->lin_params + r_idx * n_px * l;
   doublereal *alf = this->alf + r_idx * nl;
   doublereal *alf_best = this->alf_best + r_idx * nl;
   doublereal *w = this->w + thread * n_meas;
   doublereal *sort_buf = this->sort_buf + thread * n_exp;
   int        *sort_idx_buf = this->sort_idx_buf + thread * n_exp;
   doublereal *grid = this->grid + thread * grid_positions;
   doublereal *var_min = this->var_min + thread * nl;
   doublereal *var_max = this->var_max + thread * nl;
   doublereal *var_buf = this->var_buf + thread * nl; 
   doublereal *beta_buf = this->beta_buf + thread * n_exp;
   doublereal *theta_buf = this->theta_buf + thread * n_theta;
   doublereal *fit_buf = this->fit_buf + thread * n_meas;
   doublereal *count_buf = this->count_buf + thread * n_meas;
   doublereal *adjust_buf = this->adjust_buf + thread * n_meas;
   doublereal *conf_lim = this->conf_lim + thread * nl;
   doublereal *alf_err = this->alf_err + thread * nl;

   int idx = 0;

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

   i=0;

   for(j=0; j<n_v; j++)
      alf[i++] = tau2alf(tau_guess[guess_idx+j+n_fix],tau_min[j+n_fix],tau_max[j+n_fix]); //tau_guess[i+n_fix];
   
   for(j=0; j<n_fret_v; j++)
      alf[i++] = beta2alf(pow(R_guess[j+n_fret_fix],-6.0));

   for(j=0; j<n_beta; j++)
      alf[i++] = tau2alf(fixed_beta[j]/fixed_beta[n_beta],0,10); //tau2alf(0.5,0.0,1.0);// tau2alf(1,0,10000);

   for(j=0; j<n_theta_v; j++)
      alf[i++] =  tau2alf(theta_guess[j+n_theta_fix],0,1000000);


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


   for(j=0; j<n_meas; j++)
      w[j] = 0;

   for(i=0; i<n_meas; i++)
   {
      count_buf[i] = 0;
   }

   SetupAdjust(adjust_buf, (fit_scatter == FIX) ? scatter_guess : 0, 
                           (fit_offset == FIX)  ? offset_guess  : 0, 
                           (fit_tvb == FIX)     ? tvb_guess     : 0);

   // Store masked values
   s_thresh = 0;
   for(i=0; i<n_px; i++)
   {
      if (mask_buf[i] == region)
      {
         for(j=0; j<n_meas; j++)
         {
            if (data[i*n_meas + j] != data[i*n_meas + j]) //check for nan
            {
               y[s_thresh*n_meas+j] = 0;
            }
            else
            {
               w[j] += abs(data[i*n_meas + j]);
               y[s_thresh*n_meas+j] = data[i*n_meas + j] - adjust_buf[j];
               count_buf[j]++;
            }

            
         }
         s_thresh++;
      }
   }

   if (anscombe_tranform)
      for(i=0; i<s_thresh*n_meas; i++)
         y[i] = anscombe(y[i]);

   // Check we have pixels left to process
   if (s_thresh == 0)
      goto skip_processing;

   // Compute weights
   if (anscombe_tranform)
   {
      for(j=0; j<n_meas; j++)
      {
            w[j] = 1;
      }
   }
   else
   {
      for(j=0; j<n_meas; j++)
      {
         if (count_buf[j] == 0 || w[j] == 0)
            w[j] = count_buf[j];   // If we have a zero data point set to 1
         else
            w[j] = count_buf[j] / w[j]; // we're averaging over the s_thresh points
      }
   }

   // Check for termination request
   if (status->UpdateStatus(thread, g, 0, 0)==1)
      return 0;

   // Update lpps1 which depends on s
   lpps1_ = l + p + s_thresh + 1;
   
   itmax = 200;
     
   if (grid_search)
   {
      varp2_grid( &s_thresh, &l, &lmax, &nl, &n_meas, &nmax, &ndim, &lpps1_, &lps, &pp2, &iv, 
               t, y, w, (U_fp)ada, a, b, &iprint, (int*) this, (int*) &thread, alf, lin_params, 
               ierr+r_idx, (doublereal*)chi2+r_idx, (int*)&algorithm,
               var_min, var_max, grid, grid_size, grid_factor, var_buf, grid_iter );
   }
   else
   {
      varp2_( &s_thresh, &l, &lmax, &nl, &n_meas, &nmax, &ndim, &lpps1_, &lps, &pp2, &iv, 
               t, y, w, (U_fp)ada, a, b, &iprint, &itmax, (int*) this, (int*) &thread, static_store, 
               alf, lin_params, ierr+r_idx, &c2, &algorithm, alf_best );
   }

  


   if (ierr[r_idx] >= -1 || ierr[r_idx] == -9) // if successful (or failed due to too many iterations) return fit results
   {

      c2 = CalculateChi2(region, s_thresh, y, w, a, lin_params, adjust_buf, fit_buf, mask_buf, chi2+g*n_px);

      // calculate errors
      if (calculate_errs)
      {
         ErrMinParams pr;
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
 
         if(mask_buf[i] == region)
         {

            lin_idx = 0;
            nlin_idx = n_v;


            if (tau != NULL)
            {
               for(j=0; j<n_fix; j++)
                  tau[ (g*n_px+i)*n_exp + j ] = tau_guess[j];
               for(j=0; j<n_v; j++)
                  tau[ (g*n_px+i)*n_exp + j + n_fix ] = alf2tau(alf[sort_idx_buf[j]],tau_min[sort_idx_buf[j]+n_fix],tau_max[sort_idx_buf[j]+n_fix]);
               if (calculate_errs && tau_err != NULL)
                  for(j=0; j<n_v; j++)
                     tau_err[ (g*n_px+i)*n_exp + j + n_fix ] = abs(alf2tau(conf_lim[sort_idx_buf[j]],tau_min[sort_idx_buf[j]+n_fix],tau_max[sort_idx_buf[j]+n_fix]) - tau[ (g*n_px+i)*n_exp + j + n_fix ]);

            }
            if (theta != NULL)
            {
               for(j=0; j<n_theta_v; j++)
                  theta[ (g*n_px+i)*n_theta + j ] =  alf2tau(alf[alf_theta_idx + j], 0, 1000000);
               if (calculate_errs && theta_err != NULL)
                  for(j=0; j<n_theta_v; j++)
                     theta_err[ (g*n_px+i)*n_theta + j ] =  abs(alf2tau(conf_lim[alf_theta_idx + j], 0, 1000000) - theta[ (g*n_px+i)*n_theta + j ]);
               for(j=0; j<n_theta_fix; j++)
                  theta[ (g*n_px+i)*n_theta + j + n_theta_v ] =  theta_guess[ j ];
            }
            if (R != NULL)
            {
               for(j=0; j<n_fret_fix; j++)
                  R[ g*n_px*n_fret + i*n_fret + j ] = R_guess[j];
               for(j=0; j<n_fret_v; j++)
                  R[ g*n_px*n_fret + i*n_fret + j + n_fret_fix ] = pow(alf2beta(alf[alf_iR6_idx+j]),-1.0/6.0);
               if (calculate_errs && R_err != NULL)
                  for(j=0; j<n_fret_v; j++)
                     R_err[ g*n_px*n_fret + i*n_fret + j + n_fret_fix ] = abs(pow(alf2beta(conf_lim[alf_iR6_idx+j]),-1.0/6.0) - R[ g*n_px*n_fret + i*n_fret + j + n_fret_fix ]);
            }

            /*
            if (t0 != NULL)
            {
               switch(fit_t0)
               {
               case FIX:
                  t0[ g*n_px + i ] = t0_guess;
                  break;
               default:
                  //t0[ g*n_px + i ] = alf[nlin_idx];
                  //nlin_idx++;
                  break;
               }
            }
            */

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
                  ref_lifetime[ g*n_px + i ] = alf[alf_ref_idx];
                  if (calculate_errs && ref_lifetime_err != NULL)
                     ref_lifetime_err[ g*n_px + i ] = abs(conf_lim[alf_ref_idx] - ref_lifetime[ g*n_px + i ]);
               }
               else if (ref_reconvolution)
                  ref_lifetime[ g*n_px + i ] = ref_lifetime_guess;
               else
                  ref_lifetime[ g*n_px + i ] = 0;
            }

            if (polarisation_resolved)
            {
               I0[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx + n_r ];
               
               for(j=0; j<n_r; j++)
                  r[ g*n_px*n_r + i*n_r + j ] = lin_params[ i_thresh*l + j + lin_idx ] / I0[ g*n_px + i ];

               double norm = 0;
               for(j=0; j<n_exp; j++)
                  norm += beta_buf[j];

               for(j=0; j<n_v; j++)
                  beta[ g*n_px*n_exp + i*n_exp + j ] = beta_buf[sort_idx_buf[j]+n_fix] / norm;
               for(j=0; j<n_fix; j++)
                  beta[ g*n_px*n_exp + i*n_exp + j + n_v ] = beta_buf[j] / norm;
                 
            }
            else
            {
               if (fit_fret)
               {
                  I0[ g*n_px + i ] = 0;
                  for(j=0; j<n_decay_group; j++)
                     I0[ g*n_px + i ] += lin_params[ i_thresh*l + j + lin_idx ];

                  for (j=0; j<n_decay_group; j++)
                     gamma[ g*n_px*n_decay_group + i*n_decay_group + j] = lin_params[ i_thresh*l + lin_idx + j] / I0[ g*n_px + i ];
               }

               if (beta_global)
               {
                  double norm = 0;
                  for(j=0; j<n_exp; j++)
                     norm += beta_buf[j];
                  
                  I0[ g*n_px + i ] = lin_params[ i_thresh*l + lin_idx ];

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
               else
               {
                  I0[ g*n_px + i ] = 0;
                  for(j=0; j<n_exp; j++)
                  {               
                     I0[ g*n_px + i ] += lin_params[ i_thresh*l + j + lin_idx ];
                  }

                  for(j=0; j<n_v; j++)
                     beta[ g*n_px*n_exp + i*n_exp + j ] = lin_params[ i_thresh*l + sort_idx_buf[j] + n_fix + lin_idx] / I0[ g*n_px + i ];
                  for(j=0; j<n_fix; j++)
                     beta[ g*n_px*n_exp + i*n_exp + j + n_v ] = lin_params[ i_thresh*l + j + lin_idx] / I0[ g*n_px + i ];
               }
            }

            i_thresh++;
         }

      }
   }

skip_processing:


   return 0;
}
