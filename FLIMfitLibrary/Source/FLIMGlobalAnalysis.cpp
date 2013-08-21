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
#include "InstrumentResponseFunction.h"
#include "ModelADA.h" 
#include "FLIMGlobalAnalysis.h"
#include "FLIMGlobalFitController.h"
#include "FLIMData.h"

#include <assert.h>
#include <map>
#include <utility>

using std::map;
using std::pair;

int next_id = 0;
typedef map<int, FLIMGlobalFitController> ControllerMap;

ControllerMap controller;


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
      #ifdef USE_CONCURRENCY_ANALYSIS
      writer = new marker_series("FLIMfit");
      #endif
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
      #ifdef USE_CONCURRENCY_ANALYSIS
      delete writer;
      #endif
      break;
   }
    return TRUE;
}

#else

void __attribute__ ((constructor)) myinit() 
{
}

void __attribute__ ((destructor)) myfini()
{
   FLIMGlobalClearFit(-1);
}

#endif

FITDLL_API int FLIMGlobalGetUniqueID()
{
   controller.insert( pair<int,FLIMGlobalFitController>(next_id,FLIMGlobalFitController()) );
   return next_id++;
}

FITDLL_API void FLIMGlobalRelinquishID(int id)
{
   controller.erase(id);
}


int ValidControllerIdx(int c_idx)
{
   return (controller.find(c_idx) != controller.end() );
}

FLIMGlobalFitController* GetController(int c_idx)
{
   ControllerMap::iterator iter = controller.find(c_idx);

   if ( iter != controller.end() )
      return &(iter->second);
   else
      return NULL;

}

int InitControllerIdx(int c_idx)
{
   FLIMGlobalFitController *c;
   if ( c = GetController(c_idx) )
      return c->init;
   else
      return false;

   
}

int CheckControllerIdx(int c_idx)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_COULD_NOT_START_FIT;

   if (c->status->IsRunning())
      return ERR_FIT_IN_PROGRESS;

   return SUCCESS;
}

/*
FITDLL_API int SetIRF(int c_idx, int image_irf, int n_irf, double t_irf[], double irf[], double t0_image[])
{

}

FITDLL_API int SetFitParameters(int c_idx, ModelParamsStruct* params)
{

}
*/

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
                              int weighting, int calculate_errors, double conf_interval,
                              int n_thread, int runAsync, int use_callback, int (*callback)())
{
   INIT_CONCURRENCY;

   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;

   int error;

   int n_chan = 1;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Setting up fit");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   if ( c->status->IsRunning() )
      return ERR_FIT_IN_PROGRESS;

   if (!use_callback)
      callback = NULL;

   InstrumentResponseFunction IRF;
   IRF.SetIRF(n_irf, n_chan, t_irf, irf);
   if (ref_reconvolution)
      IRF.SetReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   ModelParameters params;
   params.SetDecay(n_exp, n_fix, n_decay_group, decay_group, tau_min, tau_max, tau_guess, fit_beta, fixed_beta);
   params.SetStrayLight(fit_offset, offset_guess, fit_scatter, scatter_guess, fit_tvb, tvb_guess);
   
   if (n_fret > 0)
      params.SetFRET(n_fret, n_fret_fix, inc_donor, E_guess);

              
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return c->GetErrorCode();
   
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
                             int weighting, int calculate_errors, double conf_interval,
                             int n_thread, int runAsync, int use_callback, int (*callback)())
{
   INIT_CONCURRENCY;

   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Setting up fit");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   int error;

   if (!use_callback)
      callback = NULL;


   InstrumentResponseFunction IRF;
   IRF.SetIRF(n_irf, n_chan, t_irf, irf);
   if (ref_reconvolution)
      IRF.SetReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   ModelParameters params;
   params.SetDecay(n_exp, n_fix, tau_min, tau_max, tau_guess, fit_beta, fixed_beta);
   params.SetStrayLight(fit_offset, offset_guess, fit_scatter, scatter_guess, fit_tvb, tvb_guess);
   
   if (n_fret > 0)
      params.SetAnisotropy(n_theta, n_theta_fix, inf_rinf, theta_guess);

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return c->GetErrorCode();

}


FITDLL_API int SetDataFloat(int c_idx, float* data)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;

   int e = c->data->SetData(data);   
   return e;
}

FITDLL_API int SetDataUInt16(int c_idx, uint16_t* data)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;

   int e = c->data->SetData(data);   
   return e;
}

FITDLL_API int SetDataFile(int c_idx, char* data_file, int data_class, int data_skip)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;

   return c->data->SetData(data_file, data_class, data_skip);
}

FITDLL_API int SetAcceptor(int c_idx, float* acceptor)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;

   c->data->SetAcceptor(acceptor);
   return SUCCESS;
}



FITDLL_API int SetDataParams(int c_idx, int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], double t_int[], int t_skip[], int n_t, int data_type,
                             int use_im[], uint8_t mask[], int threshold, int limit, double counts_per_photon, int global_mode, int smoothing_factor, int use_autosampling)
{
   INIT_CONCURRENCY;

   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;


   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Setting up data object");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   int        n_thread              = c->n_thread;
   int        polarisation_resolved = n_chan == 2; // TODO
   FitStatus* status =              c->status;

   FLIMData* d = new FLIMData(polarisation_resolved, n_im, n_x, n_y, n_chan, n_t_full, t, t_int, t_skip, n_t, data_type, use_im,  
                              mask, threshold, limit, counts_per_photon, global_mode, smoothing_factor, use_autosampling, c->n_thread, c->status);
   
   c->SetData(d);

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return SUCCESS;

}


FITDLL_API int SetBackgroundImage(int c_idx, float* background_image)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;
   c->data->SetBackground(background_image);
   return 0;
}


FITDLL_API int SetBackgroundValue(int c_idx, float background_value)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;
   c->data->SetBackground(background_value);
   return 0;
}

FITDLL_API int SetBackgroundTVImage(int c_idx, float* tvb_profile, float* tvb_I_map, float const_background)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return ERR_INVALID_IDX;
   c->data->SetTVBackground(tvb_profile, tvb_I_map, const_background);
   return 0;
}


FITDLL_API int StartFit(int c_idx)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 
   
   c->Init();
   return c->RunWorkers();
}


FITDLL_API const char** GetOutputParamNames(int c_idx, int* n_output_params)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 

   const char** names; 
   c->results->GetCParamNames(*n_output_params, names);

   return names;
}

FITDLL_API int GetTotalNumOutputRegions(int c_idx)
{
  FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 

   return c->data->n_output_regions_total;
}

FITDLL_API int GetImageStats(int c_idx, int* n_regions, int* image, int* regions, int* region_size, float* success, int* iterations, float* stats)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 

   int error = c->results->GetImageStats(*n_regions, image, regions, region_size, success, iterations, stats, 0.05, 1); // TODO: conf_factor, n_thread

   return error;

}


FITDLL_API int GetParameterImage(int c_idx, int im, int param, uint8_t ret_mask[], float image_data[])
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 

   int error = c->results->GetParameterImage(im, param, ret_mask, image_data);

   return error;

}

FITDLL_API int FLIMGlobalGetFit(int c_idx, int im, int n_t, double t[], int n_fit, int fit_mask[], double fit[], int* n_valid)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 
 
   int error = c->GetFit(im, n_fit, fit_mask, fit, *n_valid);

   return error;

}

FITDLL_API int FLIMGlobalClearFit(int c_idx)
{
   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 
   
   c->CleanupResults();

   return SUCCESS;
}


FITDLL_API int FLIMGetFitStatus(int c_idx, int *group, int *n_completed, int *iter, double *chi2, double *progress)
{  

   FLIMGlobalFitController *c;
   if ( c != GetController(c_idx) )
      return NULL; 

   
   c->status->CalculateProgress();

   for(int i=0; i<c->status->n_thread; i++)
   {
      group[i]       = c->status->group[i]; 
      n_completed[i] = c->status->n_completed[i];
      iter[i]        = c->status->iter[i];
      chi2[i]        = c->status->chi2[i];
   }
   *progress = c->status->progress;

   return c->status->Finished();
   
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

