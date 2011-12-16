#ifndef _FLIMGLOBALFITCONTROLLER_H
#define _FLIMGLOBALFITCONTROLLER_H

#ifdef _MSC_VER
#  pragma warning(disable: 4512) // assignment operator could not be generated.
#  pragma warning(disable: 4510) // default constructor could not be generated.
#  pragma warning(disable: 4610) // can never be instantiated - user defined constructor required.
#endif

#include <boost/interprocess/file_mapping.hpp>

#include "FitStatus.h"
#include "ModelADA.h"
#include <stdio.h>
#include "FLIMGlobalAnalysis.h"
#include "tinythread.h"


#define _CRTDBG_MAPALLOC

#define DATA_DIRECT 0
#define DATA_MAPPED 1

#define MODE_STANDARD     0
#define MODE_POLARISATION 1

class ErrMinParams;

class WorkerParams
{
public:
   FLIMGlobalFitController* controller;
   int thread;
};

class FLIMGlobalFitController
{
public:

   int n_group; int n_px; int *n_regions; int global_mode;
   int data_type; double *data; int *mask; 
   int n_t; double *t;
   int n_irf; double *t_irf; double *irf; double pulse_pileup;
   int n_exp; int n_fix; 
   double *tau_min; double *tau_max;
   int single_guess; double *tau_guess;
   int fit_beta; double *fixed_beta;
   int fit_t0; double t0_guess; 
   int fit_offset; double offset_guess; 
   int fit_scatter; double scatter_guess;
   int fit_tvb; double tvb_guess; double *tvb_profile;
   int fit_fret; int inc_Rinf; double *R_guess; int n_fret; int n_fret_fix; int n_fret_v;
   int pulsetrain_correction; double t_rep;
   int ref_reconvolution; double ref_lifetime_guess;
   double *tau; double *tau_err; double *I0; double *beta; double *beta_err; 
   double *R; double *R_err; double *gamma; double *t0; 
   double *offset; double *offset_err; double *scatter; double *scatter_err ;
   double *tvb;  double *tvb_err; double *ref_lifetime; double *ref_lifetime_err;
   double *chi2; int *ierr; int algorithm;
   int n_thread; int (*callback)();
   int error;

   char *data_file; int data_mode;
   
   boost::interprocess::file_mapping data_map_file;

   tthread::thread **thread_handle;

   float *irf_f, *t_irf_f;

   bool polarisation_resolved;
   int n_chan, n_meas, n_pol_group;
   int n_theta, n_theta_fix, n_theta_v, n_r, inc_rinf;
   double *theta_guess;
   double *theta, *theta_err, *r;
   double *chan_fact;
   bool no_linear_exps;

   int use_magic_decay;
   double *magic_decay;


   int *mask_buf;
   int *n_regions_buf;
   double *t_irf_buf;
   double *irf_buf;
   double *tvb_profile_buf;

   int *sort_idx_buf;
   double *sort_buf;
   double *exp_buf;
   double *tau_buf;
   double *beta_buf;
   double *theta_buf;
   double *fit_buf;
   double *adjust_buf;
   double *count_buf;

   int *irf_max;
   double *resampled_irf;

   int max_dim, exp_dim;
   int *r_start;
   int n_regions_total;

   integer static_store[1000];
   
   bool use_kappa;

   integer s; integer lmax; integer l; integer nl; integer n; integer nmax; integer ndim; 
   integer lpps1; integer lps; integer pp2; integer iv; integer p; integer iprint; integer lnls1; integer n_v;
	double *y; double *w; double *alf; double *alf_best; double *a; double *b; double *lin_params; 
   integer n_exp_phi, n_decay_group, exp_buf_size, tau_start;

   double *a_cpy;

   bool beta_global;
   int n_beta;

   int grid_search, grid_size, grid_factor, grid_positions, grid_iter, chi2_map_mode;
   double *var_min, *var_max, *grid, *var_buf;

   tthread::mutex cleanup_mutex;
   tthread::mutex mutex;

   int first_call;
   int runAsync;
   int init;
   bool has_fit;

   FitStatus *status;
   WorkerParams* params;

   int alf_t0_idx, alf_offset_idx, alf_scatter_idx, alf_iR6_idx, alf_beta_idx, alf_theta_idx, alf_tvb_idx, alf_ref_idx;
   double t_g;

   int *locked_param;
   double *locked_value;
   bool getting_fit;
   double* conf_lim;
   bool calculate_errs;
   double* lin_params_err;
   double* alf_err;

   bool anscombe_tranform;

   conv_func Convolve;
   conv_deriv_func ConvolveDerivative;

   FLIMGlobalFitController(int n_group, int n_px, int n_regions[], int global_mode,
                           int mask[], int n_t, double t[],
                           int n_irf, double t_irf[], double irf[], double pulse_pileup,
                           int n_exp, int n_fix, 
                           double tau_min[], double tau_max[], 
                           int single_guess, double tau_guess[],
                           int fit_beta, double fixed_beta[],
                           int use_magic, double magic_angle[],
                           int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                           int fit_t0, double t0_guess, 
                           int fit_offset, double offset_guess, 
                           int fit_scatter, double scatter_guess,
                           int fit_tvb, double tvb_guess, double tvb_profile[],
                           int n_fret, int n_fret_fix, int inc_Rinf, double R_guess[],
                           int pulsetrain_correction, double t_rep,
                           int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                           double tau[], double I0[], double beta[], double R[], double gamma[],
                           double theta[], double r[],
                           double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                           int calculate_errs, double tau_err[], double beta_err[], double R_err[], double theta_err[],
                           double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                           double chi2[], int ierr[],
                           int n_thread, int runAsync, int callback());


   void SetData(double data[], int data_type);
   int SetData(char* data_file, int data_type);

   void SetChi2MapMode(int grid_size, double grid[]);
   void SetPolarisationMode(int mode);

   int RunWorkers();

   ~FLIMGlobalFitController();

   void Init();

   int  GetNumGroups();
   int  GetNumThreads();
   int  GetNumRegions(int g);
   int  GetErrorCode();
   void SetGlobalVariables();
   int  ProcessRegion(int g, int r, int thread);
   void SetupAdjust(double adjust[], double scatter_adj, double offset_adj, double tvb_adj);

   int GetFit(int ret_group_start, int n_ret_groups, int n_fit, int fit_mask[], int n_t, double t[], double fit[]);

   int SimulateData(double I0[], double beta[], double data[]);

   double ErrMinFcn(double x, ErrMinParams& params);


   void CleanupTempVars();

private:
   void CalculateIRFMax(int n_t, double t[]);
   void CalculateResampledIRF(int n_t, double t[]);
   void CleanupResults();
   double CalculateChi2(int region, int s_thresh, double y[], double w[], double a[], double lin_params[], double adjust_buf[], double fit_buf[], int mask_buf[], double chi2[]);

};

class ErrMinParams
{
public:
   int s_thresh;
   int r_idx;
   double chi2;
   int thread;
   double param_value;
   int region;
   int group;
   FLIMGlobalFitController* gc;

   double f(double x)
   {
      return gc->ErrMinFcn(x,*this);
   }
};


void WorkerThread(void* wparams);

extern int hooke(FLIMGlobalFitController* gc, ErrMinParams params, double startpt, double& endpt, double rho, double epsilon, int itermax);


#endif