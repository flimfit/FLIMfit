
#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include "boost/bind.hpp"
#include <limits>
#include <exception>

#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"
#include "util.h"

#ifndef NO_OMP   
#include <omp.h>
#endif

using namespace boost::interprocess;
using namespace std;


FLIMGlobalFitController::FLIMGlobalFitController(int global_algorithm, int image_irf,
                                                 int n_irf, double t_irf[], double irf[], double pulse_pileup,
                                                 int n_exp, int n_fix, 
                                                 double tau_min[], double tau_max[], 
                                                 int estimate_initial_tau, double tau_guess[],
                                                 int fit_beta, double fixed_beta[],
                                                 int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                                                 int fit_t0, double t0_guess, 
                                                 int fit_offset, double offset_guess,  
                                                 int fit_scatter, double scatter_guess,
                                                 int fit_tvb, double tvb_guess, double tvb_profile[],
                                                 int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                                                 int pulsetrain_correction, double t_rep,
                                                 int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                                                 int ierr[], int n_thread, int runAsync, int (*callback)()) :
   global_algorithm(global_algorithm), image_irf(image_irf), n_irf(n_irf),  t_irf(t_irf), irf(irf), pulse_pileup(pulse_pileup),
   n_exp(n_exp), n_fix(n_fix), 
   tau_min(tau_min), tau_max(tau_max),
   estimate_initial_tau(estimate_initial_tau), tau_guess(tau_guess),
   fit_beta(fit_beta), fixed_beta(fixed_beta),
   n_theta(n_theta), n_theta_fix(n_theta_fix), inc_rinf(inc_rinf), theta_guess(theta_guess),
   fit_t0(fit_t0), t0_guess(t0_guess), 
   fit_offset(fit_offset), offset_guess(offset_guess), 
   fit_scatter(fit_scatter), scatter_guess(scatter_guess), 
   fit_tvb(fit_tvb), tvb_guess(tvb_guess), tvb_profile(tvb_profile),
   n_fret(n_fret), n_fret_fix(n_fret_fix), inc_donor(inc_donor), E_guess(E_guess),
   pulsetrain_correction(pulsetrain_correction), t_rep(t_rep),
   ref_reconvolution(ref_reconvolution), ref_lifetime_guess(ref_lifetime_guess),
   ierr(ierr), n_thread(n_thread), runAsync(runAsync), callback(callback), algorithm(algorithm),
   error(0), init(false), polarisation_resolved(false), has_fit(false), 
   anscombe_tranform(false), thread_handle(NULL)
{
   params = new WorkerParams[n_thread]; //free ok
   status = new FitStatus(this,n_thread,NULL);

   alf          = NULL;
   a            = NULL;
   b            = NULL;
   c            = NULL;

   y            = NULL;
   lin_params   = NULL;

   w            = NULL;

   exp_buf      = NULL;
   tau_buf      = NULL;
   beta_buf     = NULL;
   theta_buf    = NULL;
   fit_buf      = NULL;
   count_buf    = NULL;
   adjust_buf   = NULL;

   irf_max      = NULL;
   resampled_irf= NULL;

   conf_lim     = NULL;

   locked_param = NULL;
   locked_value = NULL;

   lin_params_err = NULL;
   alf_err        = NULL;

   chan_fact       = NULL;

   ma_decay = NULL;

   data = NULL;

   lm_algorithm = 1;
}

int FLIMGlobalFitController::RunWorkers()
{
   
   if (status->IsRunning())
      return ERR_FIT_IN_PROGRESS;

   if (!init)
      return ERR_COULD_NOT_START_FIT;

   if (n_thread == 1 && !runAsync)
   {
      params[0].controller = this;
      params[0].thread = 0;

      WorkerThread((void*)(params));
   }
   else
   {
      for(int thread = 0; thread < n_thread; thread++)
      {
         params[thread].controller = this;
         params[thread].thread = thread;
      
         thread_handle[thread] = new tthread::thread(WorkerThread,(void*)(params+thread));
      }

      if (!runAsync)
      {
         for(int thread = 0; thread < n_thread; thread++)
            thread_handle[thread]->join();

         CleanupTempVars();
         has_fit = true;
      }
   }
   return 0;
   
}



void WorkerThread(void* wparams)
{
   try
   {
      WorkerParams* p = (WorkerParams*) wparams;
      FLIMGlobalFitController* controller = p->controller;
      FLIMData* data = controller->data;
      int thread = p->thread;

      int idx = 0;

      if (thread >= controller->data->n_regions_total)
         return;

      controller->status->AddThread();

      for(int g=0; g<data->n_group; g++)
      {
         for(int r=data->GetMinRegion(g); r<=data->GetMaxRegion(g); r++)
         {
            if(idx % controller->n_thread == thread)
            {
               if (!controller->init)
                  break;

               controller->ProcessRegion(g,r,thread);

               controller->status->FinishedRegion(thread);
            }
            if (controller->status->terminate)
               goto terminated;
            idx++;
         }
      }

   terminated:

      int threads_running = controller->status->RemoveThread();

      if (threads_running == 0 && controller->runAsync)
      {
         controller->CleanupTempVars();
      }

   }
   catch(std::exception e)
   {
      e = e;

   }
   return;
}

void FLIMGlobalFitController::SetData(FLIMData* data)
{
   this->data = data;

   n_t = data->n_t;
   t = data->GetT();
}


void FLIMGlobalFitController::SetPolarisationMode(int mode)
{
   if (mode == MODE_STANDARD)
      this->polarisation_resolved = false;
   else
      this->polarisation_resolved = true;
}

void FLIMGlobalFitController::DetermineMAStartPosition()
{
   double irf_95, c, p;
   double* t = data->GetT();

   ma_start = 0;

   c = 0;
   for(int i=0; i<n_irf; i++)
      c += irf[i];

   if (polarisation_resolved)
   {
      p = 0;
      for(int i=0; i<n_irf; i++)
         p += irf[i+n_irf];

         g_factor = c/p;
   }



   irf_95 = c * 0.95;
   
   c = 0;
   for(int i=0; i<n_irf; i++)
   {
      c += irf[i];
      if (c >= irf_95)
      {
         for (int j=0; j<data->n_t; j++)
            if (t[j] > t_irf[i])
            {
               ma_start = j;
               break;
            }
         break;
      }   
   }
}

double FLIMGlobalFitController::CalculateMeanArrivalTime(double decay[])
{
   double* t   = data->GetT();
   double  tau = 0;
   double  n   = 0;
   
   for(int i=ma_start; i<n_t; i++)
   {
      tau += decay[i] * (t[i] - t[ma_start]);
      n   += decay[i];
   }
   
   if (polarisation_resolved)
   {
      decay += n_t;
      for(int i=ma_start; i<n_t; i++)
      {
         tau += 2 * g_factor * decay[i] * (t[i] - t[ma_start]);
         n   += 2 * g_factor * decay[i];
      }
   }

   return tau / n;
}


void FLIMGlobalFitController::Init()
{

   int n_group = data->n_group;
   int n_px    = data->n_px;

   int s_max;

   getting_fit = false;

   use_kappa = true;

   // Validate input
   //---------------------------------------
   if (polarisation_resolved)
   {
      if (fit_beta == FIT_LOCALLY)
         fit_beta = FIT_GLOBALLY;

      if (n_fret > 0)
         n_fret = 0;
   }

   if (n_thread < 1)
      n_thread = 1;
   
   #ifndef NO_OMP
   if (n_group == 1)
      omp_set_num_threads(n_thread);
   else
      omp_set_num_threads(1); 
   #endif

   if (data->global_mode != MODE_PIXELWISE)
      image_irf = false;

   // Set up FRET parameters
   //---------------------------------------
   fit_fret = (n_fret > 0) & (fit_beta != FIT_LOCALLY);
   if (!fit_fret)
   {
      n_fret = 0;
      n_fret_fix = 0;
      inc_donor = true;
   }
   else
      n_fret_fix = min(n_fret_fix,n_fret);
 
   n_fret_v = n_fret - n_fret_fix;
      
   tau_start = inc_donor ? 0 : 1;

   beta_global = (fit_beta != FIT_LOCALLY);

   //if (global_mode == MODE_GLOBAL_BINNING)
   //   n_fix = n_exp;

   // Set up polarisation resolved measurements
   //---------------------------------------
   if (polarisation_resolved)
   {
      n_chan = 2;
      n_r = n_theta + inc_rinf;
      n_pol_group = n_r + 1;

      chan_fact = new double[ n_chan * n_pol_group ]; //free ok
      int i;

      double f = +0.00;

      chan_fact[0] = 1.0/3.0- f*1.0/3.0;
      chan_fact[1] = (1.0/3.0) + f*1.0/3.0;

      for(i=1; i<n_pol_group ; i++)
      {
         chan_fact[i*2  ] =   2.0/3.0 - f*2.0/3.0;
         chan_fact[i*2+1] =  -(1.0/3.0) + f*2.0/3.0;
      }

     
   }
   else
   {
      n_chan = 1;
      n_pol_group = 1;
      n_r = 0;

      chan_fact = new double[1]; //free ok
      chan_fact[0] = 1;
   }

   n_theta_v = n_theta - n_theta_fix;

   n_meas = n_t * n_chan;
   
   if (data->global_mode == MODE_PIXELWISE)
      status->SetNumRegion(data->n_masked_px);
   else
      status->SetNumRegion(data->n_regions_total);

   if (data->n_regions_total == 0)
   {
      error = ERR_FOUND_NO_REGIONS;
      return;
   }

   // Only create as many threads as there are regions if we have
   // fewer regions than maximum allowed number of thread
   //---------------------------------------
   n_thread = min(n_thread,data->n_regions_total);
  
   thread_handle = new tthread::thread*[ n_thread ];


   // Supplied t_rep in seconds, convert to ps
   this->t_rep = t_rep * 1e12;

   s_max = data->max_region_size;

   n_decay_group = n_fret + inc_donor;        // Number of decay 'groups', i.e. FRETing species + no FRET

   n_v = n_exp - n_fix;                      // Number of unfixed exponentials
   
   n_exp_phi = (beta_global ? 1 : n_exp);
   
   n_beta = (fit_beta == FIT_GLOBALLY) ? n_exp - 1 : 0;
   
   nl  = n_v + n_fret_v + n_beta + n_theta_v;                                // (varp) Number of non-linear parameters to fit
   p   = (n_v + n_beta)*n_decay_group*n_pol_group + n_exp_phi * n_fret_v + n_theta_v;    // (varp) Number of elements in INC matrix 
   l   = n_exp_phi * n_decay_group * n_pol_group;          // (varp) Number of linear parameters

   s   = s_max;                              // (varp) Number of pixels (right hand sides)

   max_dim = max(n_irf,n_t);
   exp_dim = max_dim * n_chan;
   

   if (ref_reconvolution == FIT_GLOBALLY) // fitting reference lifetime
   {
      nl++;
      p += l;
   }

   // Check whether t0 has been specified
   if (fit_t0)
   {
      nl++;
      p += l;
   }

   if (fit_offset == FIT_GLOBALLY)
   {
      nl++;
      p++;
   }

   if (fit_scatter == FIT_GLOBALLY)
   {
      nl++;
      p++;
   }

   if (fit_tvb == FIT_GLOBALLY)
   {
      nl++;
      p++;
   }

   if (fit_offset == FIT_LOCALLY)
   {
      l++;
   }

   if (fit_scatter == FIT_LOCALLY)
   {
      l++;
   }

   if (fit_tvb == FIT_LOCALLY)
   {
      l++;
   }

   if (data->global_mode == MODE_GLOBAL)
      n = data->GetResampleNumMeas(0);
   else
      n = n_meas;

   ndim = max( n, 2*nl+3 );
   nmax   = n;
   int lps    = l + s + 1;
   int pp3    = p + 3;
   lnls1  = l + nl + s + 1;
   
   csize = max(1,nl);
   csize = csize * (csize + 7);

   exp_buf_size = n_exp * n_pol_group * exp_dim * N_EXP_BUF_ROWS;

   try
   {
      alf          = new double[ data->n_regions_total * nl ]; //free ok
      a            = new double[ n_thread * n * lps ]; //free ok
      
      b            = new double[ n_thread * ndim * pp3 ]; //free ok
      c            = new double[ n_thread * csize ]; // free ok

      y            = new double[ n_thread * s * n_meas ]; //free ok 
      ma_decay     = new double[ n_thread * n_meas ];
      lin_params   = new double[ data->n_regions_total * n_px * l ]; //free ok
      //lin_params   = new double[ n_thread * l ];

      w            = new double[ n_thread * n ]; //free ok

      exp_buf      = new double[ n_thread * n_decay_group * exp_buf_size ]; //free ok
      tau_buf      = new double[ n_thread * (n_fret+1) * n_exp ]; //free ok 
      beta_buf     = new double[ n_thread * n_exp ]; //free ok
      theta_buf    = new double[ n_thread * n_theta ]; //free ok 
      fit_buf      = new double[ n_thread * n_meas ]; // free ok 
      count_buf    = new double[ n_thread * n_meas ]; // free ok 
      adjust_buf   = new double[ n_thread * n_meas ]; // free ok 

      irf_max      = new int[n_meas]; //free ok
      resampled_irf= new double[n_meas]; //free ok 

      conf_lim     = new double[ n_thread * nl ]; //free ok

      locked_param = new int[n_thread];
      locked_value = new double[n_thread];

      lin_params_err = new double[ n_thread * n_px * l ]; //free ok
      alf_err        = new double[ n_thread * nl ]; //free ok

      local_irf    = new DoublePtr[n_thread];

      init = true;
   }
   catch(std::exception e)
   {
      error =  ERR_OUT_OF_MEMORY;
      CleanupTempVars();
      CleanupResults();
      return;
   }

   SetNaN(alf, data->n_regions_total * nl);

   if (n_irf > 2)
      t_g = t_irf[1] - t_irf[0];
   else
      t_g = 1;

   CalculateIRFMax(n_t,t);
   CalculateResampledIRF(n_t,t);
   DetermineMAStartPosition();

   // Select correct convolution function for data type
   //-------------------------------------------------
   if (data->data_type == DATA_TYPE_TCSPC && !ref_reconvolution)
   {
      Convolve = conv_irf_tcspc;
      ConvolveDerivative = ref_reconvolution ? conv_irf_deriv_ref_tcspc : conv_irf_deriv_tcspc;
   }
   else
   {
      Convolve = conv_irf_timegate;
      ConvolveDerivative = ref_reconvolution ? conv_irf_deriv_ref_timegate : conv_irf_deriv_timegate;
   }


   // Set alf indices
   //-----------------------------
   int idx = n_v;

   if (fit_beta == FIT_GLOBALLY)
   {
     alf_beta_idx = idx;
     idx += n_beta;
   }

   if (fit_fret == FIT)
   {
     alf_E_idx = idx;
     idx += n_fret_v;
   }

   alf_theta_idx = idx; 
   idx += n_theta_v;

   if (fit_t0)
      alf_t0_idx = idx++;

   if (fit_offset == FIT_GLOBALLY)
      alf_offset_idx = idx++;

  if (fit_scatter == FIT_GLOBALLY)
      alf_scatter_idx = idx++;

  if (fit_tvb == FIT_GLOBALLY)
      alf_tvb_idx = idx++;

  if (ref_reconvolution == FIT_GLOBALLY)
     alf_ref_idx = idx++;

   first_call = true;

}

FLIMGlobalFitController::~FLIMGlobalFitController()
{
   status->Terminate();

   while (status->IsRunning()) {}

   CleanupResults();
   CleanupTempVars();

   delete status;
   delete[] params;

   status = 0;

}

void FLIMGlobalFitController::CalculateIRFMax(int n_t, double t[])
{
   // Calculate IRF values to include in convolution for each time point
   //------------------------------------------------------------------
   for(int j=0; j<n_chan; j++)
   {
      for(int i=0; i<n_t; i++)
      {
         irf_max[j*n_t+i] = 0;
         int k=0;
         while(k < n_irf && (t[i] - t_irf[k] - t0_guess) >= -1.0)
         {
            irf_max[j*n_t+i] = k + j*n_irf;
            k++;
         }
      }
   }

}

void FLIMGlobalFitController::CalculateResampledIRF(int n_t, double t[])
{
   double td, weight;
   int last_j, c;

   for(int i=0; i<n_t; i++)
   {
      td = t[i]-t0_guess;

      for(c=0; c<n_chan; c++)
         resampled_irf[c*n_t+i] = 0;
      
      resampled_irf[i] = 0;
      last_j = 0;
      for(int j=last_j; j<n_irf-2; j++)
      {
         if(td>t_irf[j] && td<=t_irf[j+1])
         {
            // Interpolate between points
            weight = (td-t_irf[j]) / ( t_irf[j+1]-t_irf[j] );
            for(c=0; c<n_chan; c++)
               resampled_irf[c*n_t+i] = irf[c*n_irf+j]*(1-weight) + irf[c*n_irf+j+1]*weight;
            last_j = j;
            break;
         }
      }
   }   
}

void FLIMGlobalFitController::SetGlobalVariables()
{       
}

int FLIMGlobalFitController::GetNumThreads()
{
   return n_thread;
}


int FLIMGlobalFitController::GetErrorCode()
{
   return error;
}

void FLIMGlobalFitController::SetupAdjust(int thread, double adjust[], double scatter_adj, double offset_adj, double tvb_adj)
{
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   for(int i=0; i<n_meas; i++)
      adjust[i] = 0;

   sample_irf(thread, this, adjust, n_r, scale_fact);

   for(int i=0; i<n_meas; i++)
      adjust[i] = adjust[i] * scatter_adj + tvb_profile[i] * tvb_adj + offset_adj;

}




/*===============================================
  ErrMinFcn
  ===============================================*/

double FLIMGlobalFitController::ErrMinFcn(double x, ErrMinParams& params)
{
/*
   using namespace boost::math;

   int itmax;

   int r_idx = params.r_idx;
   
   int n_px = data->n_px;
   int lps = l+s;
   int pp3 = p+3;

   int    *mask = data->mask + params.group * n_px;
   double *a = this->a + params.thread * n_meas * lps;
   double *b = this->b + params.thread * ndim * pp3;
   double *y = this->y + params.thread * s * n_meas;
   double *alf = this->alf + r_idx * nl;
   double *w = this->w + params.thread * n_meas;
   double *adjust_buf = this->adjust_buf + params.thread * n_meas;
   double *lin_params_err = this->lin_params_err + params.thread * l * n_px;
   double *alf_err = this->alf_err + params.thread * nl;
   double *fit_buf = this->fit_buf + params.thread * n_meas;

   double alpha,c2,F,F_crit;
   int nierr;
   itmax = 10;

   alpha = 0.05;
   fisher_f dist(1, n_meas * params.s_thresh - nl - params.s_thresh * l);
   F_crit = quantile(complement(dist, alpha));
   
   
   locked_value[params.thread] = params.param_value + x;
   alf_err[locked_param[params.thread]] = locked_value[params.thread];
   
   varp2_(  &params.s_thresh, &l, &lmax, &nl, &n_meas, &nmax, &ndim, &lpps1_, &lps, &pp2, 
            t, y, w, (U_fp)ada, a, b, &iprint, &itmax, (int*)this, &params.thread, static_store, 
            alf_err, lin_params_err, &nierr, &c2, &algorithm, alf_best );
            
   c2 = CalculateChi2(params.thread, params.region, params.s_thresh, y, w, a, lin_params_err, adjust_buf, fit_buf, mask, NULL);

   F = (c2-params.chi2)/params.chi2*(n_meas * params.s_thresh - nl - params.s_thresh * l);
  

   return (F-F_crit)*(F-F_crit)/F_crit;
   */
   return 0;
}



void FLIMGlobalFitController::CleanupTempVars()
{
   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);
   
      ClearVariable(a);
      a = a;
      a = a;
      ClearVariable(y);
      y = y;

}

void FLIMGlobalFitController::CleanupResults()
{
   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);

      init = false;
      ClearVariable(lin_params);
      ClearVariable(alf);
      ClearVariable(tau_buf);
      ClearVariable(beta_buf);
      ClearVariable(theta_buf);
      ClearVariable(chan_fact);
      ClearVariable(locked_param);
      ClearVariable(locked_value);

      ClearVariable(c);
      ClearVariable(exp_buf);
      ClearVariable(irf_max);
      ClearVariable(resampled_irf);
      ClearVariable(fit_buf);
      ClearVariable(count_buf);
      ClearVariable(adjust_buf);
      ClearVariable(conf_lim);
      ClearVariable(lin_params_err);
      ClearVariable(alf_err);
      ClearVariable(ma_decay);

      ClearVariable(b);
      ClearVariable(y);
      ClearVariable(w);
      //ClearVariable(local_irf);


      if (data != NULL)
      {
         delete data;
         data = NULL;
      }

   if (thread_handle != NULL)
   {
      delete[] thread_handle;
      thread_handle = NULL;
   }

}
