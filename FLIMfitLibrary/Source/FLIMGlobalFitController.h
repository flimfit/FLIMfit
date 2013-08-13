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

#include <boost/interprocess/file_mapping.hpp>

#include "FitStatus.h"
#include "DecayModel.h"
#include "ModelADA.h"
#include "FLIMData.h"
#include "RegionData.h"
#include "FitResults.h"
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


class FLIMGlobalFitController
{
public:

   int algorithm;
   int n_thread; 
   int (*callback)();
   int error;

   int n_fitters;
   int n_omp_thread;

   DecayModel* model;
   FLIMData* data;
   FitResults* results;
   
   int y_dim;
   
   int runAsync;
   int init;
   bool has_fit;

   FitStatus *status;
   WorkerParams* params;

   
   bool getting_fit;
   int calculate_errors;
   double conf_interval;
   double conf_factor;


   FLIMGlobalFitController(int global_algorithm, DecayModel* params, int algorithm,
                           int weighting, int calculate_errors, double conf_interval,
                           int n_thread, int runAsync, int (*callback)());
  

   ~FLIMGlobalFitController();


   void SetData(FLIMData* data);
   
   void Init();
   int RunWorkers();
   int  GetErrorCode();

   int GetFit(int im, int n_t, double t[], int n_fit, int fit_mask[], double fit[], int& n_valid);
   
   void GetWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread);


private:

   void SetOutputParamNames();
   void CalculateIRFMax(int n_t, double t[]);
   void CleanupResults();
   
   void WorkerThread(int thread);
   
   void CleanupTempVars();


   
   void CalculateMeanLifetime(int s, float lin_params[], float alf[], float mean_tau[], float w_mean_tau[]);

   double* GetDataPointer(int g, boost::interprocess::mapped_region& data_map_view);

//   void SetupAdjust(int thread, float adjust[], float scatter_adj, float offset_adj, float tvb_adj);
   
   int ProcessRegion(int g, int r, int px, int thread);
   

   int global_algorithm;
   int weighting;

   tthread::recursive_mutex cleanup_mutex;
   tthread::recursive_mutex mutex;

   int DetermineMAStartPosition(int p);
   double EstimateAverageLifetime(float decay[], int p);


   int ma_start;
   double g_factor;

   double photons_per_count;
   

   int calculate_mean_lifetimes;



   ptr_vector<AbstractFitter> projectors;
   ptr_vector<RegionData> region_data;

   ptr_vector<tthread::thread> thread_handle;

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





void StartWorkerThread(void* wparams);


#endif