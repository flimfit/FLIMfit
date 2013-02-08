//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================

#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include "boost/bind.hpp"
#include <limits>
#include <exception>

#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"
#include "VariableProjector.h"
#include "MaximumLikelihoodFitter.h"
#include "util.h"

#include "omp_stub.h"

using namespace boost::interprocess;
using namespace std;




FLIMGlobalFitController::FLIMGlobalFitController(int global_algorithm, int image_irf, 
                                                 int n_irf, double t_irf[], double irf[], double pulse_pileup,
                                                 double t0_image[],
                                                 int n_exp, int n_fix, int n_decay_group, int* decay_group,
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
                                                 int weighting, int n_thread, int runAsync, int (*callback)()) :
   global_algorithm(global_algorithm), image_irf(image_irf), n_irf(n_irf),  t_irf(t_irf), irf(irf), pulse_pileup(pulse_pileup),
   t0_image(t0_image), n_exp(n_exp), n_fix(n_fix), n_decay_group(n_decay_group), decay_group(decay_group),
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
   n_thread(n_thread), runAsync(runAsync), callback(callback), algorithm(algorithm),
   weighting(weighting), error(0), init(false), polarisation_resolved(false), has_fit(false)
{

   if (this->n_thread < 1)
      this->n_thread = 1;

   params = new WorkerParams[this->n_thread]; //ok
   status = new FitStatus(this,this->n_thread,NULL); //ok

   alf          = NULL;
   chi2         = NULL;
   I            = NULL;
   r_ss         = NULL;
   w_mean_tau   = NULL;
   mean_tau     = NULL;
   cur_alf      = NULL;
   cur_irf_idx  = NULL;
   acceptor     = NULL;

   ierr         = NULL;
   success      = NULL;

   y            = NULL;
   lin_params   = NULL;

   w            = NULL;

   irf_buf      = NULL;
   t_irf_buf    = NULL;
   exp_buf      = NULL;
   tau_buf      = NULL;
   beta_buf     = NULL;
   theta_buf    = NULL;
   fit_buf      = NULL;
   count_buf    = NULL;
   adjust_buf   = NULL;
   decay_group_buf = NULL;

   irf_max      = NULL;
   
   conf_lim     = NULL;

   locked_param = NULL;
   locked_value = NULL;

   lin_params_err = NULL;
   alf_err        = NULL;

   chan_fact      = NULL;
   irf_idx        = NULL;

   param_names_ptr = NULL;

   result_map_filename = NULL;
   local_decay = NULL;
   data = NULL;

   alf_local = NULL;
   lin_local = NULL;

   thread_handle = NULL;

   lm_algorithm = 1;

}

int FLIMGlobalFitController::RunWorkers()
{
   
   if (status->IsRunning())
      return ERR_FIT_IN_PROGRESS;

   if (!init)
      return ERR_COULD_NOT_START_FIT;

   omp_set_num_threads(n_omp_thread);


   if (n_fitters == 1 && !runAsync)
   {
      params[0].controller = this;
      params[0].thread = 0;

      StartWorkerThread((void*)(params));
   }
   else
   {
      for(int thread = 0; thread < n_fitters; thread++)
      {
         params[thread].controller = this;
         params[thread].thread = thread;
      
         thread_handle[thread] = new tthread::thread(StartWorkerThread,(void*)(params+thread)); // ok
      }

      if (!runAsync)
      {
         for(int thread = 0; thread < n_fitters; thread++)
            thread_handle[thread]->join();

         CleanupTempVars();
         has_fit = true;
      }
   }
   return 0;
   
}


/**
 * Wrapper function for WorkerThread
 */
void StartWorkerThread(void* wparams)
{
   WorkerParams* p = (WorkerParams*) wparams;

   FLIMGlobalFitController* controller = p->controller;
   int                      thread     = p->thread;

   controller->WorkerThread(thread);
}

/**
 * Worker thread, called several times to process regions
 */
void FLIMGlobalFitController::WorkerThread(int thread)
{
   int idx, region_count;
   
   status->AddThread();

   //=============================================================================
   // In pixelwise mode, we process one region at a time, with all threads
   // working on the same region. When all threads are finished working
   // on a region, thread 0 gets the data for the next thread and processing
   // begins again. Use active_lock to ensure processes are kept in order
   //=============================================================================
   if (data->global_mode == MODE_PIXELWISE)
   {

      for(int im=0; im<data->n_im_used; im++)
      {
         for(int r=0; r<MAX_REGION; r++)
         {
            if (data->GetRegionIndex(im,r) > -1)
            {
               idx = im*MAX_REGION+r;

               if (thread > 0)
               {     
                  // If we are not thread 0, check if thread 0 has processed
                  // the data we need. If not, wait until it has been processed
                  
                  region_mutex.lock();

                  while (idx > cur_region)
                     active_lock.wait(region_mutex);
                  
                  threads_active++;
                  threads_started++;

                  region_mutex.unlock();
               }
               else
               {                  
                  // If we are thread 0, check to see if all threads have started & finished on current region
                  // then request data for next region

                  region_mutex.lock();
                  
                  while (  threads_active > 0 ||                           // there are threads running
                          (threads_started < n_thread && cur_region >= 0) ) // not all threads have yet started up
                     active_lock.wait(region_mutex);
  
                  int pos =  data->GetRegionPos(im,r);

                  float* I_local        = I        + pos;
                  float* r_ss_local     = r_ss     + pos;
                  float* acceptor_local = acceptor + pos;
                  
                  data->GetMaskedData(0, im, r, adjust_buf, y, I_local, r_ss_local, acceptor_local, irf_idx, global_algorithm == MODE_GLOBAL_BINNING);
                  next_pixel = 0;
                  
                  cur_region = idx;

                  threads_active++;
                  threads_started = 1;
                 
                  active_lock.notify_all();
                  region_mutex.unlock();


               }

               // Process every n_thread'th pixel in region

               region_count = data->GetRegionCount(im,r);
               for(int j=thread; j<region_count; j+=n_thread)
               {
                  ProcessRegion(im, r, j, thread);
                  
                  // Check to see if a termination has been requested
                  if (status->terminate)
                  {
                     region_mutex.lock();
                     threads_active--;
                     active_lock.notify_all();
                     region_mutex.unlock();
                     
                     goto terminated;
                  }

               }

               region_mutex.lock();
               threads_active--;
               active_lock.notify_all();
               region_mutex.unlock();

            }
         }
      }
   }

   //=============================================================================
   // In imagewise mode, each region from each image is processed seperately. 
   // Each thread processes every n_thread'th region in the dataset
   //=============================================================================
   else if (data->global_mode == MODE_IMAGEWISE)
   {
      // Cycle through every region in every image
      for(int im=0; im<data->n_im_used; im++)
         for(int r=0; r<MAX_REGION; r++)
         {
            // Get region index and process if it exists and is for this threads
            idx = data->GetRegionIndex(im,r);
            if (idx > -1 &&               // region exists
               idx % n_thread == thread)  // should be processed by this thread
               ProcessRegion(im, r, 0, thread);
            
            if (status->terminate)
               goto terminated;
         }
   }

   //=============================================================================
   // In global mode each region is processed seperately across the images
   // so we processes all region 1's from every image together etc
   // Each thread processes a different region
   //=============================================================================
   else
   {
      // Cycle through regions
      for(int r=0; r<MAX_REGION; r++)
      {
         idx = data->GetRegionIndex(-1,r);
         if (idx > -1 && idx % n_thread == thread)
            ProcessRegion(-1, r, 0, thread);
           
         if (status->terminate)
            goto terminated;
      }
   }

terminated:

   int threads_running = status->RemoveThread();

   // If we're the last thread running cleanup temporary variables
   if (threads_running == 0 && runAsync)
      CleanupTempVars();

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

/**
 * Determine which data should be used when we're calculating the average lifetime for an initial guess. 
 * Since we won't take the IRF into account we need to only use data after the gate is mostly closed.
 * 
 * \param idx The pixel index, used if we have a spatially varying IRF
*/
int FLIMGlobalFitController::DetermineMAStartPosition(int idx)
{
   double c;
   int j_last = 0;
   int start = 0;
   

   // Get reference to timepoints
   double* t = data->GetT();
   
   // Get IRF for the pixel position idx
   double *irf = this->irf_buf + idx * n_irf * n_chan;

   //===================================================
   // If we have a scatter IRF use data after cumulative sum of IRF is
   // 95% of total sum (so we ignore any potential tail etc)
   //===================================================
   if (!ref_reconvolution)
   {      
      // Determine 95% of IRF
      double irf_95 = 0;
      for(int i=0; i<n_irf; i++)
         irf_95 += irf[i];
      irf_95 *= 0.95;
   
      // Cycle through IRF to find time at which cumulative IRF is 95% of sum.
      // Once we get there, find the time gate in the data immediately after this time
      c = 0;
      for(int i=0; i<n_irf; i++)
      {
         c += irf[i];
         if (c >= irf_95)
         {
            for (int j=j_last; j<data->n_t; j++)
               if (t[j] > t_irf[i])
               {
                  start = j;
                  j_last = j;
                  break;
               }
            break;
         }   
      }
   }

   //===================================================
   // If we have reference IRF, use data after peak of reference which should roughly
   // correspond to end of gate
   //===================================================
   else
   {
      // Cycle through IRF, if IRF is larger then previously seen find the find the 
      // time gate in the data immediately after this time. Repeat until end of IRF.
      c = 0;
      for(int i=0; i<n_irf; i++)
      {
         if (irf[i] > c)
         {
            c = irf[i];
            for (int j=j_last; j<data->n_t; j++)
               if (t[j] > t_irf[i])
               {
                  start = j;
                  j_last = j;
                  break;
               }
         }
      }
   }


   return start;
}

/**
 * Estimate average lifetime of a decay as an intial guess
 */ 
double FLIMGlobalFitController::EstimateAverageLifetime(float decay[], int p)
{
   double* t   = data->GetT();
   double  tau = 0;
   int     start;
   
   //if (image_irf)
   //   start = DetermineMAStartPosition(p);
   //else
      start = ma_start;
     
   //===================================================
   // For TCSPC data, calculate the mean arrival time and apply a correction for
   // the data censoring (i.e. finite measurement window)
   //===================================================

   if (data->data_type == DATA_TYPE_TCSPC)
   {
      double  n  = 0;


      for(int i=start; i<n_t; i++)
      {
         tau += decay[i] * (t[i] - t[start]);
         n   += decay[i];
      }
   
      // If polarisation resolevd add perp decay using I = para + 2*g*perp
      if (polarisation_resolved)
      {
         for(int i=start; i<n_t; i++)
         {
            tau += 2 * g_factor * decay[i+n_t] * (t[i] - t[start]);
            n   += 2 * g_factor * decay[i+n_t];
         }
      }

      tau = tau / n;

      // Apply correction for measurement window
      double tau1 = tau;
      double T = t[n_t-1]-t[start];
      for(int i=0; i<10; i++)  
         tau = tau + T / (exp(T/tau1)-1);

   }

   //===================================================
   // For widefield data, apply linearised model 
   //===================================================

   else
   {
      double sum_t  = 0;
      double sum_t2 = 0;
      double sum_tlnI = 0;
      double sum_lnI = 0;
      double dt;
      int    N;


      N = n_t-start;

      for(int i=start; i<n_t; i++)
      {
         dt = t[i]-t[start];

         sum_t += dt;
         sum_t2 += dt * dt;

         sum_tlnI += dt * log(decay[i]);
         sum_lnI  += log(decay[i]);

      }

      tau  = - (N * sum_t2   - sum_t * sum_t);
      tau /=   (N * sum_tlnI - sum_t * sum_lnI);

   }

   return tau;

}
 
/** 
 * Calculate g factor for polarisation resolved data
 *
 * g factor gives relative sensitivity of parallel and perpendicular channels, 
 * and so can be determined from the ratio of the IRF's for the two channels 
*/
double FLIMGlobalFitController::CalculateGFactor()
{
   if (polarisation_resolved)
   {
      double perp = 0;
      double para = 0;
      for(int i=0; i<n_irf; i++)
      {
         para += irf[i];
         perp += irf[i+n_irf];
      }

      g_factor = para / perp;
   }
   else
   {
      g_factor = 1;
   }

   return g_factor;
}


void FLIMGlobalFitController::Init()
{

   cur_region = -1;
   next_pixel  = 0;
   threads_active = 0;
   threads_started = 0;

   int s_max;

   getting_fit    = false;
   use_kappa      = true;
   calculate_errs = false;

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

   decay_group_buf = new int[n_exp];

   if (beta_global)
   {

      // Check to make sure that decay groups increase
      // contiguously from zero
      int cur_group = 0;
      if (decay_group != NULL)
      {
         for(int i=0; i<n_exp; i++)
         {
            if (decay_group[i] == (cur_group + 1))
            {
               cur_group++;
            }
            else if (decay_group[i] != cur_group)
            {
               decay_group = NULL;
               break;
            }
         }
      }
   }
   else
   {
      decay_group = NULL;
      n_decay_group = 1;
   }

   if (decay_group == NULL)
      for(int i=0; i<n_exp; i++)
         decay_group_buf[i] = 0;
   else
      for(int i=0; i<n_exp; i++)
         decay_group_buf[i] = decay_group[i];





   // Copy IRF, padding to ensure we have an even number of points so we can 
   // use SSE primatives in convolution
   //------------------------------
   int n_irf_rep;
   
   if (image_irf) 
      n_irf_rep =  data->n_px;
   else if (t0_image)
      n_irf_rep = 1 + n_thread;
   else 
      n_irf_rep = 1;

   int a_n_irf = (int) ( ceil(n_irf / 2.0) * 2 );
   int irf_size = a_n_irf * n_chan * n_irf_rep;
   #ifdef _WINDOWS
      irf_buf   = (double*) _aligned_malloc(irf_size*sizeof(double), 16);
      t_irf_buf = (double*) _aligned_malloc(a_n_irf*sizeof(double), 16);
   #else
      irf_buf  = new double[irf_size]; 
      t_irf_buf  = new double[a_n_irf]; 
   #endif
      

   double dt = t_irf[1]-t_irf[0];

   for(int j=0; j<n_irf_rep; j++)
   {
      int i;
      for(i=0; i<n_irf; i++)
      {
         t_irf_buf[i] = t_irf[i];
         for(int k=0; k<n_chan; k++)
             irf_buf[j*a_n_irf*n_chan+k*a_n_irf+i] = irf[j*n_irf*n_chan+k*n_irf+i];
      }
      for(i=i; i<a_n_irf; i++)
      {
         t_irf_buf[i] = t_irf_buf[i-1] + dt;
         for(int k=0; k<n_chan; k++)
            irf_buf[j*a_n_irf*n_chan+k*a_n_irf+i] = irf_buf[j*a_n_irf*n_chan+k*a_n_irf+i-1];
      }
   }

   n_irf = a_n_irf;

   
   if (data->global_mode != MODE_PIXELWISE)
      algorithm = ALG_LM;

   
   if (data->global_mode == MODE_PIXELWISE)
   {
      status->SetNumRegion(data->n_masked_px);
      n_fitters = min(data->n_px,n_thread);
   }
   else
   {
      status->SetNumRegion(data->n_regions_total);
      n_fitters = min(data->n_regions_total,n_thread);
   }

   
   if (data->n_regions_total == 0)
   {
      error = ERR_FOUND_NO_REGIONS;
      return;
   }

   // Only create as many threads as there are regions if we have
   // fewer regions than maximum allowed number of thread
   //---------------------------------------

   
   if (n_fitters == 1)
      n_omp_thread = n_thread;
   else
      n_omp_thread = 1;

   thread_handle = new tthread::thread*[ n_fitters ];
   for(int i=0; i<n_fitters; i++)
      thread_handle[i] = NULL;

   // Supplied t_rep in seconds, convert to ps
   this->t_rep = t_rep * 1e12;

   s_max = data->max_region_size;

   n_fret_group = n_fret + inc_donor;        // Number of decay 'groups', i.e. FRETing species + no FRET

   n_v = n_exp - n_fix;                      // Number of unfixed exponentials
   
   n_exp_phi = (beta_global ? n_decay_group : n_exp);
   
   n_beta = (fit_beta == FIT_GLOBALLY) ? n_exp - n_decay_group : 0;
   
   nl  = n_v + n_fret_v + n_beta + n_theta_v;                                // (varp) Number of non-linear parameters to fit
   p   = (n_v + n_beta)*n_fret_group*n_pol_group + n_exp_phi * n_fret_v + n_theta_v;    // (varp) Number of elements in INC matrix 
   l   = n_exp_phi * n_fret_group * n_pol_group;          // (varp) Number of linear parameters

   if (data->global_mode == MODE_GLOBAL)
   {
      s = data->n_masked_px;                              // (varp) Number of pixels (right hand sides)
   }
   else
      s = data->n_px;

   max_dim = max(n_irf,n_t);
   max_dim = (int) (ceil(max_dim/4.0) * 4);


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

   // If using MLE, need an extra non-linear scaling factor
   if (algorithm == ALG_ML)
   {
      nl += l;
   }

   if (data->global_mode == MODE_GLOBAL)
      n = data->GetResampleNumMeas(0);
   else
      n = n_meas;

   ndim       = max( n, 2*nl+3 );
   nmax       = n;
   int lps    = l + s + 1;
   

   calculate_mean_lifetimes = !beta_global && n_exp > 1;

   int n_j = fit_fret ? n_fret_group : n_exp_phi;

   if (!polarisation_resolved && n_j == 1)
      lmax = l;
   else
      lmax = l+1; // for I, which we will compute afterwards

   exp_buf_size = n_exp * n_pol_group * exp_dim * N_EXP_BUF_ROWS;

   int alf_size = (data->global_mode == MODE_PIXELWISE) ? data->n_masked_px : data->n_regions_total;

   try
   {
      lin_params   = new float[ data->n_masked_px * lmax ]; //ok
      chi2         = new float[ data->n_masked_px ]; //ok
      I            = new float[ data->n_masked_px ];

      if (polarisation_resolved)
         r_ss      = new float[ data->n_masked_px ];

      if (data->has_acceptor)
         acceptor  = new float[ data->n_masked_px ];

      ierr         = new int[ data->n_regions_total ];
      success      = new float[ data->n_regions_total ];
      alf          = new float[ alf_size * nl ]; //ok
      
      if (calculate_mean_lifetimes)
      {
         w_mean_tau   = new float[ data->n_masked_px ];  
         mean_tau     = new float[ data->n_masked_px ];  
      }
      

      alf_local    = new double[ n_fitters * nl ]; //free ok
      y            = new float[ n_fitters * s * n_meas ]; //free ok 
      irf_idx      = new int[ n_fitters * s ];

      local_decay  = new float[ n_fitters * n_meas ]; //ok
      lin_local    = new float[ n_fitters * lmax ]; //ok
      w            = new float[ n_fitters * n_meas ]; //free ok

      cur_alf      = new double[ n_fitters * nl ]; //ok
      cur_irf_idx  = new int[ n_fitters ];

      #ifdef _WINDOWS
         exp_buf   = (double*) _aligned_malloc( n_thread * n_fret_group * exp_buf_size * sizeof(double), 16 ); //ok
       #else
         exp_buf   = new double[n_thread * n_fret_group * exp_buf_size];
       #endif
      
      tau_buf      = new double[ n_thread * (n_fret+1) * n_exp ]; //free ok 
      beta_buf     = new double[ n_thread * n_exp ]; //free ok
      theta_buf    = new double[ n_thread * n_theta ]; //free ok 
      fit_buf      = new double[ n_thread * n_meas ]; // free ok 
      count_buf    = new double[ n_thread * n_meas ]; // free ok 
      adjust_buf   = new float[ n_meas ]; // free ok 

    
      irf_max      = new int[n_meas]; //free ok

      if (calculate_errs) 
         conf_lim  = new double[ n_thread * nl ]; //free ok

      //locked_param = new int[n_thread]; //ok
      //locked_value = new double[n_thread]; //ok

      //local_irf    = new double*[n_thread]; //ok

      init = true;
   }
   catch(std::exception e)
   {
      error =  ERR_OUT_OF_MEMORY;
      CleanupTempVars();
      CleanupResults();
      return;
   }



   SetNaN(alf, alf_size * nl );
   SetNaN(chi2, data->n_masked_px );
   SetNaN(I, data->n_masked_px );
   SetNaN(r_ss, data->n_masked_px );
   SetNaN(lin_params, data->n_masked_px * lmax);

   for(int i=0; i<data->n_regions_total; i++)
   {
      success[i] = 0;
      ierr[i] = 0;
   }


   if (n_irf > 2)
      t_g = t_irf[1] - t_irf[0];
   else
      t_g = 1;


   // Check to see if gates are equally spaced
   //---------------------------------------------
   eq_spaced_data = true;
   double dt0 = t[1]-t[0];
   for(int i=2; i<n_t; i++)
   {
      double dt = t[i] - t[i-1];
      if (abs(dt - dt0) > 1e-5)
      {
         eq_spaced_data = false;
         break;
      }
         
   }

   CalculateIRFMax(n_t,t);
   ma_start = DetermineMAStartPosition(0);

   // Create fitting objects
   projectors.reserve(n_fitters);

   for(int i=0; i<n_fitters; i++)
   {
      if (algorithm == ALG_ML)
         projectors.push_back( new MaximumLikelihoodFitter(this, l, nl, nmax, ndim, p, t, &(status->terminate)) );
      else
         projectors.push_back( new VariableProjector(this, s, l, nl, nmax, ndim, p, t, image_irf | (t0_image != NULL), weighting, n_omp_thread, &(status->terminate)) );
   }

   for(int i=0; i<n_fitters; i++)
   {
      if (projectors[i].err != 0)
         error = projectors[i].err;
   }


   // Select correct convolution function for data type
   //-------------------------------------------------
   if (data->data_type == DATA_TYPE_TCSPC)
   {
      Convolve = conv_irf_tcspc;
      ConvolveDerivative = ref_reconvolution ? conv_irf_deriv_ref_tcspc : conv_irf_deriv_tcspc;
   }
   else
   {
      Convolve = conv_irf_timegate;
      ConvolveDerivative = ref_reconvolution ? conv_irf_deriv_ref_timegate : conv_irf_deriv_timegate;
   }

   // Setup adjust buffer which will be subtracted from the data
   SetupAdjust(0, adjust_buf, (fit_scatter == FIX) ? (float) scatter_guess : 0, 
                              (fit_offset == FIX)  ? (float) offset_guess  : 0, 
                              (fit_tvb == FIX)     ? (float) tvb_guess     : 0);

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

   SetOutputParamNames();

}


void FLIMGlobalFitController::SetOutputParamNames()
{
   char buf[1024];

   // Parameters associated with non-linear parameters (or fixed)

   for(int i=0; i<n_exp; i++)
   {
      sprintf(buf,"tau_%i",i+1);
      param_names.push_back(buf);
   }

   if (fit_beta != FIT_LOCALLY)
      for(int i=0; i<n_exp; i++)
      {
         sprintf(buf,"beta_%i",i+1);
         param_names.push_back(buf);
      }

   for(int i=0; i<n_fret; i++)
   {
      sprintf(buf,"E_%i",i+1);
      param_names.push_back(buf);
   }

   for(int i=0; i<n_theta; i++)
   {
      sprintf(buf,"theta_%i",i+1);
      param_names.push_back(buf);
   }
   
   if (fit_offset == FIT_GLOBALLY)
      param_names.push_back("offset");

   if (fit_scatter == FIT_GLOBALLY)
      param_names.push_back("scatter");

   if (fit_tvb == FIT_GLOBALLY)
      param_names.push_back("tvb");

   if (ref_reconvolution == FIT_GLOBALLY)
      param_names.push_back("tau_ref");

   n_nl_output_params = (int) param_names.size();

   if (fit_offset == FIT_LOCALLY)
      param_names.push_back("offset");

   if (fit_scatter == FIT_LOCALLY)
      param_names.push_back("scatter");

   if (fit_tvb == FIT_LOCALLY)
      param_names.push_back("tvb");

   // Now that parameters that are derived from the linear parameters

   if (fit_beta == FIT_LOCALLY && n_exp > 1)
      for(int i=0; i<n_exp; i++)
      {
         sprintf(buf,"beta_%i",i+1);
         param_names.push_back(buf);
      }

   if (n_decay_group > 1)
      for(int i=0; i<n_decay_group; i++)
      {
         sprintf(buf,"gamma_%i",i+1);
         param_names.push_back(buf);
      }

   if (fit_fret == FIT && inc_donor)
   {
      sprintf(buf,"gamma_0");
      param_names.push_back(buf);
   }

   if (n_fret_group > 1)
      for(int i=0; i<n_fret; i++)
      {
         sprintf(buf,"gamma_%i",i+1);
         param_names.push_back(buf);
      }

   if (polarisation_resolved)
      param_names.push_back("r_0");

   for(int i=0; i<n_theta; i++)
   {
      sprintf(buf,"r_%i",i+1);
      param_names.push_back(buf);
   }

   param_names.push_back("I0");
   
   // Parameters we manually calculate at the end
   
   param_names.push_back("I");

   if ( acceptor != NULL )
      param_names.push_back("acceptor");

   if (polarisation_resolved)
      param_names.push_back("r_ss");


   if (calculate_mean_lifetimes)
   {
      param_names.push_back("mean_tau");
      param_names.push_back("w_mean_tau");
   }

   param_names.push_back("chi2");

   n_output_params = (int) param_names.size();

   param_names_ptr = new const char*[n_output_params];

   for(int i=0; i<n_output_params; i++)
      param_names_ptr[i] = param_names[i].c_str();

}


FLIMGlobalFitController::~FLIMGlobalFitController()
{
   status->Terminate();

   while (status->IsRunning()) {}

   CleanupResults();
   CleanupTempVars();

   delete status;
   delete[] params;

}

/** 
 * Calculate IRF values to include in convolution for each time point
 *
 * Accounts for the step function in the model - we don't want to convolve before the decay starts
*/
void FLIMGlobalFitController::CalculateIRFMax(int n_t, double t[])
{
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


int FLIMGlobalFitController::GetErrorCode()
{
   return error;
}

void FLIMGlobalFitController::SetupAdjust(int thread, float adjust[], float scatter_adj, float offset_adj, float tvb_adj)
{

   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   for(int i=0; i<n_meas; i++)
      adjust[i] = 0;

   add_irf(thread, 0, adjust, n_r, scale_fact);

   for(int i=0; i<n_meas; i++)
      adjust[i] = adjust[i] * scatter_adj + offset_adj;

   if (tvb_profile != NULL)
      for(int i=0; i<n_meas; i++)
         adjust[i] += (float) (tvb_profile[i] * tvb_adj);
}




/*===============================================
  ErrMinFcn
  ===============================================*/
/*
double FLIMGlobalFitController::ErrMinFcn(double x, ErrMinParams& params)
{

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
   float *lin_params_err = this->lin_params_err + params.thread * l * n_px;
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
  
   return 0;
}

*/

void FLIMGlobalFitController::CleanupTempVars()
{

   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);
   
   ClearVariable(y);

   boost::ptr_vector<AbstractFitter>::iterator iter = projectors.begin();
   while (iter != projectors.end())
   {
        iter->ReleaseResidualMemory();
        iter++;
   }

   _ASSERTE(_CrtCheckMemory());
}

void FLIMGlobalFitController::CleanupResults()
{

   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);

   init = false;
      
   ClearVariable(lin_local);
   ClearVariable(alf_local);
   ClearVariable(tau_buf);
   ClearVariable(beta_buf);
   ClearVariable(theta_buf);
   ClearVariable(chan_fact);
   ClearVariable(cur_alf);
   ClearVariable(cur_irf_idx);

   ClearVariable(I);
   ClearVariable(chi2);
   ClearVariable(alf);
   ClearVariable(lin_params);
   ClearVariable(ierr);
   ClearVariable(success);
   ClearVariable(w_mean_tau);
   ClearVariable(mean_tau);
   ClearVariable(r_ss);
   ClearVariable(acceptor);

   #ifdef _WINDOWS
   
      if (exp_buf != NULL)
      {
         _aligned_free(exp_buf);
         exp_buf = NULL;
      }
      if (irf_buf != NULL)
      {
         _aligned_free(irf_buf);
         irf_buf = NULL;
      }
      if (t_irf_buf != NULL)
      {
         _aligned_free(t_irf_buf);
         t_irf_buf = NULL;
      }
   
   #else
   
      ClearVariable(exp_buf);
      ClearVariable(irf_buf);
      ClearVariable(t_irf_buf);
   
   #endif

      ClearVariable(fit_buf);


      ClearVariable(irf_max);
      ClearVariable(fit_buf);
      ClearVariable(count_buf);
      ClearVariable(adjust_buf);
      ClearVariable(conf_lim);
      ClearVariable(local_decay);
      ClearVariable(decay_group_buf);

      ClearVariable(irf_idx);

      ClearVariable(y);
      ClearVariable(w);
      
      ClearVariable(param_names_ptr);

      if (result_map_filename != NULL)
      {
         remove(result_map_filename);
         free(result_map_filename);
         result_map_filename = NULL;
      }

      if (data != NULL)
      {
         delete data;
         data = NULL;
      }

   if (thread_handle != NULL)
   {
      for(int i=0; i<n_fitters; i++)
      {
         if (thread_handle[i] != NULL)
            delete thread_handle[i];
      }
      delete[] thread_handle;
      thread_handle = NULL;
   }

     _ASSERTE(_CrtCheckMemory());
}
