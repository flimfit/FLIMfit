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

#include "FitStatus.h"
#include "ModelADA.h" 
#include "FLIMGlobalAnalysis.h"
#include "FLIMGlobalFitController.h"
#include "FLIMData.h"

#include <assert.h>

FLIMGlobalFitController* controller[MAX_CONTROLLER_IDX];
int id_registered[MAX_CONTROLLER_IDX];

#ifdef _WINDOWS

#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
                )
{
   switch (ul_reason_for_call)
   {
   case DLL_PROCESS_ATTACH:
      for(int i=0; i<MAX_CONTROLLER_IDX; i++)
      {
         controller[i] = NULL;
         id_registered[i] = 0;
      }
      //VLDDisable();
      break;
      
   case DLL_THREAD_ATTACH:
      //VLDEnable();
      break;
 
   case DLL_THREAD_DETACH:
      //VLDDisable();
      break;

   case DLL_PROCESS_DETACH:
      FLIMGlobalClearFit(-1);
      break;
   }
    return TRUE;
}

#else

void __attribute__ ((constructor)) myinit() 
{
      for(int i=0; i<MAX_CONTROLLER_IDX; i++)
      {
         controller[i] = NULL;
         id_registered[i] = 0;
      }
}

void __attribute__ ((destructor)) myfini()
{
   FLIMGlobalClearFit(-1);
}

#endif

FITDLL_API int FLIMGlobalGetUniqueID()
{
   for(int i=0; i<MAX_CONTROLLER_IDX; i++)
   {
      if (id_registered[i] == 0)
      {
         id_registered[i] = 1;
         return i;
      }
   }

   return -1;
}

FITDLL_API void FLIMGlobalRelinquishID(int id)
{
   id_registered[id] = 0;
}


int ValidControllerIdx(int c_idx)
{
   if (c_idx >= MAX_CONTROLLER_IDX)
      return false;

   if (controller[c_idx] == NULL)
      return false;

   return true;
}

int InitControllerIdx(int c_idx)
{
   int valid = ValidControllerIdx(c_idx);

   if (valid)
      return (controller[c_idx]->init);
   else
      return valid;
}

int CheckControllerIdx(int c_idx)
{
   if (c_idx >= MAX_CONTROLLER_IDX)
      return ERR_COULD_NOT_START_FIT;

   if (controller[c_idx] != NULL)
   {
      if (controller[c_idx]->status->IsRunning())
      {
         return ERR_FIT_IN_PROGRESS;
      }
      else
      {
         delete controller[c_idx];
         controller[c_idx] = NULL;
      }
   }

   return SUCCESS;
}





FITDLL_API int SetupGlobalFit(int c_idx, int global_algorithm, int image_irf,
                              int n_irf, double t_irf[], double irf[], double pulse_pileup, double t0_image[],
                              int n_exp, int n_fix, int n_decay_group, int decay_group[], double tau_min[], double tau_max[], 
                              int estimate_initial_tau, double tau_guess[],
                              int fit_beta, double fixed_beta[],
                              int fit_t0, double t0_guess, 
                              int fit_offset, double offset_guess, 
                              int fit_scatter, double scatter_guess,
                              int fit_tvb, double tvb_guess, double tvb_profile[],
                              int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                              int pulsetrain_correction, double t_rep,
                              int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                              int weighting, int n_thread, int runAsync, int use_callback, int (*callback)())
{
   int error;

   error = CheckControllerIdx(c_idx);
   if (error)
      return error;

   if (!use_callback)
      callback = NULL;

   for(int i=0; i<n_irf; i++)
      t_irf[i] = t_irf[i]/T_FACTOR;

   int     n_theta         = 0;
   int     n_theta_fix     = 0;
   int     inc_rinf        = 0;
   double* theta_guess     = NULL;

   controller[c_idx] = 
         new FLIMGlobalFitController( global_algorithm, image_irf, n_irf, t_irf, irf, pulse_pileup, t0_image,
                                      n_exp, n_fix, n_decay_group, decay_group, tau_min, tau_max, 
                                      estimate_initial_tau, tau_guess,
                                      fit_beta, fixed_beta,
                                      n_theta, n_theta_fix, inc_rinf, theta_guess,
                                      fit_t0, t0_guess, 
                                      fit_offset, offset_guess, 
                                      fit_scatter, scatter_guess,
                                      fit_tvb, tvb_guess, tvb_profile,
                                      n_fret, n_fret_fix, inc_donor, E_guess, 
                                      pulsetrain_correction, t_rep,
                                      ref_reconvolution, ref_lifetime_guess, algorithm,
                                      weighting, n_thread, runAsync, callback );
                                      
   return controller[c_idx]->GetErrorCode();
   
}


FITDLL_API int SetupGlobalPolarisationFit(int c_idx, int global_algorithm, int image_irf,
                             int n_irf, double t_irf[], double irf[], double pulse_pileup, double t0_image[],
                             int n_exp, int n_fix, 
                             double tau_min[], double tau_max[], 
                             int estimate_initial_tau, double tau_guess[],
                             int fit_beta, double fixed_beta[],
                             int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                             int fit_t0, double t0_guess,
                             int fit_offset, double offset_guess, 
                             int fit_scatter, double scatter_guess,
                             int fit_tvb, double tvb_guess, double tvb_profile[],
                             int pulsetrain_correction, double t_rep,
                             int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                             int weighting, int n_thread, int runAsync, int use_callback, int (*callback)())
{

   int error = CheckControllerIdx(c_idx);
   if (error)
      return error;

   if (!use_callback)
      callback = NULL;

   int n_fret = 0;
   int n_fret_fix = 0;
   int inc_donor = 0;
   double* E_guess = NULL;

  for(int i=0; i<n_irf; i++)
      t_irf[i] = t_irf[i]/T_FACTOR;   


   int n_decay_group = 1;
   int* decay_group = NULL;

   controller[c_idx] = 
         new FLIMGlobalFitController( global_algorithm, image_irf, n_irf, t_irf, irf, pulse_pileup, t0_image,
                                      n_exp, n_fix, n_decay_group, decay_group, tau_min, tau_max, 
                                      estimate_initial_tau, tau_guess,
                                      fit_beta, fixed_beta,
                                      n_theta, n_theta_fix, inc_rinf, theta_guess,
                                      fit_t0, t0_guess, 
                                      fit_offset, offset_guess, 
                                      fit_scatter, scatter_guess,
                                      fit_tvb, tvb_guess, tvb_profile,
                                      n_fret, n_fret_fix, inc_donor, E_guess, 
                                      pulsetrain_correction, t_rep,
                                      ref_reconvolution, ref_lifetime_guess, algorithm,
                                      weighting, n_thread, runAsync, callback );
   controller[c_idx]->SetPolarisationMode(MODE_POLARISATION);

   return controller[c_idx]->GetErrorCode();

}


FITDLL_API int SetDataFloat(int c_idx, float* data)
{
   int e = controller[c_idx]->data->SetData(data);   
   return e;
}

FITDLL_API int SetDataUInt16(int c_idx, uint16_t* data)
{
   int e = controller[c_idx]->data->SetData(data);   
   return e;
}

FITDLL_API int SetDataFile(int c_idx, char* data_file, int data_class, int data_skip)
{
   return controller[c_idx]->data->SetData(data_file, data_class, data_skip);
}

FITDLL_API int SetAcceptor(int c_idx, float* acceptor)
{
   controller[c_idx]->data->SetAcceptor(acceptor);
   return SUCCESS;
}



FITDLL_API int SetDataParams(int c_idx, int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], double t_int[], int t_skip[], int n_t, int data_type,
                             int use_im[], uint8_t mask[], int threshold, int limit, double counts_per_photon, int global_mode, int smoothing_factor, int use_autosampling)
{

//   int valid = ValidControllerIdx(c_idx);
//   if (!valid)
//      return -1;

   for(int i=0; i<n_t_full; i++)
      t[i] = t[i]/T_FACTOR;

   int    n_thread              = controller[c_idx]->n_thread;
   int    polarisation_resolved = controller[c_idx]->polarisation_resolved;
   double g_factor              = controller[c_idx]->CalculateGFactor();

   FLIMData* d = new FLIMData(polarisation_resolved, g_factor, n_im, n_x, n_y, n_chan, n_t_full, t, t_int, t_skip, n_t, data_type, use_im,  
                              mask, threshold, limit, counts_per_photon, global_mode, smoothing_factor, use_autosampling, n_thread);
   
   controller[c_idx]->SetData(d);

   return SUCCESS;

}


FITDLL_API int SetBackgroundImage(int c_idx, float* background_image)
{
   controller[c_idx]->data->SetBackground(background_image);
   return 0;
}


FITDLL_API int SetBackgroundValue(int c_idx, float background_value)
{
   controller[c_idx]->data->SetBackground(background_value);
   return 0;
}

FITDLL_API int SetBackgroundTVImage(int c_idx, float* tvb_profile, float* tvb_I_map, float const_background)
{
   controller[c_idx]->data->SetTVBackground(tvb_profile, tvb_I_map, const_background);
   return 0;
}


FITDLL_API int StartFit(int c_idx)
{

   controller[c_idx]->Init();
   if (!controller[c_idx]->init)
      return controller[c_idx]->error;

   return controller[c_idx]->RunWorkers();
}


FITDLL_API const char** GetOutputParamNames(int c_idx, int* n_output_params)
{
   int valid = InitControllerIdx(c_idx);
   if (!valid) return NULL;

   *n_output_params = controller[c_idx]->n_output_params;
   return controller[c_idx]->param_names_ptr;
}



FITDLL_API int GetImageStats(int c_idx, int im, uint8_t* ret_mask, int* n_regions, int* regions, int* region_size, float* success, int* iterations, 
                             float* params_mean, float* params_std, float* params_median, float* params_q1, float* params_q2, float* params_01, float* params_99, float* params_w_mean, float* params_w_std)
{
   int valid = InitControllerIdx(c_idx);
   if (!valid) return ERR_NO_FIT;

   ImageStats<float> stats(params_mean, params_std, params_median, params_q1, params_q2, params_01, params_99, params_w_mean, params_w_std);

   int error = controller[c_idx]->GetImageStats(im, ret_mask, *n_regions, regions, region_size, success, iterations, stats);

   return error;

}


FITDLL_API int GetParameterImage(int c_idx, int im, int param, uint8_t ret_mask[], float image_data[])
{
   int valid = InitControllerIdx(c_idx);
   if (!valid) return ERR_NO_FIT;

   int error = controller[c_idx]->GetParameterImage(im, param, ret_mask, image_data);

   return error;

}

FITDLL_API int FLIMGlobalGetFit(int c_idx, int im, int n_t, double t[], int n_fit, int fit_mask[], double fit[], int* n_valid)
{

   int valid = InitControllerIdx(c_idx);
   if (!valid) return ERR_NO_FIT;

   for(int i=0; i<n_t; i++)
      t[i] = t[i]/T_FACTOR;

   int error = controller[c_idx]->GetFit(im, n_t, t, n_fit, fit_mask, fit, *n_valid);

   return error;

}

FITDLL_API int FLIMGlobalClearFit(int c_idx)
{

   if (c_idx >= 0)
   {
      int valid = ValidControllerIdx(c_idx);
      if (valid)
      {
         delete controller[c_idx];
         controller[c_idx] = NULL;
      }
   }
   else
   {
      for(int i=0; i<MAX_CONTROLLER_IDX; i++)
      {
         if (controller[i] != NULL)
         {
            delete controller[i];
            controller[i] = NULL;
         }
      }
   }

   return SUCCESS;
}


FITDLL_API int FLIMGetFitStatus(int c_idx, int *group, int *n_completed, int *iter, double *chi2, double *progress)
{  

   int valid = InitControllerIdx(c_idx);
   if (!valid)
      return ERR_NOT_INIT;

   
   controller[c_idx]->status->CalculateProgress();

   for(int i=0; i<controller[c_idx]->status->n_thread; i++)
   {
      group[i]       = controller[c_idx]->status->group[i]; 
      n_completed[i] = controller[c_idx]->status->n_completed[i];
      iter[i]        = controller[c_idx]->status->iter[i];
      chi2[i]        = controller[c_idx]->status->chi2[i];
   }
   *progress = controller[c_idx]->status->progress;

   return controller[c_idx]->status->Finished();
   
   return 0;
}


FITDLL_API int FLIMGlobalTerminateFit(int c_idx)
{
   int valid = ValidControllerIdx(c_idx);
   if (!valid)
      return ERR_NOT_INIT;

   controller[c_idx]->status->Terminate();
   return SUCCESS;
}
