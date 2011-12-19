
#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include "boost/bind.hpp"
#include <limits>
#include <exception>

#include "FLIMGlobalFitController.h"
#include "IRFConvolution.h"

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

FLIMGlobalFitController::FLIMGlobalFitController(int n_group, int n_px, int n_regions[], int global_mode,
                                                 int mask[], int n_t, double t[],
                                                 int n_irf, double t_irf[], double irf[], double pulse_pileup,
                                                 int n_exp, int n_fix, 
                                                 double tau_min[], double tau_max[], 
                                                 int single_guess, double tau_guess[],
                                                 int fit_beta, double fixed_beta[],
                                                 int use_magic_decay, double magic_decay[],
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
   n_group(n_group), n_px(n_px), n_regions(n_regions), global_mode(global_mode),
   mask(mask), n_t(n_t), t(t),
   n_irf(n_irf),  t_irf(t_irf), irf(irf), pulse_pileup(pulse_pileup),
   n_exp(n_exp), n_fix(n_fix), 
   tau_min(tau_min), tau_max(tau_max),
   single_guess(single_guess), tau_guess(tau_guess),
   fit_beta(fit_beta), fixed_beta(fixed_beta),
   use_magic_decay(use_magic_decay), magic_decay(magic_decay),
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
   status = new FitStatus(this,n_group,n_thread,callback); //free ok
   params = new WorkerParams[n_thread]; //free ok
}

int FLIMGlobalFitController::RunWorkers()
{
   
   if (status->IsRunning())
      return ERR_FIT_IN_PROGRESS;

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
      int thread = p->thread;

      int idx = 0;

      if (thread >= controller->n_regions_total)
	      return;

      controller->status->AddThread();

      for(int g=0; g<controller->n_group; g++)
      {
         for(int r=1; r<=controller->n_regions[g]; r++)
         {
            if(idx % controller->n_thread == thread)
            {
               if (!controller->init)
                  break;

               controller->ProcessRegion(g,r,thread);

			   if (controller->ierr[0] > -1)
				   int a = 1;

               if (r == controller->n_regions[g])
                  controller->status->FinishedGroup(thread);
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
   catch(exception e)
   {
      e = e;

   }
   return;
}




int FLIMGlobalFitController::SetData(char* data_file, int data_type)
{
   int error = 0;

   data_mode = DATA_MAPPED;
   this->data_type = data_type;
   
   try
   {
      data_map_file = boost::interprocess::file_mapping(data_file,boost::interprocess::read_only);
   }
   catch(std::exception& e)
   {
      return -1;
   }

   return error;


}


void FLIMGlobalFitController::SetData(double data[], int data_type)
{
   this->data = data;
   this->data_type = data_type;
   data_mode = DATA_DIRECT;
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

void FLIMGlobalFitController::Init()
{
   int s_max, n_thread_buf;

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


   // Set up FRET parameters
   //---------------------------------------
   fit_fret = n_fret > 0;
   if (!fit_fret)
   {
      n_fret_fix = 0;
      inc_donor = true;
   }
   else
      n_fret_fix = min(n_fret_fix,n_fret);
 
   n_fret_v = n_fret - n_fret_fix;
      
   tau_start = inc_donor ? 0 : 1;

   beta_global = (fit_beta != FIT_LOCALLY);

   if (use_magic_decay)
   {
      n_exp = 1;
      n_fix = 1;
   }

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

      for(i=0; i<n_pol_group-1; i++)
      {
         chan_fact[i*2  ] =   2.0/3.0 - f*2.0/3.0;
         chan_fact[i*2+1] =  -(1.0/3.0) + f*2.0/3.0;
      }

      chan_fact[i*2] = 1.0/3.0 - f*1.0/3.0;
      chan_fact[i*2+1] = (1.0/3.0) + f*1.0/3.0;
     
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

   // Determine total number of regions across all groups
   //---------------------------------------
   n_regions_total = 0;
   for(int i=0; i<n_group; i++)
      n_regions_total += n_regions[i];

   // Only create as many threads as there are regions if we have
   // fewer regions than maximum allowed number of thread
   //---------------------------------------
   n_thread_buf = min(n_thread,n_regions_total);
  


   // Store copies of the mask, irf and regions so that we can use them after the fit
   // to get the fitted decays even if the user has removed the memory. These will 
   // be cleared when Cleanup() is called
   //----------------------------------------------------
   mask_buf        = new int[ n_group * n_px ]; //free ok
   irf_buf         = new double[ n_irf * n_chan ]; //free ok
   t_irf_buf       = new double[ n_irf ]; //free ok 
   n_regions_buf   = new int[ n_group ]; //free ok 
   tvb_profile_buf = new double[ n_meas ]; //free ok 

   thread_handle = new tthread::thread*[ n_thread ];

   if (mask != NULL)
   {
      for(int i=0; i<n_group*n_px; i++)
         mask_buf[i] = mask[i];
   }
   else
   {
      for(int i=0; i<n_group*n_px; i++)
         mask_buf[i] = 1;
   }

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


   for(int i=0; i<n_group; i++)
   {
      n_regions_buf[i] = n_regions[i];
   }

   // Supplied t_rep in seconds, convert to ps
   this->t_rep = t_rep * 1e12;

   // Determine largest region size
   //-----------------------------------------------
   s_max = 0;
   r_start = new int[n_group]; //free ok
   for(int i=0; i<n_group; i++)
   {
      if (i>0)
         r_start[i] = r_start[i-1] + n_regions[i-1];
      else
         r_start[0] = 0;

      for(int j=0; j<n_regions[i]; j++)
      {
         s = 0;
         for(int k=0; k<n_px; k++)
         {
            if(mask_buf[i*n_px+k]==(j+1))
                s++;
         }
         if (s > s_max)
            s_max = s;
      }
   }

   n_decay_group = n_fret + inc_donor;        // Number of decay 'groups', i.e. FRETing species + no FRET

/*
   if (n_decay_group == 1 && n_pol_group == 1 && fit_beta == FIT_GLOBALLY)
      no_linear_exps = true;
   else
      no_linear_exps = false;
*/
   no_linear_exps = false;
   
   n_v = n_exp - n_fix;                      // Number of unfixed exponentials
   
   /*
   if (beta_global)
      if (no_linear_exps)
         n_exp_phi = 0;
      else
         n_exp_phi = 1;
   else
         n_exp_phi = n_exp;       // Number of non-linear functions associated with each exponetial group 
   */
   n_exp_phi = (beta_global ? 1 : n_exp);
   
   n_beta = (fit_beta == FIT_GLOBALLY) ? n_exp - 1 : 0;
   
   nl  = n_v + n_fret_v + n_beta + n_theta_v;                                // (varp) Number of non-linear parameters to fit
   p   = (n_v + n_beta)*n_decay_group*n_pol_group + n_exp_phi * n_fret_v + n_theta_v;    // (varp) Number of elements in INC matrix 
   if (use_kappa)
      p  += (n_v > 1) ? n_v-1 : 0; // for kappa derivates
   l   = n_exp_phi * n_decay_group * n_pol_group;          // (varp) Number of linear parameters

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

   anscombe_tranform = (l == 1);
   
	ndim   = max( n_meas, 2*nl+3 );
	ndim   = max( ndim, s*n_meas - (s-1)*l );
	nmax   = n_meas;
   lpps1  = l + p + s + 1;
	lps    = l + s;
	pp2    = p + 2;
	iprint = -1;
	lnls1  = l + nl + s + 1;
   lmax   = l;

   if (nl == 0)
      lpps1  = l + s + 1;
   if (l == 0)
      lpps1 = nl + s + 1;

   exp_buf_size = n_exp * n_pol_group * exp_dim * N_EXP_BUF_ROWS;

   try
   {
      alf          = new double[ n_regions_total * nl ]; //free ok
      alf_best     = new double[ n_regions_total * nl ]; //free ok
	   a            = new double[ n_thread_buf * n_meas * lps ]; //free ok
      a_cpy        = new double[ n_thread_buf * n_meas * (l+1) ];
	   b            = new double[ n_thread_buf * ndim * pp2 ]; //free ok

      y            = new double[ n_thread_buf * s * n_meas ]; //free ok 
      lin_params   = new double[ n_regions_total * n_px * l ]; //free ok

      w            = new double[ n_thread_buf * n_meas ]; //free ok

      sort_buf     = new double[ n_thread_buf * n_exp ]; //free ok
      sort_idx_buf = new int[ n_thread_buf * n_exp ]; //free ok
      exp_buf      = new double[ n_thread_buf * n_decay_group * exp_buf_size ]; //free ok
      tau_buf      = new double[ n_thread_buf * (n_fret+1) * n_exp ]; //free ok 
      beta_buf     = new double[ n_thread_buf * n_exp ]; //free ok
      theta_buf    = new double[ n_thread_buf * n_theta ]; //free ok 
      fit_buf      = new double[ n_thread_buf * n_meas ]; // free ok 
      count_buf    = new double[ n_thread_buf * n_meas ]; // free ok 
      adjust_buf   = new double[ n_thread_buf * n_meas ]; // free ok 

      irf_max      = new int[n_meas]; //free ok
      resampled_irf= new double[n_meas]; //free ok 

      conf_lim     = new double[ n_thread_buf * nl ]; //free ok

      locked_param = new int[n_thread];
      locked_value = new double[n_thread];

      lin_params_err = new double[ n_thread_buf * n_px * l ]; //free ok
      alf_err        = new double[ n_thread_buf * nl ]; //free ok


      init = true;
   }
   catch(...)
   {
      error = ERR_OUT_OF_MEMORY;
   }

   if (n_irf > 2)
      t_g = t_irf[1] - t_irf[0];
   else
      t_g = 1;

   CalculateIRFMax(n_t,t);
   CalculateResampledIRF(n_t,t);

   // Select correct convolution function for data type
   //-------------------------------------------------
   if (data_type == DATA_TYPE_TCSPC)
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

   if (fit_fret == FIT)
   {
     alf_E_idx = idx;
     idx += n_fret_v;
   }

   if (fit_beta == FIT_GLOBALLY)
   {
     alf_beta_idx = idx;
     idx += n_beta;
   }

   alf_theta_idx = idx; 
   idx += n_v;


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
         while(k < n_irf && (t[i] - t_irf[k] - t0_guess) >= 0)
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

int FLIMGlobalFitController::GetNumGroups()
{
   return n_group;
}

int FLIMGlobalFitController::GetNumThreads()
{
   return n_thread;
}

int FLIMGlobalFitController::GetNumRegions(int g)
{
   if (g<n_group) 
      return n_regions_buf[g];
   else
      return 0;
}

int FLIMGlobalFitController::GetErrorCode()
{
   return error;
}

void FLIMGlobalFitController::SetupAdjust(double adjust[], double scatter_adj, double offset_adj, double tvb_adj)
{
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   for(int i=0; i<n_meas; i++)
      adjust[i] = 0;

   sample_irf(this, adjust, n_r, scale_fact);

   for(int i=0; i<n_meas; i++)
      adjust[i] = adjust[i] * scatter_adj + tvb_profile_buf[i] * tvb_adj + offset_adj;
}



double FLIMGlobalFitController::CalculateChi2(int region, int s_thresh, double y[], double w[], double a[], double lin_params[], double adjust_buf[], double fit_buf[], int mask_buf[], double chi2[])
{
   int i,j;
   // calcuate chi2
   double ft;
   double chi2_tot = 0;
   int i_thresh = 0;
   for(i=0; i<n_px; i++)
   {
 
      if(mask_buf[i] == region)
      {

         for(j=0; j<n_meas; j++)
         {
            ft = 0;
            for(int k=0; k<l; k++)
               ft += a[n_meas*k+j] * lin_params[ i_thresh*l + k ];

            ft += a[n_meas*l+j];

            fit_buf[j] = ft - y[i_thresh*n_meas + j];
            fit_buf[j] *= fit_buf[j] * w[j];

            if (j>0)
               fit_buf[j] += fit_buf[j-1];
         }

         if (chi2 != NULL)
         {
            chi2[i] = fit_buf[n_meas-1] / (n_meas - nl/s_thresh - l);
            if (chi2[i] == std::numeric_limits<double>::infinity( ))
               chi2[i] = 0;
         }

         if (fit_buf[n_meas-1] < 1e5)
            chi2_tot += fit_buf[n_meas-1];
         else
            chi2_tot = chi2_tot;

         i_thresh++;


      }
   }

   //chi2_tot /= (n_meas * s_thresh - nl - l * s_thresh);
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

   int        *mask_buf = this->mask_buf + params.group * n_px;
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

   c2 = CalculateChi2(params.region, params.s_thresh, y, w, a, lin_params_err, adjust_buf, fit_buf, mask_buf, NULL);

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
   this->n_t = n_t;
   this->n_meas = n_t*n_chan;
   this->nmax = this->n_meas;

   getting_fit = true;

   exp_dim = max(n_irf*n_chan,n_meas);
   exp_buf_size = n_exp * exp_dim * n_pol_group * N_EXP_BUF_ROWS;

   exp_buf = new double[ n_decay_group * exp_buf_size ];
   irf_max = new int[ n_meas ];
   resampled_irf = new double[ n_meas ];

   CalculateIRFMax(n_t,t);
   CalculateResampledIRF(n_t,t);

   double *adjust = new double[n_meas];
   SetupAdjust(adjust, (fit_scatter == FIX) ? scatter_guess : 0, 
                       (fit_offset == FIX)  ? offset_guess  : 0, 
                       (fit_tvb == FIX )    ? tvb_guess     : 0);

   
   int s = 1;
   int lp1 = l+p+1;
   int lpp2 = l+p+2;
   int lps = l+s; 
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
      for(int r=1; r<=n_regions_buf[group]; r++)
      {
         process_group = false;
         for(int p=0; p<n_px; p++)
            if (fit_mask[n_px*g+p] && mask_buf[group*n_px+p] == r)
               process_group = true;

         if (process_group)
         {

            r_idx = r_start[group] + (r-1);
            ada(&s,&lp1,&nl,(int*)&n_meas,&nmax,(int*)&n_meas,&lpp2,&pp2,&iv,at,bt,inc,t,alf+r_idx*nl,&isel,(int*)this, &thread);

            px_thresh = 0;
            for(int p=0; p<n_px; p++)
            {
               if (fit_mask[n_px*g+p])
               {
         
                  if (mask_buf[group*n_px+p] == r)
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

               if (mask_buf[group*n_px+p] == r)
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

   delete[] adjust;

   this->n_t = n_t_buf;
   this->n_meas = this->n_t * n_chan;
   this->nmax = n_meas;

   
   return 0;

}


int FLIMGlobalFitController::SimulateData(double I0[], double beta[], double data[])
{

   for(int p=0; p<n_px; p++)
   {
      for(int i=0; i<l; i++)
         lin_params[p*l+i] = I0[p] * beta[p*l+i];
   }

   GetFit(0, 1, n_px, mask_buf, n_t, t, data);

   return 0;

}

void FLIMGlobalFitController::CleanupTempVars()
{
   tthread::lock_guard<tthread::mutex> guard(cleanup_mutex);
   
   ClearVariable(a);
   ClearVariable(b);
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
   tthread::lock_guard<tthread::mutex> guard(cleanup_mutex);

   init = false;
   ClearVariable(lin_params);
   ClearVariable(a_cpy);
   ClearVariable(alf);
   ClearVariable(alf_best);
   ClearVariable(mask_buf);
   ClearVariable(tau_buf);
   ClearVariable(beta_buf);
   ClearVariable(theta_buf);
   ClearVariable(irf_buf);
   ClearVariable(t_irf_buf);
   ClearVariable(tvb_profile_buf);
   ClearVariable(n_regions_buf);
   ClearVariable(r_start);
   ClearVariable(chan_fact);
   ClearVariable(locked_param);
   ClearVariable(locked_value);

   if (thread_handle != NULL)
   {
      delete[] thread_handle;
      thread_handle = NULL;
   }

}
