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
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <map>
#include "MexUtils.h"

using std::pair;
using std::map;
using std::unique_ptr;
using std::shared_ptr;

int next_id = 0;

struct ControllerGroup
{
   shared_ptr<AcquisitionParameters> acq;
   shared_ptr<FLIMData> data;
   shared_ptr<FLIMGlobalFitController> controller;
};

typedef map<int, ControllerGroup> ControllerMap;
typedef pair<int, ControllerGroup> ControllerEntry;
ControllerMap controller;


#ifdef _WINDOWS
#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif
#endif

#define AssertInputCondition(x) CheckInputCondition(#x, x);

void CheckInputCondition(char* text, bool condition)
{
   if (!condition)
      mexErrMsgIdAndTxt("FLIMfitMex:invalidInput", text);
}

int started = false;
void Startup()
{
#ifdef USE_CONCURRENCY_ANALYSIS
   if (!started)
   {
      writer = new marker_series("FLIMfit");
      started = true;
   }
#endif
}

void Cleanup()
{
   FLIMGlobalClearFit(-1);
#ifdef USE_CONCURRENCY_ANALYSIS
   delete writer;
#endif
}


void CheckInput(int nrhs, int needed);
void ErrorCheck(int nlhs, int nrhs, const mxArray *prhs[]);
void CheckSize(const mxArray* array, int needed);



void GetUniqueID(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   controller.insert(ControllerEntry(next_id, ControllerGroup()));
   plhs[0] = mxCreateDoubleScalar(next_id);
   next_id++;
}



int SetAcquisitionParameters(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 13);
   AssertInputCondition(mxIsInt32(prhs[9]));

   int data_type = mxGetScalar(prhs[2]);
   int polarisation_resolved = mxGetScalar(prhs[3]);

   int n_chan = mxGetScalar(prhs[4]);
   int n_t_full = mxGetScalar(prhs[5]);
   int n_t = mxGetScalar(prhs[6]);
   double* t = mxGetPr(prhs[7]);
   double* t_int = mxGetPr(prhs[8]);
   int* t_skip = reinterpret_cast<int*>(mxGetData(prhs[9]));
   double t_rep = mxGetScalar(prhs[10]);
   double counts_per_photon = mxGetScalar(prhs[11]);

   g.acq = std::make_shared<AcquisitionParameters>(data_type, polarisation_resolved, n_chan, n_t_full, n_t, t, t_int, t_skip, t_rep, counts_per_photon);
}

int SetIRF(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.acq != nullptr);
   AssertInputCondition(nrhs >= 10);

   int n_irf = mxGetN(prhs[2]);
   int n_chan = mxGetM(prhs[3]);
   double* data = mxGetPr(prhs[4]);

   double t0 = mxGetScalar(prhs[5]);
   double dt = mxGetScalar(prhs[6]);

   int ref_reconvolution = mxGetScalar(prhs[7]);
   double ref_lifetime_guess = mxGetScalar(prhs[8]);

   shared_ptr<InstrumentResponseFunction> irf(new InstrumentResponseFunction());
   irf->SetIRF(n_irf, n_chan, t0, dt, data);
   if (ref_reconvolution)
      irf->SetReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   g.acq->SetIRF(irf);
}

int SetDataParameters(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.acq != nullptr);
   AssertInputCondition(nrhs >= 13);
   AssertInputCondition(mxIsInt32(prhs[5]));
   AssertInputCondition(mxGetNumberOfElements(prhs[5]) == g.data->n_im);
   AssertInputCondition(mxIsUint8(prhs[6]));
   AssertInputCondition(mxGetNumberOfElements(prhs[6]) == g.data->n_im * g.data->n_x * g.data->n_y);

   int n_im = mxGetScalar(prhs[2]);
   int n_x = mxGetScalar(prhs[3]);
   int n_y = mxGetScalar(prhs[4]);
   int* use_im = reinterpret_cast<int32_t*>(mxGetData(prhs[5]));
   uint8_t* mask = reinterpret_cast<uint8_t*>(mxGetData(prhs[6]));
   int merge_regions = mxGetScalar(prhs[7]);
   int threshold = mxGetScalar(prhs[8]);
   int limit = mxGetScalar(prhs[9]);
   int global_mode = mxGetScalar(prhs[10]);
   int smoothing_factor = mxGetScalar(prhs[11]);

   g.data = std::make_shared<FLIMData>(g.acq, n_im, n_x, n_y, use_im, mask, merge_regions, threshold, limit, global_mode, smoothing_factor);
}

int SetData(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 3);

   const mxArray* data = prhs[2];

   if (mxIsSingle(data))
   {
      float* d = reinterpret_cast<float*>(mxGetData(data));
      g.data->SetData(d);
   }
   else if (mxIsUint16(data))
   {
      uint16_t* d = reinterpret_cast<uint16_t*>(mxGetData(data));
      g.data->SetData(d);
   }
   else
   {
      mexErrMsgIdAndTxt("FLIMfitMex:invalidInput", "FLIMData must be single precision floating point or uint16");
   }
}

int SetDataFromFile(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 5);
   AssertInputCondition(mxIsChar(prhs[2]));

   std::string data_file = GetStringFromMatlab(prhs[2]);
   int data_class = mxGetScalar(prhs[3]);
   int data_skip = mxGetScalar(prhs[4]);

   g.data->SetData(data_file.c_str(), data_class, data_skip);
}

int SetAcceptor(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsSingle(prhs[2]));

   float* acceptor = reinterpret_cast<float*>(mxGetData(prhs[2]));
   g.data->SetAcceptor(acceptor);
}

int SetBackgroundImage(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsSingle(prhs[2]));

   float* data = reinterpret_cast<float*>(mxGetData(prhs[2]));
   g.data->SetBackground(data);
}

int SetBackground(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 3);

   float data = mxGetScalar(prhs[2]);
   g.data->SetBackground(data);
}

int SetBackgroundTVImage(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 5);
   AssertInputCondition(mxIsSingle(prhs[2]));
   AssertInputCondition(mxIsSingle(prhs[3]));

   float* tvb_profile = reinterpret_cast<float*>(mxGetData(prhs[2]));
   float* tvb_I_map = reinterpret_cast<float*>(mxGetData(prhs[3]));
   float const_background = mxGetScalar(prhs[4]);

   g.data->SetTVBackground(tvb_profile, tvb_I_map, const_background);
}

int SetImageT0Shift(ControllerGroup& g, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(g.data != nullptr);
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsDouble(prhs[3]));

   double* data = mxGetPr(prhs[2]);
   g.data->SetImageT0Shift(data);
}






void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   mexAtExit(Cleanup);

   Startup();

   try
   {
      if (nrhs == 0 && nlhs > 0)
      {
         GetUniqueID(nlhs, plhs, nrhs, prhs);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsScalar(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      int c_idx = mxGetScalar(prhs[0]);

      // Get controller
      auto iter = controller.find(c_idx);
      if (iter == controller.end())
         mexErrMsgIdAndTxt("FLIMfitMex:invalidControllerIndex", "Controller index is not valid");
      ControllerGroup& g = iter->second;

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "Clear")
         controller.erase(c_idx);
      else if (command == "SetAcquisitionParameters")
         SetAcquisitionParameters(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetIRF")
         SetIRF(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetDataParameters")
         SetDataParameters(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetData")
         SetData(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetDataFromFile")
         SetDataFromFile(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetAcceptor")
         SetAcceptor(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetBackgroundImage")
         SetBackgroundImage(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetBackground")
         SetBackground(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetBackgroundTVImage")
         SetBackgroundTVImage(g, nlhs, plhs, nrhs, prhs);
      else if (command == "SetImageT0Shift")
         SetImageT0Shift(g, nlhs, plhs, nrhs, prhs);

   }
   catch (std::exception e)
   {
      mexErrMsgIdAndTxt("FLIMreaderMex:exceptionOccurred",
         e.what());
   }
}

/*
bool ClearController(int c_idx)
{
   ControllerMap::iterator iter = controller.find(c_idx);

   if ( iter != controller.end() )
   {
      if (iter->second->Busy())
         return false;
      else
      {
         controller.release(iter);
         return true;
      }
   }
   else
      return true;

}

FITDLL_API ModelParametersStruct GetDefaultModelParameters()
{
   ModelParameters params;
   return params.GetStruct();
}

FITDLL_API FitSettingsStruct GetDefaultFitSettings()
{
   FitSettings settings;
   return settings.GetStruct();
}


FITDLL_API int SetupFit(int c_idx, ModelParametersStruct params_, FitSettingsStruct settings_)
{

   if ( !ClearController(c_idx) )
      return ERR_FIT_IN_PROGRESS;

   ModelParameters params(params_);
   FitSettings     settings(settings_);
   
   controller.insert( c_idx,
      new FLIMGlobalFitController(params, settings)
   );
           
   return controller[c_idx].GetErrorCode();
   
}

FITDLL_API int SetIRF(int c_idx, int n_chan, int n_irf, int image_irf, double timebin_t0, double timebin_width, double irf[], int ref_reconvolution, double ref_lifetime_guess)
{
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return ERR_INVALID_IDX;

   shared_ptr<InstrumentResponseFunction> IRF( new InstrumentResponseFunction() );
   IRF->SetIRF(n_irf, n_chan, timebin_t0, timebin_width, irf);
   if (ref_reconvolution)
      IRF->SetReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   return SUCCESS;
}
*/

FITDLL_API int SetupFit(int c_idx, int global_algorithm, int algorithm,
   int weighting, int calculate_errors, double conf_interval,
   int n_thread, int runAsync, int use_callback, int(*callback)())
{
   FitSettings settings(algorithm, global_algorithm, weighting, n_thread, runAsync, callback);
   settings.CalculateErrors(calculate_errors, conf_interval);

   controller.insert(c_idx, new FLIMGlobalFitController(settings));
}


FITDLL_API int SetupGlobalFit(int c_idx, 
                              int n_exp, int n_fix, int n_decay_group, int decay_group[], double tau_min[], double tau_max[], 
                              int estimate_initial_tau, double tau_guess[],
                              int fit_beta, double fixed_beta[],
                              int fit_t0, double t0_guess, 
                              int fit_offset, double offset_guess, 
                              int fit_scatter, double scatter_guess,
                              int fit_tvb, double tvb_guess, double tvb_profile[],
                              int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                              int pulsetrain_correction
                              )
{
   INIT_CONCURRENCY;

   if ( !ClearController(c_idx) )
      return ERR_FIT_IN_PROGRESS;

   bool polarisation_resolved = false;
   int n_chan = 1;
   
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Setting up fit");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    if (!use_callback)
      callback = NULL;


   shared_ptr<DecayModel> model = std::make_shared<DecayModel>(acq);

   ModelParameters params;
   params.SetDecay(n_exp, n_fix, tau_min, tau_max, tau_guess, fit_beta, fixed_beta);
   params.SetPulseTrainCorrection(pulsetrain_correction);
   
   if (decay_group != NULL)
      params.SetDecayGroups(decay_group);
   
   params.SetStrayLight(fit_offset, offset_guess, fit_scatter, scatter_guess, fit_tvb, tvb_guess);
   params.SetFitT0(fit_t0, t0_guess);

   if (n_fret > 0)
      params.SetFRET(n_fret, n_fret_fix, inc_donor, E_guess);

   FitSettings settings(algorithm, global_algorithm, weighting, n_thread, runAsync, callback);
   settings.CalculateErrors(calculate_errors, conf_interval);

   controller.insert( c_idx,
      new FLIMGlobalFitController(params, settings, polarisation_resolved, t_rep)
   );
           
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return controller[c_idx].GetErrorCode();
   
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

   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return ERR_INVALID_IDX;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Setting up fit");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//   int error;

   if (!use_callback)
      callback = NULL;

   bool polarisation_resolved = true;
   int n_chan = 2; 

   shared_ptr<InstrumentResponseFunction> IRF( new InstrumentResponseFunction() );
   IRF->SetIRF(n_irf, n_chan, t_irf[0], t_irf[1]-t_irf[0], irf);
   if (ref_reconvolution)
      IRF->SetReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   ModelParameters params;
   params.SetDecay(n_exp, n_fix, tau_min, tau_max, tau_guess, fit_beta, fixed_beta);
   params.SetPulseTrainCorrection(pulsetrain_correction);
   params.SetStrayLight(fit_offset, offset_guess, fit_scatter, scatter_guess, fit_tvb, tvb_guess);
   
   params.SetAnisotropy(n_theta, n_theta_fix, inc_rinf, theta_guess);

   FitSettings settings(algorithm, global_algorithm, weighting, n_thread, runAsync, callback);
   settings.CalculateErrors(calculate_errors, conf_interval);

   controller.insert( c_idx,
      new FLIMGlobalFitController(params, settings, polarisation_resolved, t_rep)
   );
   
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return c->GetErrorCode();

}


FITDLL_API int StartFit(int c_idx)
{
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 
   
   c->Init();
   return c->RunWorkers();
}


FITDLL_API const char** GetOutputParamNames(int c_idx, int* n_output_params)
{
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 

   const char** names; 
   c->results->GetCParamNames(*n_output_params, names);

   return names;
}

FITDLL_API int GetTotalNumOutputRegions(int c_idx)
{
  FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 

   return c->data->n_output_regions_total;
}

FITDLL_API int GetImageStats(int c_idx, int* n_regions, int* image, int* regions, int* region_size, float* success, int* iterations, float* stats)
{
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 

   int error = c->results->GetImageStats(*n_regions, image, regions, region_size, success, iterations, stats, 0.05, 1); // TODO: conf_factor, n_thread

   return error;

}


FITDLL_API int GetParameterImage(int c_idx, int im, int param, uint8_t ret_mask[], float image_data[])
{
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 

   int error = c->results->GetParameterImage(im, param, ret_mask, image_data);

   return error;

}

FITDLL_API int FLIMGlobalGetFit(int c_idx, int im, int n_t, double t[], int n_fit, int fit_mask[], double fit[], int* n_valid)
{
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 
 
   int error = c->GetFit(im, n_fit, fit_mask, fit, *n_valid);

   return error;

}

FITDLL_API int FLIMGlobalClearFit(int c_idx)
{
   if (c_idx == -1)
   {
      controller.erase(controller.begin(), controller.end());
   }
   else
   {
      ClearController(c_idx);
   }
   return SUCCESS;
}


FITDLL_API int FLIMGetFitStatus(int c_idx, int *group, int *n_completed, int *iter, double *chi2, double *progress)
{  

   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
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
   FLIMGlobalFitController *c = GetController(c_idx);
   if ( c == NULL )
      return NULL; 

   c->status->Terminate();
   return SUCCESS;
}

