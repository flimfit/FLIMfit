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

#include "boost/math/distributions/normal.hpp"

#include "FitController.h"

#include "VariableProjectionFitter.h"
#include "MaximumLikelihoodFitter.h"
#include "util.h"

#include <thread>
#include "omp_stub.h"

#include <limits>
#include <exception>
#include <cmath>
#include <algorithm>

using std::min;

#ifdef USE_CONCURRENCY_ANALYSIS
marker_series* writer;
#endif

FitController::FitController()
{
   reporter = std::make_shared<ProgressReporter>("Fitting Data");
}

FitController::FitController(const FitSettings& fit_settings) :
   FitSettings(fit_settings)
{
   if (n_thread < 1)
      n_thread = 1;
   
   reporter = std::make_shared<ProgressReporter>("Fitting Data");
}

void FitController::setFitSettings(const FitSettings& settings)
{
   *static_cast<FitSettings*>(this) = settings;
   if (data)
      data->setGlobalScope(global_scope);
}

void FitController::stopFit()
{
   reporter->requestTermination();
}

int FitController::runWorkers()
{
   
   if (fit_in_progress)
      throw(std::runtime_error("Fit already running"));
   
   if (!is_init)
      throw(std::runtime_error("Controller has not been initalised"));

   reporter->reset();

   has_fit = false;
   fit_in_progress = true;
   threads_running = 0;


   omp_set_num_threads(n_omp_thread);

   for(int thread = 0; thread < n_fitters; thread++)
      thread_handle.push_back(std::thread(&FitController::workerThread, this, thread));
   
   if (!run_async)
      waitForFit();
   
   return 0;
   
}

/**
 * Worker thread, called several times to process regions
 */
void FitController::workerThread(int thread)
{
   int idx, region_count;
   
   threads_running++;
   
   //=============================================================================
   // In pixelwise mode, we process one region at a time, with all threads
   // working on the same region. When all threads are finished working
   // on a region, thread 0 gets the data for the next thread and processing
   // begins again. Use active_lock to ensure processes are kept in order
   //=============================================================================
   if (global_scope == MODE_PIXELWISE)
   {
      int n_active_thread = n_thread;
      for(int im=0; im<data->n_im_used; im++)
      {
         for(int r=0; r<MAX_REGION; r++)
         {
            if (data->getRegionIndex(im,r) > -1)
            {
               idx = im*MAX_REGION+r;

               if (thread > 0)
               {     
                  // If we are not thread 0, check if thread 0 has processed
                  // the data we need. If not, wait until it has been processed
                  
                  std::unique_lock<std::mutex> lk(region_mutex);
                  while (idx > cur_region && !reporter->shouldTerminate())
                     active_lock.wait(lk);
                  
                  threads_active++;
                  threads_started++;
               }
               else
               {                  
                  // If we are thread 0, check to see if all threads have started & finished on current region
                  // then request data for next region

                  std::unique_lock<std::mutex> lk(region_mutex);
                  while ( (threads_active > 0) ||                                  // there are threads running
                          ((threads_started < n_active_thread) && (cur_region >= 0)) ) // not all threads have yet started up
                     active_lock.wait(lk);
                    
                  data->getRegionData(0, im, r, region_data[0], *results, 1);
                  //data->ImageDataFinished(im);

                  next_pixel = 0;
                  
                  cur_region = idx;

                  threads_active++;
                  threads_started = 1;
                 
                  active_lock.notify_all();
               }

               // Process every n_thread'th pixel in region

               region_count = data->getRegionCount(im,r);

               int regions_per_thread = (int) ceil((double)region_count / n_thread);
               int j_max = min( regions_per_thread * (thread + 1), region_count );

               for(int j=regions_per_thread*thread; j<j_max; j++)
               {
                  processRegion(im, r, j, thread);
                  
                  // Check to see if a termination has been requested
                  if (reporter->shouldTerminate())
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
   else if (global_scope == MODE_IMAGEWISE)
   {
      int im0 = 0;
      int process_idx = 0;

processed: 

         region_mutex.lock();
         if (next_region >= data->getNumRegionsTotal())
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
                  idx = data->getRegionIndex(im,r);
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
                     //data->AllImageLowerDataFinished(release_im-1);

                     region_mutex.unlock();

                     processRegion(im, r, 0, thread);
                     
                     im0=im;
                     
 
                     goto processed;
                  }
            
                  if (reporter->shouldTerminate())
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
         //data->AllImageLowerDataFinished(release_im-1);

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
         idx = data->getRegionIndex(-1,r);
         if (idx > -1 && idx % n_thread == thread)
            processRegion(-1, r, 0, thread);
           
         if (reporter->shouldTerminate())
            break;
      }
   }

terminated:

   threads_running--;

   // If we're the last thread running cleanup temporary variables
   
   std::thread::id cur_id = std::this_thread::get_id();

   if (threads_running == 0 && run_async)
   {
      for(auto& t : thread_handle)
         if ( t.joinable() && t.get_id() != cur_id )
            t.join();

      setFitComplete();
   }
}

void FitController::setFitComplete()
{
   results->computeRegionStats(conf_factor);
   
   cleanupTempVars();
   reporter->setFinished();
   
   has_fit = true;
   fit_in_progress = false;
   fit_cv.notify_all();
}

void FitController::waitForFit()
{
   if (!has_fit)
   {
      std::unique_lock<std::mutex> lk(fit_mutex);
      while (!has_fit)
         fit_cv.wait(lk);
   }
}


void FitController::setData(std::shared_ptr<FLIMData> data_)
{
   data = data_;
   data->setGlobalScope(global_scope);
}



void FitController::init()
{
   cur_region = -1;
   next_pixel  = 0;
   next_region = 0;
   threads_active = 0;
   threads_started = 0;
   threads_running = 0;
   n_fits_complete = 0;

   cur_im.assign(n_thread, 0);

   getting_fit = false;

   model->setTransformedDataParameters(data->GetTransformedDataParameters());
   model->init();

   if (n_thread < 1)
      n_thread = 1;

   int max_px_per_image = data->getMaxPxPerImage();
   int max_fit_size = data->getMaxFitSize();
   int max_region_size = data->getMaxRegionSize();
   
   if (n_thread > max_px_per_image)
      n_thread = max_px_per_image;
   
    if (data->global_scope == MODE_GLOBAL || (data->global_scope == MODE_IMAGEWISE && max_px_per_image > 1))
      algorithm = ALG_LM;

   
   int n_regions_total = data->getNumRegionsTotal();
   
   
   if (data->global_scope == MODE_PIXELWISE)
   {
      n_fits = data->n_masked_px;
      n_fitters = min(max_region_size,n_thread);
   }
   else
   {
      n_fits = n_regions_total;
      n_fitters = min(n_regions_total,n_thread);
   }

   
   if (n_regions_total == 0)
      throw(std::runtime_error("No Regions in Data"));

   // Only create as many threads as there are regions if we have
   // fewer regions than maximum allowed number of thread
   //---------------------------------------

   
   if (n_fitters == 1)
      n_omp_thread = n_thread;
   else
      n_omp_thread = 1;
   
   // TODO: add exception handling here
   results.reset( new FitResults(model, data, calculate_errors) );

   // Create fitting objects
   fitters.clear();
   region_data.clear();

   fitters.reserve(n_fitters);
   region_data.reserve(n_fitters);

   for(int i=0; i<n_fitters; i++)
   {
      if (algorithm == ALG_ML)
         fitters.push_back( std::make_unique<MaximumLikelihoodFitter>(model, reporter) );
      else
         fitters.push_back( std::make_unique<VariableProjectionFitter>(model, max_fit_size, weighting, global_algorithm, n_omp_thread, reporter) );

      region_data.push_back( data->getNewRegionData() );
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

   is_init = true;
}



FitController::~FitController()
{
   // wait for threads to terminate
   for (auto& t : thread_handle)
      if (t.joinable())
         t.join();

   cleanupTempVars();
}


int FitController::getErrorCode()
{
   return error;
}




void FitController::cleanupTempVars()
{
   std::lock_guard<std::recursive_mutex> guard(cleanup_mutex);
//   region_data.clear();
}

