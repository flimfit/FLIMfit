
#include <boost/math/distributions/fisher_f.hpp>
#include <boost/math/tools/minima.hpp>
#include <boost/bind.hpp>
#include <limits>

#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "IRFConvolution.h"
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

   int r_idx = data->GetRegionIndex(g,region);

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
      w[i] = 1/w[i];
   //   w[i] = sqrt(w[i]);
   
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


   // For maximum likihood set initial guesses for contributions 
   // to sum to maximum intensity, evenly distributed
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

   /* WEIGHTING FOR REFERENCE FITTNG
   projectors[thread].Fit(s_thresh, n_meas_res, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   
   double F0 = 0;
   for(i=0; i<l; i++)
      F0 = lin_params[i];

   
   for(i=0; i<n; i++)
   {
      w[i] *= w[i];
      w[i] = 1/w[i];
   }
   add_irf(thread, irf_idx[0], w, n_r, &F0);
   for(i=0; i<n; i++)
   {
      w[i] = sqrt(1/w[i]);
   }

   projectors[thread].Fit(s_thresh, n_meas_res, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   */

   
   if (use_global_binning)
      projectors[thread].Fit(1, n_meas_res, ma_decay, w, NULL, alf_local, lin_local, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   else
      projectors[thread].Fit(s_thresh, n_meas_res, y, w, irf_idx, alf_local, lin_params, chi2, thread, itmax, data->smoothing_area, status->iter[thread], ierr_local, status->chi2[thread]);
   

   if (calculate_errs)
      projectors[thread].CalculateErrors(alf_local,conf_lim);

   for(int i=0; i<nl; i++)
      alf[i] = alf_local[i];

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
