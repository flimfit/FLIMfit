//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

#ifndef _FLIMGLOBALFITCONTROLLER_H
#define _FLIMGLOBALFITCONTROLLER_H

#ifdef _MSC_VER
#  pragma warning(disable: 4512) // assignment operator could not be generated.
#  pragma warning(disable: 4510) // default constructor could not be generated.
#  pragma warning(disable: 4610) // can never be instantiated - user defined constructor required.
#endif

#define NOMINMAX
#include <boost/interprocess/file_mapping.hpp>

#include "FitStatus.h"
#include "ModelADA.h"
#include "FLIMData.h"
#include "FLIMGlobalAnalysis.h"
#include "tinythread.h"

#include <boost/ptr_container/ptr_vector.hpp>
#include <boost/interprocess/mapped_region.hpp>

#include "AbstractFitter.h"
#include "ImageStats.h"

#include "FlagDefinitions.h"
#include <cmath>

#include "ConcurrencyAnalysis.h"

typedef double* DoublePtr;  

#define USE_GLOBAL_BINNING_AS_ESTIMATE    false
#define _CRTDBG_MAPALLOC




class ErrMinParams;
class FLIMGlobalFitController;

class WorkerParams 
{
public:
   WorkerParams(FLIMGlobalFitController* controller, int thread) : 
   controller(controller), thread(thread) 
   {};
   
   WorkerParams() 
   { 
      controller = NULL;
      thread = 0;
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

typedef void (* conv_func)(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, int bin_shift, double& c);
typedef void (* conv_deriv_func)(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);


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
   int *ierr; float *success; int algorithm;
   int n_thread; int (*callback)();
   int error;

   int n_fitters;
   int n_omp_thread;

   int image_irf;
   double* t0_image;

   FLIMData* data;

   tthread::thread **thread_handle;

   int* irf_idx;
   
   bool polarisation_resolved;
   int n_chan, n_meas, n_pol_group;
   int y_dim;
   int n_theta, n_theta_fix, n_theta_v, n_r, inc_rinf;
   double *theta_guess;
   double *theta, *theta_err, *r;
   double *chan_fact;

   double *exp_buf;
   double *tau_buf;
   double *beta_buf;
   double *theta_buf;
   float  *adjust_buf;

   int *irf_max;

   int max_dim, exp_dim;

   bool use_kappa;

   int s; int l; int nl; int n; int nmax; int ndim; 
   int lmax; int p; int n_v;
   float *y; float *w; float *alf; float *lin_params; float *chi2; float *I; float *r_ss; float *acceptor;
   float *w_mean_tau, *mean_tau;
   int n_exp_phi, n_fret_group, exp_buf_size, tau_start;

   bool beta_global;
   int n_beta;

   int runAsync;
   int init;
   bool has_fit;

   FitStatus *status;
   WorkerParams* params;

   int alf_t0_idx, alf_offset_idx, alf_scatter_idx, alf_E_idx, alf_beta_idx, alf_theta_idx, alf_tvb_idx, alf_ref_idx;
   double t_g;

   bool getting_fit;
   int calculate_errors;
   double conf_interval;
   double conf_factor;

   float* lin_params_err;
   float* alf_err_lower;
   float* alf_err_upper;

   int eq_spaced_data;

   FLIMGlobalFitController(int global_algorithm, int image_irf,
                           int n_irf, double t_irf[], double irf[], double pulse_pileup, double t0_image[],
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
                           int weighting, int calculate_errors, double conf_interval,
                           int n_thread, int runAsync, int callback());

   ~FLIMGlobalFitController();


   void SetData(FLIMData* data);
   void SetPolarisationMode(int mode);

   void Init();
   int RunWorkers();
   int  GetErrorCode();

   int GetFit(int im, int n_t, double t[], int n_fit, int fit_mask[], double fit[], int& n_valid);
   int GetImageStats(int& n_regions, int image[], int regions[], int region_size[], float success[], int iterations[], float params[]);   

   int GetParameterImage(int im, int param, mask_type ret_mask[], float image_data[]);

   double CalculateGFactor();

   void SetupIncMatrix(int* inc);
   int CalculateModel(double *a, double *b, double *kap, const double *alf, int irf_idx, int isel, int thread);
   void GetWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread);
   float* GetConstantAdjustment();


   int n_output_params;
   int n_nl_output_params;
   const char** param_names_ptr;

private:

   void SetOutputParamNames();
   void CalculateIRFMax(int n_t, double t[]);
   void CleanupResults();
   
   void WorkerThread(int thread);
   
   void CleanupTempVars();


   int ProcessLinearParams(float lin_params[], float lin_params_std[], float output_params[], float output_params_std[]);  
   void NormaliseLinearParams(int s, float volatile lin_params[], float volatile norm_params[]);
   void DenormaliseLinearParams(int s, float volatile norm_params[], float volatile lin_params[]);

   int ProcessNonLinearParams(float alf[], float alf_err_lower[], float alf_err_upper[], float param[], float err_lower[], float err_upper[]);
   float GetNonLinearParam(int param, float alf[]);
   
   void CalculateMeanLifetime(int s, float lin_params[], float alf[], float mean_tau[], float w_mean_tau[]);

   double* GetDataPointer(int g, boost::interprocess::mapped_region& data_map_view);

   void SetupAdjust(int thread, float adjust[], float scatter_adj, float offset_adj, float tvb_adj);
   

   int flim_model(int thread, int irf_idx, double tau[], double beta[], double theta[], double ref_lifetime, double t0_shift, bool include_fixed, int bin_shift, double a[], int adim);
   int ref_lifetime_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int tau_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int beta_derivatives(int thread, double tau[], const double alf[], double theta[], double ref_lifetime, double b[]);
   int theta_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int E_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int FMM_derivatives(int thread, double tau[], double beta[], double theta[], double ref_lifetime, double b[]);
   int t0_derivatives(int thread, int irf_idx, double tau[], double beta[], double theta[], double ref_lifetime, double t0_shift, double b[]);

   int ProcessRegion(int g, int r, int px, int thread);

   void calculate_exponentials(int thread, int irf_idx, double tau[], double theta[], double t0_shift);
   int check_alf_mod(int thread, const double* new_alf, int irf_idx);

   void add_decay(int thread, int tau_idx, int theta_idx, int fret_group_idx, double tau[], double theta[], double fact, double ref_lifetime, double a[], int bin_shift = 0);
   void add_derivative(int thread, int tau_idx, int theta_idx, int fret_group_idx,  double tau[], double theta[], double fact, double ref_lifetime, double a[]);
   
   template <typename T>
   void add_irf(int thread, int irf_idx, double t0_shift, T a[],int pol_group, double* scale_fact = NULL);


   conv_func Convolve;
   conv_deriv_func ConvolveDerivative;


   int global_algorithm;
   int weighting;

   tthread::recursive_mutex cleanup_mutex;
   tthread::recursive_mutex mutex;



   int DetermineMAStartPosition(int p);
   double EstimateAverageLifetime(float decay[], int p);

   void ShiftIRF(double shift, double s_irf[]);

   int ma_start;
   float* local_decay;
   float* binned_decay;
   double g_factor;

   double photons_per_count;

   int lm_algorithm;
   
   char* result_map_filename;

   double* cur_alf;
   int*    cur_irf_idx;
   double* alf_local;
   float* lin_local;
   double* irf_buf;
   double* t_irf_buf;

   int n_decay_group;
   int* decay_group;
   int* decay_group_buf;

   int calculate_mean_lifetimes;


   std::vector<std::string> param_names;

   boost::ptr_vector<AbstractFitter> projectors;

   int cur_region;
   int next_pixel;
   int next_region;
   int threads_active;
   int threads_started;
   int* cur_im;

   tthread::mutex region_mutex;
   tthread::mutex pixel_mutex;
   tthread::mutex data_mutex;
   tthread::condition_variable active_lock;
   tthread::condition_variable data_lock;

   friend void StartWorkerThread(void* wparams);
};




template <typename T>
void FLIMGlobalFitController::add_irf(int thread, int irf_idx, double t0_shift, T a[], int pol_group, double* scale_fact)
{
   int* resample_idx = data->GetResampleIdx(thread);

   double* lirf = this->irf_buf;

   int irf_px = irf_idx % data->n_px;
   int irf_im = irf_idx / data->n_px;

   if (data->image_t0_shift)
      t0_shift += data->image_t0_shift[irf_im];

   if (image_irf)
      lirf += irf_px * n_irf * n_chan;
   else if (t0_image)
      t0_shift += t0_image[irf_px];

   if (t0_shift != 0)
   {
      lirf = irf_buf + (thread + 1) * n_irf * n_chan;
      ShiftIRF(t0_shift, lirf);
   }

   int idx = 0;
   int ii;
   for(int k=0; k<n_chan; k++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[k];
      for(int i=0; i<n_t; i++)
      {
         ii = (int) floor((t[i]-t_irf[0])/t_g);

         if (ii>=0 && ii<n_irf)
            a[idx] += (T) (lirf[k*n_irf+ii] * chan_fact[pol_group*n_chan+k] * scale);
         idx += resample_idx[i];
      }
      idx++;
   }
}


void StartWorkerThread(void* wparams);


#endif