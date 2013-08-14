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

using namespace std;
using namespace boost::interprocess;

#ifdef USE_CONCURRENCY_ANALYSIS
marker_series* writer;
#endif


FLIMGlobalFitController::FLIMGlobalFitController(int global_algorithm, DecayModel* model, int algorithm,
                                                 int weighting, int calculate_errors, double conf_interval,
                                                 int n_thread, int runAsync, int (*callback)()) :
   global_algorithm(global_algorithm), 
   n_thread(n_thread), runAsync(runAsync), callback(callback), algorithm(algorithm),
   weighting(weighting), calculate_errors(calculate_errors), conf_interval(conf_interval),
   error(0), init(false), has_fit(false), model(model)
{

   if (this->n_thread < 1)
      this->n_thread = 1;

   params = new WorkerParams[this->n_thread]; //ok
   status = new FitStatus(model,this->n_thread,NULL); //ok
  /*
   alf          = NULL;
   chi2         = NULL;
   I            = NULL;
   r_ss         = NULL;
   w_mean_tau   = NULL;
   mean_tau     = NULL;
   cur_alf      = NULL;
   cur_irf_idx  = NULL;
   acceptor     = NULL;
   */
   /*
   ierr         = NULL;
   success      = NULL;

   y            = NULL;
   lin_params   = NULL;

   w            = NULL;

   irf_buf      = NULL;
   t_irf_buf    = NULL;
   exp_buf      = NULL;
   tau_buf      = NULL;
   beta_buf     = NULL;
   theta_buf    = NULL;
   adjust_buf   = NULL;
   decay_group_buf = NULL;

   irf_max      = NULL;
   
   lin_params_err = NULL;
   alf_err_lower  = NULL;
   alf_err_upper  = NULL;

   chan_fact      = NULL;
   irf_idx        = NULL;

   param_names_ptr = NULL;
   */
   //local_decay = NULL;
   data = NULL;
   model = NULL;
   /*
   alf_local = NULL;
   lin_local = NULL;
   */

   cur_im = NULL;

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

   data->StartStreaming();
   status->AddConditionVariable(&active_lock);

   if (n_fitters == 1 && !runAsync)
   {
      params[0].controller = this;
      params[0].thread = 0;

      StartWorkerThread((void*)(params));
   }
   else
   {
      for(int thread = 0; thread < n_fitters; thread++)
      {
         params[thread].controller = this;
         params[thread].thread = thread;
      
         thread_handle.push_back(
               new tthread::thread(StartWorkerThread,(void*)(params+thread))
            ); // ok
      }

      if (!runAsync)
      {
         boost::ptr_vector<tthread::thread>::iterator iter = thread_handle.begin();
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

               int regions_per_thread = ceil((double)region_count / n_thread);
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
      boost::ptr_vector<tthread::thread>::iterator iter = thread_handle.begin();
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


void FLIMGlobalFitController::SetData(FLIMData* data)
{
   this->data = data;
}


 


void FLIMGlobalFitController::Init()
{

   cur_region = -1;
   next_pixel  = 0;
   next_region = 0;
   threads_active = 0;
   threads_started = 0;

   cur_im = new int[n_thread];
   memset(cur_im,0,n_thread*sizeof(int));

   getting_fit    = false;
   

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

   // Supplied t_rep in seconds, convert to ps
   // TODO: make sure we convert this properly... this->t_rep = t_rep * 1e12;
   

   int max_region_size;

   if (data->global_mode == MODE_GLOBAL)
      max_region_size = data->n_masked_px;                              // (varp) Number of pixels (right hand sides)
   else if (data->global_mode == MODE_IMAGEWISE)
      max_region_size = data->n_px;
   else
      max_region_size = 1;

   y_dim = max(max_region_size,data->n_px);


   /*
   int max_dim = max(n_irf,n_t);
   max_dim = (int) (ceil(max_dim/4.0) * 4);


   exp_dim = max_dim * n_chan;
   */


   //nl = model->nl;
   //p = model->p; 


   // If using MLE, need an extra non-linear scaling factor
   // TODO
   //if (algorithm == ALG_ML)
   //{
   //   nl += l;
   //}


   // TODO: add exception handling here
   results = new FitResults(model, data, calculate_errors);


   // Create fitting objects
   projectors.reserve(n_fitters);
   region_data.reserve(n_fitters);

   for(int i=0; i<n_fitters; i++)
   {
      if (algorithm == ALG_ML)
         projectors.push_back( new MaximumLikelihoodFitter(model, &(status->terminate)) );
      else
//         projectors.push_back( new VariableProjector(this, s, l, nl, n, ndim, p, t, image_irf | (t0_image != NULL), weighting, n_omp_thread, &(status->terminate)) );
         projectors.push_back( new VariableProjector(model, max_region_size, n_omp_thread, &(status->terminate)) );

      region_data.push_back( new RegionData(max_region_size, data->n_meas) );
   }

   for(int i=0; i<n_fitters; i++)
   {
      if (projectors[i].err != 0)
         error = projectors[i].err;
   }


   


   // standard normal distribution object:
   boost::math::normal norm;
   conf_factor = quantile(complement(norm, 0.5*conf_interval));


}



FLIMGlobalFitController::~FLIMGlobalFitController()
{
   status->Terminate();

   while (status->IsRunning()) {}

   CleanupResults();
   CleanupTempVars();

   delete status;
   delete[] params;

}


int FLIMGlobalFitController::GetErrorCode()
{
   return error;
}




void FLIMGlobalFitController::CleanupTempVars()
{

   tthread::lock_guard<tthread::recursive_mutex> guard(cleanup_mutex);
   
   region_data.clear();

   boost::ptr_vector<AbstractFitter>::iterator iter = projectors.begin();
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
      ClearVariable(cur_im);
      
      if (data != NULL)
      {
         delete data;
         data = NULL;
      }

     _ASSERTE(_CrtCheckMemory());
}

#endif