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
#include "FLIMData.h"
#include <stdio.h>
#include "FLIMGlobalAnalysis.h"
#include "tinythread.h"

#include <boost/ptr_container/ptr_vector.hpp>
#include <boost/interprocess/mapped_region.hpp>

#include "VariableProjector.h"

#include "FlagDefinitions.h"

typedef double* DoublePtr;  

#define USE_GLOBAL_BINNING_AS_ESTIMATE    false
#define _CRTDBG_MAPALLOC


class ErrMinParams;

class WorkerParams 
{
public:
   WorkerParams(FLIMGlobalFitController* controller, int thread) : 
   controller(controller), thread(thread) 
   {};
   
   WorkerParams() 
   { 
      controller = NULL;
      thread = NULL;
   };

   WorkerParams operator=(const WorkerParams& wp)
   {
      controller = wp.controller;
      thread = wp.thread;
      return wp;
   }; 
   
   FLIMGlobalFitController* controller;
   int thread;
};

class FLIMGlobalFitController;

class FLIMGlobalFitController : public FitModel
{
public:

   int n_t; double *t;
   int n_irf; double *t_irf; double *irf; double pulse_pileup;
   int n_exp; int n_fix; 
   double *tau_min; double *tau_max;
   int estimate_initial_tau; double *tau_guess;
   int fit_beta; double *fixed_beta;
   int fit_t0; double t0_guess; 
   int fit_offset; double offset_guess; 
   int fit_scatter; double scatter_guess;
   int fit_tvb; double tvb_guess; double *tvb_profile;
   int fit_fret; int inc_donor; double *E_guess; int n_fret; int n_fret_fix; int n_fret_v;
   int pulsetrain_correction; double t_rep;
   int ref_reconvolution; double ref_lifetime_guess;
   int *ierr; int algorithm;
   int n_thread; int (*callback)();
   int error;

   int image_irf;

   FLIMData* data;

   tthread::thread **thread_handle;

   double** local_irf;
   
   bool polarisation_resolved;
   int n_chan, n_meas, n_pol_group;
   int n_theta, n_theta_fix, n_theta_v, n_r, inc_rinf;
   double *theta_guess;
   double *theta, *theta_err, *r;
   double *chan_fact;

   double *exp_buf;
   double *tau_buf;
   double *beta_buf;
   double *theta_buf;
   double *fit_buf;
   float  *adjust_buf;
   double *count_buf;

   int *irf_max;
   double *resampled_irf;

   int max_dim, exp_dim;

   //integer static_store[1000];
   
   bool use_kappa;

   integer s; integer l; integer nl; integer n; integer nmax; integer ndim; 
   integer p; integer lnls1; integer n_v; integer csize;
   float *y; float *w; double *alf; double *lin_params; double *chi2;
   integer n_exp_phi, n_decay_group, exp_buf_size, tau_start;

   //double *a; double *b; double *c;

   double *ws;

   bool beta_global;
   int n_beta;

   int first_call;
   int runAsync;
   int init;
   bool has_fit;

   FitStatus *status;
   WorkerParams* params;

   int alf_t0_idx, alf_offset_idx, alf_scatter_idx, alf_E_idx, alf_beta_idx, alf_theta_idx, alf_tvb_idx, alf_ref_idx;
   double t_g;

   int *locked_param;
   double *locked_value;
   bool getting_fit;
   double* conf_lim;
   int calculate_errs;
   double* lin_params_err;
   double* alf_err;

   bool anscombe_tranform;

   conv_func Convolve;
   conv_deriv_func ConvolveDerivative;

   FLIMGlobalFitController(int global_algorithm, int image_irf,
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
                           int ierr[], int n_thread, int runAsync, int callback());


//   void SetData(double data[], int data_type);
//   int SetData(char* data_file, int data_type);

   void SetData(FLIMData* data);

   void SetPolarisationMode(int mode);

   int RunWorkers();

   void CleanupTempVars();

   ~FLIMGlobalFitController();

   void Init();

   int  GetNumGroups();
   int  GetNumThreads();
   int  GetErrorCode();
   void SetGlobalVariables();
   int  ProcessRegion(int g, int r, int thread);

   int GetFit(int im, int n_t, double t[], int n_fit, int fit_mask[], double fit[]);
   
   int GetImageResults(int idx, uint8_t mask[], float chi2[], float tau[], float I0[], float beta[], float E[], 
           float gamma[], float theta[], float r[], float t0[], float offset[], float scatter[], float tvb[], float ref_lifetime[]);

   double ErrMinFcn(double x, ErrMinParams& params);

   void calculate_exponentials(int thread, double tau[], double theta[]);
   int  check_alf_mod(int thread, const double* new_alf);

   void add_decay(int thread, int tau_idx, int theta_idx, int decay_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double a[]);
   void add_derivative(int thread, int tau_idx, int theta_idx, int decay_group_idx,  double tau[], double theta[], double fact, double ref_lifetime, double a[]);
   void add_irf(int thread, double a[],int pol_group, double* scale_fact = NULL);

   int flim_model(int thread, double tau[], double beta[], double theta[], double ref_lifetime, bool include_fixed, double a[]);
   int ref_lifetime_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int tau_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int beta_derivatives(int thread, double tau[], const double alf[], double theta[], double ref_lifetime, double b[]);
   int theta_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int E_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int FMM_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);

   void sample_irf(int thread, float a[], int pol_group = 0, double* scale_fact = 0);
   void sample_irf(int thread, double a[], int pol_group = 0, double* scale_fact = 0);


   int global_algorithm;

   tthread::recursive_mutex cleanup_mutex;
   tthread::recursive_mutex mutex;


   void SetupIncMatrix(int* inc);
   int ada(double *a, double *b, double *kap, const double *alf, int isel, int thread);



private:
   void CalculateIRFMax(int n_t, double t[]);
   void CalculateResampledIRF(int n_t, double t[]);
   void CleanupResults();
   
   double CalculateChi2(int s, int n_meas_res, float y[], double a[], double lin_params[], float adjust_buf[], double fit_buf[], double chi2[]);

   int ProcessNonLinearParams(int n, int n_px, int loc[], double alf[], float tau[], float beta[], float E[], float theta[], float offset[], float scatter[], float tvb[], float ref_lifetime[]);
   int ProcessLinearParams(int s, int n_px, int loc[], double lin_params[], double chi2_group[], float I0[], float beta[], float gamma[], float r[], float offset[], float scatter[], float tvb[], float chi2[]);


   double* GetDataPointer(int g, boost::interprocess::mapped_region& data_map_view);

   void SetupAdjust(int thread, float adjust[], float scatter_adj, float offset_adj, float tvb_adj);
   
   int GetPixelFit(double a[], double lin_params[], float adjust[], int n, double fit[]);



   int DetermineMAStartPosition(int p);
   double CalculateMeanArrivalTime(float decay[], int p);

  // int SetResultsMapping(int im);


   int ma_start;
   float* ma_decay;
   double g_factor;

   int lm_algorithm;

   boost::interprocess::file_mapping   result_map_file;
   boost::interprocess::mapped_region  result_map_view;
   boost::interprocess::mapped_region  alf_map_view;
   boost::interprocess::mapped_region  lin_map_view;
   boost::interprocess::mapped_region  chi2_map_view;

   char* result_map_filename;

   double* cur_alf;
   double* alf_local;
   double* lin_local;
   double* irf_buf;
   double* t_irf_buf;

   int memory_map_results;

   boost::ptr_vector<VariableProjector> projectors;
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

/*
// http://paulbourke.net/miscellaneous/interpolation/
double CubicInterpolate(
   double y0,double y1,
   double y2,double y3,
   double mu)
{
   // mu - distance between y1 and y2
   double a0,a1,a2,a3,mu2;

   mu2 = mu*mu;
   a0 = -0.5*y0 + 1.5*y1 - 1.5*y2 + 0.5*y3;
   a1 = y0 - 2.5*y1 + 2*y2 - 0.5*y3;
   a2 = -0.5*y0 + 0.5*y2;
   a3 = y1;

   return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}
*/


#endif