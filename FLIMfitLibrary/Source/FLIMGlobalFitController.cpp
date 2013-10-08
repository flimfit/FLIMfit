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

#ifndef FLIMGLOBALFITCONTROLLER_H_
#define FLIMGLOBALFITCONTROLLER_H_

#include "boost/math/distributions/normal.hpp"

#include "FLIMGlobalFitController.h"

#include "VariableProjector.h"
#include "MaximumLikelihoodFitter.h"
#include "util.h"

#include "tinythread.h"
#include "omp_stub.h"

#include <limits>
#include <exception>
#include <cmath>
#include <algorithm>

//using namespace boost::interprocess;

using std::min;

#ifdef USE_CONCURRENCY_ANALYSIS
marker_series* writer;
#endif


FLIMGlobalFitController::FLIMGlobalFitController() :
   error(0),init(false), has_fit(false), model(NULL), 
   worker_params(NULL), status(NULL)

{
}

FLIMGlobalFitController::FLIMGlobalFitController(int polarisation_resolved, int global_algorithm, ModelParameters& model_params, int algorithm,
                                                 int weighting, int calculate_errors, double conf_interval,
                                                 int n_thread, int runAsync, int (*callback)()) :
   polarisation_resolved(polarisation_resolved), global_algorithm(global_algorithm), model_params(model_params),
   n_thread(n_thread), runAsync(runAsync), callback(callback), algorithm(algorithm),
   weighting(weighting), calculate_errors(calculate_errors), conf_interval(conf_interval),
   error(0),init(false), has_fit(false)
{
   if (this->n_thread < 1)
      this->n_thread = 1;

   worker_params = new WorkerParams[this->n_thread]; //ok
   status = new FitStatus(this->n_thread,NULL); //ok

}

bool FLIMGlobalFitController::Busy()
{
   if (!init)
      return false;
   else
      return status->IsRunning();
}


int FLIMGlobalFitController::RunWorkers()
{
   
   if (status->IsRunning())
      return ERR_FIT_IN_PROGRESS;

   if (!init)
      return ERR_COULD_NOT_START_FIT;

   if (status->terminate)
      return 0;

   omp_set_num_threads(n_omp_thread);

   data->irf = irf;
   model->irf = irf;

   data->StartStreaming();
   status->AddConditionVariable(&active_lock);

   if (n_fitters == 1 && !runAsync)
   {
      worker_params[0].controller = this;
      worker_params[0].thread = 0;

      StartWorkerThread((void*)(worker_params));
   }
   else
   {
      for(int thread = 0; thread < n_fitters; thread++)
      {
         worker_params[thread].controller = this;
         worker_params[thread].thread = thread;
      
         thread_handle.push_back(
               new tthread::thread(StartWorkerThread,(void*)(worker_params+thread))
            ); // ok
      }

      if (!runAsync)
      {
         ptr_vector<tthread::thread>::iterator iter = thread_handle.begin();
         while (iter != projectors.end())
         {
            iter->join();
            iter++;
         }

         data->StopStreaming();

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
	  int n_active_thread = min(n_thread,data->n_px);
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

                  while (idx > cur_region && !(status->terminate))
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
                          (threads_started < n_active_thread && cur_region >= 0) ) // not all threads have yet started up
                     active_lock.wait(region_mutex);
                    
                  data->GetRegionData(0, im, r, region_data[0], *results, 1);
                  data->ImageDataFinished(im);

                  next_pixel = 0;
                  
                  cur_region = idx;

                  threads_active++;
                  threads_started = 1;
                 
                  active_lock.notify_all();
                  region_mutex.unlock();

               }

               // Process every n_thread'th pixel in region

               region_count = data->GetRegionCount(im,r);

               int regions_per_thread = (int) ceil((double)region_count / n_thread);
               int j_max = min( regions_per_thread * (thread + 1), region_count );

               for(int j=regions_per_thread*thread; j<j_max; j++)
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
      int im0 = 0;
      int process_idx = 0;

processed: 

         region_mutex.lock();
         if (next_region >= data->n_regions_total)
            process_idx = -1;
         else
            process_idx = next_region++;
         region_mutex.unlock();

         // Cycle through every region in every image
         if (process_idx >= 0)
         {
            for(int im=im0; im<data->n_im_used; im++)
            {
               for(int r=0; r<MAX_REGION; r++)
               {
                  // Get region index and process if it exists and is for this threads
                  idx = data->GetRegionIndex(im,r);
                  if (idx == process_idx)  // should be processed by this thread
                  {
                     

                     region_mutex.lock();
                     cur_im[thread] = im;

                     int release_im = cur_im[0];
                     for(int i=1; i<n_thread; i++)
                     {
                        if (cur_im[i] < release_im)
                           release_im = cur_im[i];
                     }            
                     data->AllImageLowerDataFinished(release_im-1);

                     region_mutex.unlock();

                     ProcessRegion(im, r, 0, thread);
                     
                     im0=im;
                     
 
                     goto processed;
                  }
            
                  if (status->terminate)
                     goto imagewise_terminated;
               }


            }

         }

imagewise_terminated:

		   // When thread detaches make sure we release correctly
		   region_mutex.lock();
         cur_im[thread] = -1;

         int release_im = cur_im[0];
         for(int i=1; i<n_thread; i++)
         {
         if (cur_im[i] >= 0 && cur_im[i] < release_im)
            release_im = cur_im[i];
         }            
         data->AllImageLowerDataFinished(release_im-1);

         region_mutex.unlock();
      
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
            break;
      }
   }

terminated:

   int threads_running = status->RemoveThread();

   // If we're the last thread running cleanup temporary variables
   
   tthread::thread::id cur_id = tthread::this_thread::get_id();

   if (threads_running == 0 && runAsync)
   {
      ptr_vector<tthread::thread>::iterator iter = thread_handle.begin();
         while (iter != projectors.end())
         {
            if ( iter->joinable() && iter->get_id() != cur_id )
               iter->join();
            iter++;
         }

      data->StopStreaming();
      CleanupTempVars();
   }
}


void FLIMGlobalFitController::SetData(shared_ptr<FLIMData> data_)
{
   data = data_;
}

void FLIMGlobalFitController::SetIRF(shared_ptr<InstrumentResponseFunction> irf_)
{
   irf = irf_;
}
 


void FLIMGlobalFitController::Init()
{

   cur_region = -1;
   next_pixel  = 0;
   next_region = 0;
   threads_active = 0;
   threads_started = 0;

   cur_im.assign(n_thread, 0);

   getting_fit    = false;

   model.reset( new DecayModel(model_params, *data, irf) );
   model->Init();

   if (n_thread < 1)
      n_thread = 1;

   
   if (data->global_mode == MODE_GLOBAL || (data->global_mode == MODE_IMAGEWISE && data->n_px > 1))
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
   

   int max_fit_size;
   int max_region_size;

   if (data->global_mode == MODE_GLOBAL)
      max_fit_size = data->n_masked_px;                              // (varp) Number of pixels (right hand sides)
   else if (data->global_mode == MODE_IMAGEWISE)
      max_fit_size = data->n_px;
   else
      max_fit_size = 1;

   if (data->global_mode == MODE_PIXELWISE)
      max_region_size = data->n_px;                             // We retrieve whole images at a time
   else if (data->global_mode == MODE_IMAGEWISE)
      max_region_size = max_fit_size;
   else
      max_region_size = 1;

   //y_dim = max(max_region_size,data->n_px);


   /*


   exp_dim = max_dim * n_chan;
   */


   // TODO: add exception handling here
   results.reset( new FitResults(model, data, calculate_errors) );


   // Create fitting objects
   projectors.reserve(n_fitters);
   region_data.reserve(n_fitters);

   for(int i=0; i<n_fitters; i++)
   {
      if (algorithm == ALG_ML)
         projectors.push_back( new MaximumLikelihoodFitter(model, &(status->terminate)) );
      else
         projectors.push_back( new VariableProjector(model, max_fit_size, weighting, global_algorithm, n_omp_thread, &(status->terminate)) );

      region_data.push_back( new RegionData(data->data_type, max_region_size, data->n_meas) );
   }

   /*
   TODO: replace this
   for(int i=0; i<n_fitters; i++)
   {
      if (projectors[i].err != 0)
         error = projectors[i].err;
   }
   */

   


   // standard normal distribution object:
   boost::math::normal norm;
   conf_factor = quantile(complement(norm, 0.5*conf_interval));


   init = true;

}



FLIMGlobalFitController::~FLIMGlobalFitController()
{
   if (status != NULL)
   {
      status->Terminate();
      while (status->IsRunning()) {}
   }

   CleanupResults();
   CleanupTempVars();

   delete status;
   delete[] worker_params;

}


int FLIMGlobalFitController::GetErrorCode()
{
   return error;
}




void FLIMGlobalFitController::CleanupTempVars()
{

   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);
   
   region_data.clear();

   ptr_vector<AbstractFitter>::iterator iter = projectors.begin();
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
      /*
   ClearVariable(lin_local);
   ClearVariable(alf_local);
   ClearVariable(tau_buf);
   ClearVariable(beta_buf);
   ClearVariable(theta_buf);
   ClearVariable(chan_fact);
   ClearVariable(cur_alf);
   ClearVariable(cur_irf_idx);


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


      ClearVariable(irf_max);
      ClearVariable(adjust_buf);
      ClearVariable(local_decay);
      ClearVariable(decay_group_buf);

      ClearVariable(irf_idx);

      ClearVariable(y);
      ClearVariable(w);
      
      ClearVariable(param_names_ptr);
      */
      
     _ASSERTE(_CrtCheckMemory());
}

#endif