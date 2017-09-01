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

#pragma once

#ifdef _MSC_VER
#  pragma warning(disable: 4512) // assignment operator could not be generated.
#  pragma warning(disable: 4510) // default constructor could not be generated.
#  pragma warning(disable: 4610) // can never be instantiated - user defined constructor required.
#endif

#include "FLIMData.h"
#include "FitResults.h"
#include "FitSettings.h"
#include "ProgressReporter.h"
#include "AbstractFitter.h"

#include "FlagDefinitions.h"

#include "ConcurrencyAnalysis.h"

#include <memory>
#include <thread>
#include <atomic>

#define USE_GLOBAL_BINNING_AS_ESTIMATE    false
#define _CRTDBG_MAPALLOC

class ErrMinParams;

class FitController : public FitSettings

{
public:

   FitController();
   FitController(const FitSettings& fit_settings);
   ~FitController();

   void setFitSettings(const FitSettings& fit_settings);
   void setFittingOptions(const FittingOptions& options_) { options = options_; }
   void setData(std::shared_ptr<FLIMData> data);
   void setModel(std::shared_ptr<DecayModel> model_) { model = model_; }
   
   void init();
   int runWorkers();
   int getErrorCode();
   void waitForFit();
   void stopFit();
   
   int getFit(int im, int n_fit, uint fit_mask[], double fit[], int& n_valid);

   void getWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread);

   void cleanupResults();

   std::shared_ptr<ProgressReporter> getProgressReporter() { return reporter; }
   std::shared_ptr<FitResults> getResults() { return results; };
   std::shared_ptr<FLIMData> getData() { return data; }
   
protected:
   
   virtual void setFitComplete();

private:
   
   void workerThread(int thread);
   
   void cleanupTempVars();
   
   void processRegion(int g, int r, int px, int thread);

   std::shared_ptr<DecayModel> model;
   std::shared_ptr<FLIMData> data;
   std::shared_ptr<ProgressReporter> reporter;
   std::shared_ptr<FitResults> results;

   std::recursive_mutex cleanup_mutex;
   std::recursive_mutex mutex;

   std::vector<std::unique_ptr<AbstractFitter>> fitters;
   std::vector<RegionData> region_data;
   std::vector<std::thread> thread_handle;
   
   FittingOptions options;

   int cur_region;
   int next_pixel;
   int next_region;
   int threads_active;
   int threads_started;
   int threads_running;
   std::vector<int> cur_im;

   bool is_init = false;
   bool has_fit = false;
   bool getting_fit = false;
   int error = 0;
   
   std::mutex region_mutex;
   std::condition_variable active_lock;

   std::mutex fit_mutex;
   std::condition_variable fit_cv;
   
   int n_fitters;
   int n_omp_thread;

   double conf_factor;

   bool fit_in_progress = false;
   int n_fits = 0;
   std::atomic_int n_fits_complete;
};

