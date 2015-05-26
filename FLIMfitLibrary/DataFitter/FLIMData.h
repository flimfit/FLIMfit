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
#include "ProgressReporter.h"
#include "FLIMImage.h"
#include "AcquisitionParameters.h"

#include <cstdint>

#include <thread>
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

using std::vector;
using std::string;

class PoolTransformer
{
public:
   
   PoolTransformer(DataTransformationSettings transform) :
   transformer(transform)
   {
      
   }
   
   int refs = 0;
   int im = -1;
   DataTransformer transformer;
};

class FLIMData
{

public:

   FLIMData(const vector<std::shared_ptr<FLIMImage>>& images, const DataTransformationSettings& transform);
   FLIMData(std::shared_ptr<FLIMImage> image, const DataTransformationSettings& transform);

   void SetGlobalMode(int global_mode);

   RegionData* GetNewRegionData();

   template <typename T>
   int CalculateRegions();

   int GetRegionIndex(int im, int region);
   int GetOutputRegionIndex(int im, int region);
   int GetRegionPos(int im, int region);
   int GetRegionCount(int im, int region);

   int GetRegionData(int thread, int group, int region, RegionData& region_data, FitResults& results, int n_thread);

   std::shared_ptr<TransformedDataParameters> GetTransformedDataParameters() { return dp; }
   
   int GetMaxFitSize();
   int GetMaxRegionSize();
   int GetMaxPxPerImage() { return max_px_per_image; }
   int GetNumMeasurements() { return dp->n_meas; }
   int GetNumRegionsTotal() { return n_regions_total; }
   int GetNumOutputRegionsTotal() { return n_output_regions_total; }
   int GetNumAuxillary();
   void GetAuxParamNames(vector<string>& param_names);
   
   int GetImLoc(int im);

   void SetImageT0Shift(double* image_t0_shift);


   template <typename T>
   void DataLoaderThread(bool only_load_non_empty_images);

   int n_im = 0;

   int n_output_regions_total = 0;

   int data_skip = 0;

   int n_masked_px = 0;
   int merge_regions = false;

   double* image_t0_shift = nullptr;

   int global_mode = MODE_PIXELWISE;
   
   vector<int> use_im;
   int n_im_used = 0;

   int data_type = DATA_TYPE_TCSPC;
   
private:

   int GetMaskedData(int im, int region, float* masked_data, int* irf_idx, FitResults& results);
   void SetData(const vector<std::shared_ptr<FLIMImage>>& images);
   
   void ResizeBuffers();

   template <typename T>
   T* GetDataPointer(int thread, int im);

   std::vector<std::shared_ptr<FLIMImage>> images;

   FLIMImage::DataClass data_class = FLIMImage::DataFloat;

   std::vector<std::vector<int>> region_idx;
   std::vector<std::vector<int>> output_region_idx;
   std::vector<std::vector<int>> region_count;
   std::vector<std::vector<int>> region_pos;

   vector<PoolTransformer> transformer_pool;
   vector<int> pool_use_count;
   
   DataTransformer& getPooledTransformer(int im);
   void releasePooledTranformer(int im);
   std::mutex pool_mutex;
   
   shared_ptr<ProgressReporter> reporter;

   bool has_acceptor = false;
   bool polarisation_resolved = false;
   int max_px_per_image;
   
   DataTransformationSettings transform;
   std::shared_ptr<TransformedDataParameters> dp;

   int n_regions_total = 0;
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
   
   
   
   for(int i=0; i<n_im_used; i++)
   {
      //cp_async([&]()
      //{
         int im = use_im[i];

         // Determine how many regions we have in each image
         //--------------------------------------------------------
         vector<int>& region_count_ptr = region_count[i];
         region_count_ptr.assign(MAX_REGION, 0);
         
         DataTransformer transformer(transform);
         transformer.setImage(images[im]);
         
         auto& mask = transformer.getMask();
         
         int n_px = mask.size();
         
         if (merge_regions)
         {
            for(int p=0; p<n_px; p++)
               region_count_ptr[mask[p]>0]++;
         }
         else
         {
            for(int p=0; p<n_px; p++)
               region_count_ptr[mask[p]]++;
         }

         // Calculate region indexes
         for(int r=1; r<MAX_REGION; r++)
         {
            region_pos[i][r] = cur_pos;
            cur_pos += region_count[i][r];
            if (region_count[i][r] > 0)
               output_region_idx[i][r] = r_idx++;
         }
      //});
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
            region_pos[i][j] = cur_pos;
            cur_pos += region_count[i][j];
            r_count += region_count[i][j];

            if (region_count[i][j] > 0)
               region_idx[i+1][j] = r_idx;
         }

         if (r_count > 0)
         {
            region_idx[0][j] = r_idx;
            r_idx++;
         }

      }
   }
   else
   {
      for(int r=0; r<MAX_REGION; r++)
         for(int i=0; i<n_im_used; i++)
         region_idx[i][r] = output_region_idx[i][r];
   }
   
   n_masked_px = cur_pos;
   n_regions_total = r_idx;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return err;

}

/*

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
 
 */

