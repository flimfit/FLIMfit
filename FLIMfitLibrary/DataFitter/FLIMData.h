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

#include "RegionData.h"
#include "FitResults.h"
#include "FitStatus.h"
#include "FLIMImage.h"
#include "AcquisitionParameters.h"

#include <cstdint>

#include <memory>
#include <limits>
#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>

#include "FlagDefinitions.h"
#include "ConcurrencyAnalysis.h"

#include "omp_stub.h"

#define MAX_REGION 255

#define STREAM_DATA  true

using std::vector;
using std::string;

class FLIMData
{

public:

   FLIMData();

   void SetAcquisitionParmeters(const AcquisitionParameters& acq);
   void SetMasking(int* use_im, uint8_t mask[], int merge_regions = false);
   void SetThresholds(int threshold, int limit);
   void SetGlobalMode(int global_mode);

   void SetData(const vector<std::shared_ptr<FLIMImage>>& images);

   /* TODO: MOVE TO FLIMImages
   void SetNumImages(int n_im);
   int SetData(float data[]);
   int SetData(uint16_t data[]);
   int SetData(const char* data_file, int data_class, int data_skip);
   int SetAcceptor(float acceptor[]);
    */
   
   void SetStatus(shared_ptr<FitStatus> status_);
   void SetNumThreads(int n_thread);

   template <typename T>
   int CalculateRegions();

   int GetRegionIndex(int im, int region);
   int GetOutputRegionIndex(int im, int region);
   int GetRegionPos(int im, int region);
   int GetRegionCount(int im, int region);

   int GetRegionData(int thread, int group, int region, RegionData& region_data, FitResults& results, int n_thread);

   int GetNumAuxillary();
   void GetAuxParamNames(vector<string>& param_names);
   
   int GetImLoc(int im);

   double* GetT();  

   double GetPhotonsPerCount();

   void SetImageT0Shift(double* image_t0_shift);
   void ClearMapping();
   
   void ImageDataFinished(int im);
   void AllImageLowerDataFinished(int im);
   void StartStreaming(bool only_load_non_empty_images = true);
   void StopStreaming();

   template <typename T>
   void DataLoaderThread(bool only_load_non_empty_images);

   ~FLIMData();

   int n_im = 0;

   int n_regions_total = 0;
   int n_output_regions_total = 0;

   int data_skip = 0;

   vector<vector<uint8_t>> mask;
   int n_masked_px = 0;
   int merge_regions = false;

   double* image_t0_shift = nullptr;

   int global_mode = MODE_PIXELWISE;
   
   vector<int> use_im;
   int n_im_used = 0;

   int has_acceptor = false;

private:

   int GetMaskedData(int thread, int im, int region, float* masked_data, int* irf_idx, FitResults& results);

   void ResizeBuffers();

   template <typename T>
   T* GetDataPointer(int thread, int im);

   template <typename T>
   void TransformImage(int thread, int im);

   template <typename T>
   int GetStreamedData(int im, int thread, T*& data);
   
   void MarkCompleted(int slot);

   void* data;

   std::vector<std::vector<float>> tr_data_;
   std::vector<std::vector<float>> tr_buf_;
   std::vector<std::vector<float>> tr_row_buf_;
   std::vector<std::vector<float>> intensity_;
   std::vector<std::vector<float>> r_ss_;
   

   std::vector<std::shared_ptr<FLIMImage>> images;

   
   /* TODO: MOVE TO FLIMImage
   float* acceptor_ = nullptr;



   char *data_file; 

   
   int has_data = false;
    */
   
   
   int background_type = BG_NONE;
   float background_value = 0;
   float* background_image = nullptr;

   float* tvb_profile = nullptr;
   float* tvb_I_map = nullptr;

   int n_thread = 1;

   int threshold = 3;
   int limit = INT_MAX;

   std::vector<int> cur_transformed;

   int data_class = DATA_FLOAT;

   std::vector<int> region_idx;
   std::vector<int> output_region_idx;
   std::vector<int> region_count;
   std::vector<int> region_pos;

   std::vector<int> data_used;
   std::vector<int> data_loaded;

   bool stream_data = STREAM_DATA;

   tthread::thread* loader_thread;
   tthread::mutex data_mutex;
   tthread::condition_variable data_avail_cond;
   tthread::condition_variable data_used_cond;

   shared_ptr<FitStatus> status;

   friend void StartDataLoaderThread(void* wparams);
};


struct DataLoaderThreadParams
{
   FLIMData* data;
   bool only_load_non_empty_images;
};

void StartDataLoaderThread(void* wparams);


template <typename T>
int FLIMData::CalculateRegions()
{
   INIT_CONCURRENCY;

   int err = 0;

   int cur_pos = 0;
   
   n_regions_total = 0;

   int r_count = 0;
   int r_idx = 0; 
   
   omp_set_num_threads(n_thread);

   double tvb_sum = 0;
   if (background_type == BG_TV_IMAGE)
      for(int i=0; i<n_meas; i++)
         tvb_sum += tvb_profile[i];
   else
      tvb_sum = 0;
   
   int n_px = acq->n_px;
  

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Loading Data");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   StartStreaming(false);

   //#pragma omp parallel for schedule(dynamic, 1)
   for(int i=0; i<n_im_used; i++)
   {
      int thread = omp_get_thread_num();

      int im = use_im[i];

      T* cur_data_ptr;
      int slot = GetStreamedData(i, thread, cur_data_ptr);

      // We already have segmentation mask, now calculate integrated intensity
      // and apply min intensity and max bin mask
      //----------------------------------------------------
      if (slot >= 0)
      {
         for(int p=0; p<n_px; p++)
         {
            T* ptr = cur_data_ptr + p*n_meas_full;
            uint8_t* mask_ptr = mask[im].data() + p;
            double intensity = 0;
            for(int k=0; k<n_chan; k++)
            {
               for(int j=0; j<n_t_full; j++)
               {
                  if (limit > 0 && *ptr >= limit)
                     *mask_ptr = 0;

                  intensity += *ptr;
                  ptr++;
               }
            }
            if (background_type == BG_VALUE)
               intensity -= background_value * n_meas_full;
            else if (background_type == BG_IMAGE)
               intensity -= background_image[p] * n_meas_full;
            else if (background_type == BG_TV_IMAGE)
               intensity -= (tvb_sum * tvb_I_map[p] + background_value * n_meas_full);

            if (intensity < threshold || *mask_ptr < 0 || *mask_ptr >= MAX_REGION)
               *mask_ptr = 0;

         }
      }
      MarkCompleted(slot);
   }

   for(int i=0; i<n_im_used; i++)
   {
      int im = use_im[i];

      // Determine how many regions we have in each image
      //--------------------------------------------------------
      int*     region_count_ptr = region_count.data() + i * MAX_REGION;
      uint8_t* mask_ptr         = mask[im].data();

      memset(region_count_ptr, 0, MAX_REGION*sizeof(int));
      

      if (merge_regions)
      {
         for(int p=0; p<n_px; p++)
            region_count_ptr[(*(mask_ptr++)>0)]++;
      }
      else
      {
         for(int p=0; p<n_px; p++)
            region_count_ptr[*(mask_ptr++)]++;  
      }

      // Calculate region indexes
      for(int r=1; r<MAX_REGION; r++)
      {
         region_pos[ i* MAX_REGION + r ] = cur_pos;
         cur_pos += region_count[ i * MAX_REGION + r ];
         if (region_count[ i * MAX_REGION + r ] > 0)
            output_region_idx[ i * MAX_REGION + r ] = r_idx++;
      }


   }
   
   n_output_regions_total = r_idx;

   //Calculate global region indices
   if (global_mode == MODE_GLOBAL)
   {
      cur_pos = 0;
      r_idx = 0;

      for(int j=1; j<MAX_REGION; j++)
      {
         r_count = 0;
         for(int i=0; i<n_im_used; i++)
         {
            region_pos[ j + i* MAX_REGION ] = cur_pos;
            cur_pos += region_count[ j + i * MAX_REGION ];
            r_count += region_count[ j + i * MAX_REGION ];

            if (region_count[ j + i * MAX_REGION ] > 0)
               region_idx[ j + (i+1) * MAX_REGION ] = r_idx;
         }

         if (r_count > 0)
         {
            region_idx[ j ] = r_idx;
            r_idx++;
         }

      }
   }
   else
   {
      for(int i=0; i<MAX_REGION*n_im_used; i++)
         region_idx[i] = output_region_idx[i];
   }
   
   n_masked_px = cur_pos;
   n_regions_total = r_idx;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   StopStreaming();

   return err;

}

template <typename T>
void FLIMData::DataLoaderThread(bool only_load_non_empty_images)
{
   data_loaded.assign(n_thread, -1);
   data_used.assign(n_thread, -1);

   int free_slot;
   bool load_image;

   int n_p = n_meas_full * n_x * n_y;

   for(int im=0; im<n_im_used; im++)
   {
      if (only_load_non_empty_images)
      {
         load_image = false;
         for (int r = 0; r < MAX_REGION; r++ )
         {
            if (GetRegionIndex(im, r) > -1)
            {
               load_image = true;
               break;
            }
         }
      }
      else
      {
         load_image = true;
      }
      
      if (load_image) // don't try and load data if there are no regions
      {
         data_mutex.lock();

         // wait for some space to become free
         do
         {
            free_slot = -1;
            for(int j=0; j<n_thread; j++)
            {
               if (data_used[j])
               {
                  free_slot = j;
                  break;
               }
            }   

            if (status != nullptr && status->terminate)
               free_slot = -2;

            if (free_slot == -1)
               data_used_cond.wait(data_mutex);
                  
         }
         while( free_slot == -1 );

         if (free_slot >= 0)
            data_used[free_slot] = 0;

         data_mutex.unlock();

         if (free_slot == -2)
            return;

         T* tr_buf = (T*) tr_buf_[free_slot].data();
         T* data_ptr = images[im].getDataPointer<T>();
         memcpy(tr_buf, data_ptr, n_p * sizeof(T));
         data_loaded[free_slot] = im;

         data_avail_cond.notify_all();
      }
   }


}

template <typename T>
int FLIMData::GetStreamedData(int im, int thread, T*& data)
{
   int n_p = n_meas_full * n_x * n_y;

   if (stream_data)
   {
    // Get data from loading thread
      data_mutex.lock();

      int slot;
      do
      {

         slot = -1;
         for(int j=0; j<n_thread; j++)
         {
            if (data_loaded[j]==im)
            {
               slot = j;
               break;
            }
         }   
         if (status != nullptr && status->terminate)
            slot = -2;

         if (slot == -1)
            data_avail_cond.wait(data_mutex);
      }
      while( slot == -1 );
      data_mutex.unlock();

      if (slot < 0)
      {
         data = NULL;
         slot = -1;
      }
      else
         data = (T*) tr_buf_[slot].data();

      return slot;

   }
   else
   {

      T* tr_buf = (T*) this->tr_buf_[thread].data();
      T* data_ptr = images[im].getDataPointer<T>();
      memcpy(tr_buf, data_ptr, n_p * sizeof(T));
      data = tr_buf;

      return 0;

   }
}

