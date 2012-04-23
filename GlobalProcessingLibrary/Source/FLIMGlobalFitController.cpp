
#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include "boost/bind.hpp"
#include <limits>
#include <exception>

#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"

#ifndef NO_OMP   
#include <omp.h>
#endif

using namespace boost::interprocess;
using namespace std;

void ClearVariable(double*& var)
{
   if (var!=NULL)
   {
      delete[] var;
      var = NULL;
   }
}

void ClearVariable(int*& var)
{
   if (var!=NULL)
   {
      delete[] var;
      var = NULL;
   }
}

void SetNaN(double* var, int n)
{
   unsigned long nan_l[2]={0xffffffff, 0x7fffffff};
   double nan = *( double* )nan_l;

   if (var != NULL)
      for(int i=0; i<n; i++)
         var[i] = nan;
}

FLIMGlobalFitController::FLIMGlobalFitController(int global_algorithm, int n_irf, double t_irf[], double irf[], double pulse_pileup,
                                                 int n_exp, int n_fix, 
                                                 double tau_min[], double tau_max[], 
                                                 int estimate_initial_tau, int single_guess, double tau_guess[],
                                                 int fit_beta, double fixed_beta[],
                                                 int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                                                 int fit_t0, double t0_guess, 
                                                 int fit_offset, double offset_guess,  
                                                 int fit_scatter, double scatter_guess,
                                                 int fit_tvb, double tvb_guess, double tvb_profile[],
                                                 int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                                                 int pulsetrain_correction, double t_rep,
                                                 int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                                                 double tau[], double I0[], double beta[], double E[], double gamma[],
                                                 double theta[], double r[],
                                                 double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                                                 int calculate_errs, double tau_err[], double beta_err[], double E_err[], double theta_err[],
                                                 double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                                                 double chi2[], int ierr[],
                                                 int n_thread, int runAsync, int (*callback)()) :
   global_algorithm(global_algorithm), n_irf(n_irf),  t_irf(t_irf), irf(irf), pulse_pileup(pulse_pileup),
   n_exp(n_exp), n_fix(n_fix), 
   tau_min(tau_min), tau_max(tau_max),
   estimate_initial_tau(estimate_initial_tau), single_guess(single_guess), tau_guess(tau_guess),
   fit_beta(fit_beta), fixed_beta(fixed_beta),
   n_theta(n_theta), n_theta_fix(n_theta_fix), inc_rinf(inc_rinf), theta_guess(theta_guess),
   fit_t0(fit_t0), t0_guess(t0_guess), 
   fit_offset(fit_offset), offset_guess(offset_guess), 
   fit_scatter(fit_scatter), scatter_guess(scatter_guess), 
   fit_tvb(fit_tvb), tvb_guess(tvb_guess), tvb_profile(tvb_profile),
   n_fret(n_fret), n_fret_fix(n_fret_fix), inc_donor(inc_donor), E_guess(E_guess),
   pulsetrain_correction(pulsetrain_correction), t_rep(t_rep),
   ref_reconvolution(ref_reconvolution), ref_lifetime_guess(ref_lifetime_guess),
   tau(tau), I0(I0), beta(beta), E(E), gamma(gamma), theta(theta), r(r), t0(t0), offset(offset), 
   scatter(scatter), tvb(tvb), ref_lifetime(ref_lifetime), 
   calculate_errs(calculate_errs), tau_err(tau_err), beta_err(beta_err), E_err(E_err), theta_err(theta_err), 
   offset_err(offset_err), scatter_err(scatter_err), tvb_err(tvb_err), ref_lifetime_err(ref_lifetime_err),
   chi2(chi2), ierr(ierr),
   n_thread(n_thread), runAsync(runAsync), callback(callback), algorithm(algorithm),
   error(0), init(false), chi2_map_mode(false), polarisation_resolved(false), has_fit(false), 
   anscombe_tranform(false), thread_handle(NULL)
{
   params = new WorkerParams[n_thread]; //free ok
   status = new FitStatus(this,n_thread,NULL);
   use_FMM = false;

   alf          = NULL;
   alf_best     = NULL; 
   a            = NULL;
   b            = NULL;
   c            = NULL;

   y            = NULL;
   lin_params   = NULL;

   w            = NULL;

   sort_buf     = NULL;
   sort_idx_buf = NULL;
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

   irf_buf         = NULL;
   t_irf_buf       = NULL;
   tvb_profile_buf = NULL;
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


void FLIMGlobalFitController::SetChi2MapMode(int grid_size, double grid[])
{
   chi2_map_mode = true;
   grid_search = true;
   this->grid_size = grid_size;
   this->grid = grid;
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


int FLIMGlobalFitController::SetupBinnedFitController()
{
/*
   int n_group = data->n_group;
   int n_px    = data->n_px;

   aux_fit_tau = new double[ n_group * n_px ];
   aux_fit_ierr = new int[ n_group * n_px ];
   aux_tau = new double[ n_thread ];

   boost::interprocess::mapped_region data_map_view;


   aux_n_regions = new int[ n_regions_total ];
   for(int j=0; j<n_group; j++)
      aux_n_regions[j] = 1;
      
   aux_data = new double[ n_regions_total * n_meas ];

   int region = 0;
   for(int g=0; g<n_group; g++)
   {
      double* data = GetDataPointer(g, data_map_view);
      int count = 0;
      for(int i=0; i<n_px; i++)
      {
         if (mask[g*n_px+i] > 0)
         {
            for(int j=0; j<n_meas; j++)
            {
               aux_data[(region+mask[g*n_px+i]-1)*n_meas+j] = data[i*n_meas + j];
               count++;
            }
         }
      }
      for(int i=0; i<n_regions[g]; i++)
         for(int j=0; j<n_meas; j++)
            aux_data[(region+i-1)*n_meas+j] /= count;
      region += n_regions[g];

   }
   
   aux_controller = new FLIMGlobalFitController( n_group, 1, aux_n_regions, MODE_GLOBAL_ANALYSIS,
                                      mask, n_t, t,
                                      n_irf, t_irf, irf, pulse_pileup,
                                      false, n_exp, 0, tau_min, tau_max, 
                                      single_guess, tau_guess,
                                      false, fixed_beta,
                                      n_theta, n_theta_fix, inc_rinf, theta_guess,
                                      fit_t0, t0_guess, 
                                      fit_offset, offset_guess, 
                                      fit_scatter, scatter_guess,
                                      fit_tvb, tvb_guess, tvb_profile,
                                      n_fret, n_fret_fix, inc_donor, E_guess, 
                                      pulsetrain_correction, t_rep,
                                      ref_reconvolution, ref_lifetime_guess, algorithm,
                                      aux_fit_tau, NULL, NULL, NULL, NULL, NULL, r,
                                      NULL, NULL, NULL, NULL, NULL, 
                                      false, NULL, NULL, NULL, NULL, NULL, 
                                      NULL, NULL, NULL,
                                      NULL, aux_fit_ierr,
                                      n_thread, runAsync, NULL );

   //aux_controller->SetData(aux_data, data_type);
   
   aux_controller->Init();
   */
   return 0;

}

int FLIMGlobalFitController::SetupMeanFitController()
{
   /*
   int n_group = data->n_group;
   int n_px    = data->n_px;

   aux_fit_tau = new double[ n_group * n_px ];
   aux_fit_ierr = new int[ n_group * n_px ];
   aux_tau = new double[ n_thread ];

   aux_controller = new FLIMGlobalFitController( n_group, n_px, n_regions, global_mode,
                                      mask, n_t, t,
                                      n_irf, t_irf, irf, pulse_pileup,
                                      false, 1, 0, tau_min, tau_max, 
                                      single_guess, tau_guess,
                                      false, fixed_beta,
                                      n_theta, n_theta_fix, inc_rinf, theta_guess,
                                      fit_t0, t0_guess, 
                                      fit_offset, offset_guess, 
                                      fit_scatter, scatter_guess,
                                      fit_tvb, tvb_guess, tvb_profile,
                                      n_fret, n_fret_fix, inc_donor, E_guess, 
                                      pulsetrain_correction, t_rep,
                                      ref_reconvolution, ref_lifetime_guess, algorithm,
                                      aux_fit_tau, NULL, NULL, NULL, NULL, NULL, r,
                                      NULL, NULL, NULL, NULL, NULL, 
                                      false, NULL, NULL, NULL, NULL, NULL, 
                                      NULL, NULL, NULL,
                                      NULL, aux_fit_ierr,
                                      n_thread, runAsync, NULL );

   if (this->data_mode == DATA_DIRECT)
      aux_controller->SetData(data, data_type);
   else
   {
      aux_controller->SetData(data_file, data_type);
   }
   aux_controller->Init();
   */
   return 0;
}

void FLIMGlobalFitController::Init()
{

   int n_group = data->n_group;
   int n_px    = data->n_px;

   int s_max;

   getting_fit = false;

   use_kappa = false;

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
   
   // Set up grid search if required
   //---------------------------------------
   if (!chi2_map_mode)
   {
      grid_search = (algorithm == 2);
      grid_size = 50;
      grid_iter = 4;
   }
   else
   {
      grid_iter = 1;
   }
   grid_factor = 2;

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
  

   // Store copies of the mask, irf and regions so that we can use them after the fit
   // to get the fitted decays even if the user has removed the memory. These will 
   // be cleared when Cleanup() is called
   //----------------------------------------------------
   irf_buf         = new double[ n_irf * n_chan ]; //free ok
   t_irf_buf       = new double[ n_irf ]; //free ok 
   tvb_profile_buf = new double[ n_meas ]; //free ok 

   thread_handle = new tthread::thread*[ n_thread ];

   if (tvb_profile != NULL)
   {
      for(int i=0; i<n_meas; i++)
         tvb_profile_buf[i] = tvb_profile[i];
   }
   else
   {
     for(int i=0; i<n_meas; i++)
         tvb_profile_buf[i] = 0;
   }

   for(int i=0; i<n_irf*n_chan; i++)
      irf_buf[i] = irf[i];
   for(int i=0; i<n_irf; i++)
      t_irf_buf[i] = t_irf[i];


   // Supplied t_rep in seconds, convert to ps
   this->t_rep = t_rep * 1e12;

   s_max = data->max_region_size;

   n_decay_group = n_fret + inc_donor;        // Number of decay 'groups', i.e. FRETing species + no FRET

   n_v = n_exp - n_fix;                      // Number of unfixed exponentials
   
   n_exp_phi = (beta_global ? 1 : n_exp);
   
   n_beta = (fit_beta == FIT_GLOBALLY) ? n_exp - 1 : 0;
   
   if (use_FMM)
   {
      nl = 2;
      p = 2;
      l = 1;
   }
   else
   {
      nl  = n_v + n_fret_v + n_beta + n_theta_v;                                // (varp) Number of non-linear parameters to fit
      p   = (n_v + n_beta)*n_decay_group*n_pol_group + n_exp_phi * n_fret_v + n_theta_v;    // (varp) Number of elements in INC matrix 
      if (use_kappa)
         p  += (n_v > 1) ? n_v-1 : 0; // for kappa derivates
      l   = n_exp_phi * n_decay_group * n_pol_group;          // (varp) Number of linear parameters
   }


   s   = s_max;                              // (varp) Number of pixels (right hand sides)
   iv  = 1;                                  // (varp) Number of observations -> might change this if we have (say) polarisation resolved measuremnts

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

   anscombe_tranform = false && !use_FMM && (l == 1);
   
   if (data->global_mode == MODE_GLOBAL)
      n = data->GetResampleNumMeas(0);
   else
      n = n_meas;

   if (lm_algorithm == 0)
   {
      ndim   = max( n, 2*nl+3 );
      ndim   = max( ndim, s*n - (s-1)*l );
   }
   else
   {
      ndim = max( n, 2*nl+3 );
   }
   nmax   = n;
   lpps1  = l + p + s + 1; 
   lps    = l + s + 1;
   pp2    = max(p,nl + 1);
   pp2    = p + 2; //max(pp2, 2);
   iprint = -1;
   lnls1  = l + nl + s + 1;
   lmax   = l;
   
   csize = max(1,nl);
   csize = csize * (csize * 7);

   if (nl == 0)
      lpps1  = l + s + 1;
   if (l == 0)
      lpps1 = nl + s + 1;

   exp_buf_size = n_exp * n_pol_group * exp_dim * N_EXP_BUF_ROWS;

   try
   {
      alf          = new double[ data->n_regions_total * nl ]; //free ok
      alf_best     = new double[ data->n_regions_total * nl ]; //free ok
      a            = new double[ n_thread * n * lps ]; //free ok
      
      b            = new double[ n_thread * ndim * pp2 ]; //free ok
      c            = new double[ n_thread * csize ]; // free ok

      y            = new double[ n_thread * s * n_meas ]; //free ok 
      ma_decay     = new double[ n_thread * n_meas ];
      lin_params   = new double[ data->n_regions_total * n_px * l ]; //free ok

      w            = new double[ n_thread * n ]; //free ok

      sort_buf     = new double[ n_thread * n_exp ]; //free ok
      sort_idx_buf = new int[ n_thread * n_exp ]; //free ok
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


      init = true;
   }
   catch(std::exception e)
   {
      error =  ERR_OUT_OF_MEMORY;
      CleanupTempVars();
      CleanupResults();
      return;
   }

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

   // Set default values for regions lying outside of mask
   //------------------------------------------------------
   SetNaN(I0,      n_group*n_px);
   SetNaN(offset,  n_group*n_px);
   SetNaN(scatter, n_group*n_px);
   SetNaN(tvb,     n_group*n_px);
   SetNaN(t0,      n_group*n_px);
   
   SetNaN(tau,     n_group*n_px*n_exp);
   SetNaN(beta,    n_group*n_px*n_exp);
   SetNaN(theta,   n_group*n_px*n_theta);
   SetNaN(r,       n_group*n_px*n_r);

   SetNaN(E,       n_group*n_px*n_fret);
   SetNaN(gamma,   n_group*n_px*n_decay_group);

   SetNaN(ref_lifetime, n_group*n_px);
   SetNaN(chi2, n_group*n_px);

   
   SetNaN(offset_err,  n_group*n_px);
   SetNaN(scatter_err, n_group*n_px);
   SetNaN(tvb_err,     n_group*n_px);
   SetNaN(tau_err,     n_group*n_px*n_exp);
   SetNaN(beta_err,    n_group*n_px*n_exp);
   SetNaN(theta_err,   n_group*n_px*n_theta);
   SetNaN(E_err,       n_group*n_px*n_fret);
   SetNaN(ref_lifetime_err, n_group*n_px);
   

   // Setup grid search
   //---------------------------------
   if (grid_search)
   {
      grid_positions = 1;

      for(int i=0; i<nl; i++)
         grid_positions *= grid_size;

      if (!chi2_map_mode)
         grid = new double[grid_positions * n_thread]; //free ok
      
      var_min = new double[nl * n_thread]; //free ok
      var_max = new double[nl * n_thread]; //free ok
      var_buf = new double[nl * n_thread]; //free ok
   }


   if (use_FMM)   
      SetupMeanFitController();

   //if (global_mode == MODE_GLOBAL_BINNING)
   //   SetupBinnedFitController();

}

FLIMGlobalFitController::~FLIMGlobalFitController()
{
   status->Terminate();

   while (status->IsRunning()) {}

   CleanupResults();
   CleanupTempVars();

   delete status;
   delete[] params;

   //CloseHandle(cleanup_mutex);
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
      adjust[i] = adjust[i] * scatter_adj + tvb_profile_buf[i] * tvb_adj + offset_adj;
}



double FLIMGlobalFitController::CalculateChi2(int thread, int region, int s_thresh, double y[], double w[], double a[], double lin_params[], double adjust_buf[], double fit_buf[], int mask[], double chi2[])
{
   int i,j;
   // calcuate chi2
   double ft;
   double chi2_tot = 0;
   int i_thresh = 0;

   int n_group = data->n_group;
   int n_px    = data->n_px;

   int n_meas_res = data->GetResampleNumMeas(thread);

   for(i=0; i<n_px; i++)
   {
 
      if(mask[i] == region)
      {

         for(j=0; j<n_meas_res; j++)
         {
            double wj, yj;
            ft = 0;
            for(int k=0; k<l; k++)
               ft += a[n_meas_res*k+j] * lin_params[ i_thresh*l + k ];

            ft += a[n_meas_res*l+j];

            yj = y[i_thresh*n_meas_res + j] + adjust_buf[j];

            if ( yj == 0 )
               wj = 1;
            else
               wj = 1/abs(yj);

               if (yj < 0)
               wj = wj;

            fit_buf[j] = (ft - y[i_thresh*n_meas_res + j] ) ;
            fit_buf[j] *= fit_buf[j] * data->smoothing_area * wj;  // account for averaging while smoothing

            if (j>0)
               fit_buf[j] += fit_buf[j-1];
         }

         if (chi2 != NULL)
         {
            chi2[i] = fit_buf[n_meas_res-1] / (n_meas_res - nl/s_thresh - l);
            if (chi2[i] < 0)
               chi2[i] = chi2[i];
            if (chi2[i] == std::numeric_limits<double>::infinity( ))
               chi2[i] = 0;
         }

         if (fit_buf[n_meas_res-1] < 1e5)
            chi2_tot += fit_buf[n_meas_res-1];
         else
            chi2_tot = chi2_tot;

         i_thresh++;


      }
   }

   return chi2_tot;

}


/*===============================================
  ErrMinFcn
  ===============================================*/

double FLIMGlobalFitController::ErrMinFcn(double x, ErrMinParams& params)
{
   using namespace boost::math;

   int itmax;

   int r_idx = params.r_idx;
   int lpps1_ = l + p + params.s_thresh + 1;

   int n_px = data->n_px;

   int    *mask = data->mask + params.group * n_px;
   double *a = this->a + params.thread * n_meas * lps;
   double *b = this->b + params.thread * ndim * pp2;
   double *y = this->y + params.thread * s * n_meas;
   double *alf = this->alf + r_idx * nl;
   double *alf_best = this->alf_best + r_idx * nl;
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
   varp2_(  &params.s_thresh, &l, &lmax, &nl, &n_meas, &nmax, &ndim, &lpps1_, &lps, &pp2, &iv, 
            t, y, w, (U_fp)ada, a, b, &iprint, &itmax, (int*)this, &params.thread, static_store, 
            alf_err, lin_params_err, &nierr, &c2, &algorithm, alf_best );

   c2 = CalculateChi2(params.thread, params.region, params.s_thresh, y, w, a, lin_params_err, adjust_buf, fit_buf, mask, NULL);

   F = (c2-params.chi2)/params.chi2*(n_meas * params.s_thresh - nl - params.s_thresh * l);
  

   return (F-F_crit)*(F-F_crit)/F_crit;

}

/*===============================================
  GetFit
  ===============================================*/

int FLIMGlobalFitController::GetFit(int ret_group_start, int n_ret_groups, int n_fit, int fit_mask[], int n_t, double t[], double fit[])
{
   int i, px_thresh, idx, r_idx, group, process_group;


   // Set default values for regions lying outside of mask
   unsigned long nan_l[2]={0xffffffff, 0x7fffffff};
   double nan = *( double* )nan_l;

   if (!status->HasFit())
      return ERR_FIT_IN_PROGRESS;
   
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

   exp_buf = new double[ n_decay_group * exp_buf_size ];
   irf_max = new int[ n_meas ];
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
   int lpp2 = l+p+2;
   int lps = l+s+1; 
   int inc[96];
   int isel = 1;
   int thread = 0;

   double *at = 0, *bt = 0;

   int ndim;
   ndim   = max( n_meas, 2*nl+3 );
   ndim   = max( ndim, s*n_meas - (s-1)*l );

   try{ at = new double[ n_meas * lps ]; }
   catch(...)
   {
      return ERR_OUT_OF_MEMORY;
   }

   try{ bt = new double[ ndim * pp2 ]; }
   catch(...)
   {
      delete[] at;
      return ERR_OUT_OF_MEMORY;
   }

   for(i=0; i<n_fit*n_meas; i++)
      fit[i] = nan;

   idx = 0;

   for (int g=0; g<n_ret_groups; g++)
   {
      group = ret_group_start + g;
      for(int r=data->GetMinRegion(group); r<=data->GetMaxRegion(group); r++)
      {
         process_group = false;
         for(int p=0; p<n_px; p++)
            if (fit_mask[n_px*g+p] && data->mask[group*n_px+p] == r)
            {
               process_group = true;
               break;
            }

         if (process_group)
         {

            r_idx = data->GetRegionIndex(group,r);
            ada(&s,&lp1,&nl,(int*)&n_meas,&nmax,(int*)&n_meas,&lpp2,&pp2,&iv,at,bt,inc,t,alf+r_idx*nl,&isel,(int*)this, &thread);

            px_thresh = 0;
            for(int p=0; p<n_px; p++)
            {
               if (fit_mask[n_px*g+p])
               {
         
                  if (data->mask[group*n_px+p] == r)
                  {
                     for(i=0; i<n_meas; i++)
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

               if (data->mask[group*n_px+p] == r)
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

/*
int FLIMGlobalFitController::SimulateData(double I0[], double beta[], double data[])
{

   for(int p=0; p<n_px; p++)
   {
      for(int i=0; i<l; i++)
         lin_params[p*l+i] = I0[p] * beta[p*l+i];
   }

   GetFit(0, 1, n_px, mask, n_t, t, data);

   return 0;

}
*/

void FLIMGlobalFitController::CleanupTempVars()
{
   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);

      ClearVariable(a);
      ClearVariable(b);
      ClearVariable(c);
      ClearVariable(y);
      ClearVariable(w);
      ClearVariable(sort_buf);
      ClearVariable(sort_idx_buf);
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

      if (data != NULL)
         data->ClearMapping();

      if (grid_search)
      {
         if (!chi2_map_mode)
            ClearVariable(grid);
         ClearVariable(var_min);
         ClearVariable(var_max);
         ClearVariable(var_buf);
      }
}

void FLIMGlobalFitController::CleanupResults()
{
   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);

      init = false;
      ClearVariable(lin_params);
      ClearVariable(alf);
      ClearVariable(alf_best);
      ClearVariable(tau_buf);
      ClearVariable(beta_buf);
      ClearVariable(theta_buf);
      ClearVariable(irf_buf);
      ClearVariable(t_irf_buf);
      ClearVariable(tvb_profile_buf);
      ClearVariable(chan_fact);
      ClearVariable(locked_param);
      ClearVariable(locked_value);

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
