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

#ifndef _FLIMDATA_
#define _FLIMDATA_

#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <stdint.h>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include "tinythread.h"
#include "FitStatus.h"

#include "FlagDefinitions.h"
#include "ConcurrencyAnalysis.h"

#include "omp_stub.h"


#define MAX_REGION 255

using namespace boost;

class FLIMData
{

public:

   FLIMData(int polarisation_resolved, double g_factor, int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], double t_int[], int t_skip[], int n_t, int data_type,
            int* use_im, uint8_t mask[], int threshold, int limit, double counts_per_photon, int global_mode, int smoothing_factor, int use_autosampling, int n_thread, FitStatus* status);

   int  SetData(float data[]);
   int  SetData(uint16_t data[]);
   int  SetData(char* data_file, int data_class, int data_skip);

   int  SetAcceptor(float acceptor[]);
   
   template <typename T>
   int CalculateRegions();

   void DetermineAutoSampling(int thread, float decay[], int n_min_bin);

   int GetRegionIndex(int im, int region);
   int GetOutputRegionIndex(int im, int region);
   int GetRegionPos(int im, int region);
   int GetRegionCount(int im, int region);

   int GetRegionData(int thread, int group, int region, int px, float* region_data, float* intensity_data, float* r_ss_data, float* acceptor_data, float* weight, int* irf_idx, float* local_decay);
   int GetMaskedData(int thread, int im, int region, float* masked_data, float* masked_intensity, float* masked_r_ss, float* masked_acceptor, int* irf_idx);

   
   int GetImLoc(int im);

   void SetExternalResampleIdx(int ext_n_meas_res, int* ext_resample_idx);
   int* GetResampleIdx(int thread);
   int GetResampleNumMeas(int thread);

   double* GetT();  

   void SetBackground(float* background_image);
   void SetBackground(float background);
   void SetTVBackground(float* tvb_profile, float* tvb_I_map, float const_background);

   void ClearMapping();
   
   template <typename T>
   void DataLoaderThread();



   ~FLIMData();

   int n_im;
   int n_x;
   int n_y;
   int n_t;
   int n_buf;

   int n_chan;
   int n_meas;

   int n_px;
   int n_p;

   int n_regions_total;
   int n_output_regions_total;
   int max_region_size;
   int data_type;

   int data_skip;

   int use_autosampling;

   uint8_t* mask;
   int n_masked_px;


   int global_mode;

   int smoothing_factor;
   double smoothing_area;

   int* t_skip;

   double* t;
   double* t_int;

   double counts_per_photon;

   int* use_im;
   int n_im_used;

   int has_acceptor;

private:

   template <typename T>
   T* GetDataPointer(int thread, int im);

   template <typename T>
   void TransformImage(int thread, int im);

   template <typename T>
   int GetStreamedData(int im, T*& data);
   
   void MarkCompleted(int slot);

   void* data;

   float* tr_data_;
   float* tr_buf_;
   float* tr_row_buf_;
   float* intensity_;
   float* r_ss_;
   float* acceptor_;

   boost::interprocess::file_mapping data_map_file;
   boost::interprocess::mapped_region* data_map_view;

   char *data_file; 

   int data_mode;
   
   int has_data;
   int supplied_mask;

   int background_type;
   float background_value;
   float* background_image;

   float* tvb_profile;
   float* tvb_I_map;

   int n_thread;

   int n_meas_full;

   int n_t_full;

   int threshold;
   int limit;

   int* cur_transformed;

   float* average_data;

   int data_class;

   int* resample_idx;
   int* n_meas_res;

   bool use_ext_resample_idx;
   int* ext_resample_idx;
   int ext_n_meas_res;

   int polarisation_resolved;
   double g_factor;

   int* region_idx;
   int* output_region_idx;
   int* region_count;
   int* region_pos;

   int* data_used;
   int* data_loaded;

   tthread::thread* loader_thread;
   tthread::mutex data_mutex;
   tthread::condition_variable data_avail_cond;
   tthread::condition_variable data_used_cond;

   FitStatus *status;

   friend void StartDataLoaderThread(void* wparams);

};


template <typename T>
T* FLIMData::GetDataPointer(int thread, int im)
{
   using namespace boost::interprocess;

   if (use_im != NULL)
      im = use_im[im];
   unsigned long long offset, buf_size;

   unsigned long long int im_size = n_t_full * n_chan * n_x * n_y;

   int data_size = sizeof(T);

   T* data_ptr;

   try
   {
      if (data_mode == DATA_MAPPED)
      {
         buf_size = im_size * data_size;
         offset   = im * im_size * data_size + data_skip;

         data_map_view[thread] = mapped_region(data_map_file, read_only, offset, buf_size);
         data_ptr = (T*) data_map_view[thread].get_address();
      }
      else 
      {
         data_ptr = ((T*)data) + im * im_size;
      }
   }
   catch(std::exception& e)
   {
      e = e;
      data_ptr = NULL;
   }

   return data_ptr;
}



template <typename T>
int FLIMData::CalculateRegions()
{
   int err = 0;

   int cur_pos = 0;
   int average_count = 0;
   
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
  

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   span* s = new span (*writer, _T("Loading Data"));
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   tthread::thread loader_thread(StartDataLoaderThread,(void*)this); // ok


   #pragma omp parallel for schedule(dynamic, 1)
   for(int i=0; i<n_im_used; i++)
   {

      int im = i;
      if (use_im != NULL)
            im = use_im[im];

      T* cur_data_ptr;
      int slot = GetStreamedData(i, cur_data_ptr);

      // We already have segmentation mask, now calculate integrated intensity
      // and apply min intensity and max bin mask
      //----------------------------------------------------
         
      for(int p=0; p<n_px; p++)
      {
         T* ptr = cur_data_ptr + p*n_meas_full;
         uint8_t* mask_ptr = mask + im*n_px + p;
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

      MarkCompleted(slot);

      // Determine how many regions we have in each image
      //--------------------------------------------------------
      int*     region_count_ptr = region_count + i * MAX_REGION;
      uint8_t* mask_ptr         = mask + im*n_px;

      memset(region_count_ptr, 0, MAX_REGION*sizeof(int));
      
      for(int p=0; p<n_px; p++)
         region_count_ptr[*(mask_ptr++)]++;

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
   delete s;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return err;

}

template <typename T>
void FLIMData::DataLoaderThread()
{
   for(int i=0; i<n_thread; i++)
   {
      data_loaded[i] = -1;
      data_used[i] = 1;
   }

   int free_slot;

   for(int im=0; im<n_im_used; im++)
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

         if (status->terminate)
            return;

         if (free_slot == -1)
            data_used_cond.wait(data_mutex);
                  
      }
      while( free_slot == -1 );

      data_used[free_slot] = 0;

      data_mutex.unlock();

      T* tr_buf = (T*) this->tr_buf_  + free_slot * n_p;
      T* data_ptr = GetDataPointer<T>(free_slot, im);
      memcpy(tr_buf, data_ptr, n_p * sizeof(T));
      data_loaded[free_slot] = im;

      data_avail_cond.notify_all();
   }


}

template <typename T>
int FLIMData::GetStreamedData(int im, T*& data)
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

      if (slot == -1)
         data_avail_cond.wait(data_mutex);
   }
   while( slot == -1 );
   data_mutex.unlock();

   data = (T*) tr_buf_  + slot * n_p;

   return slot;
}

template <typename T>
void FLIMData::TransformImage(int thread, int im)
{
   int idx, tr_idx;

   if (im == cur_transformed[thread])
      return;

   float* tr_data    = tr_data_    + thread * n_p;
   float* intensity  = intensity_  + thread * n_px;
   float* r_ss       = r_ss_       + thread * n_px;
   float* tr_row_buf = tr_row_buf_ + thread * (n_x + n_y);


   T* tr_buf;
   int slot = GetStreamedData(im, tr_buf);  
   T* cur_data_ptr = tr_buf;

      
   float photons_per_count = (float) (1/counts_per_photon);

   
   if ( smoothing_factor == 0 )
   {
      float* tr_ptr = tr_data;
      // Copy data from source to tr_data, skipping cropped time points
      for(int y=0; y<n_y; y++)
         for(int x=0; x<n_x; x++)
            for(int c=0; c<n_chan; c++)
            {
               for(int i=0; i<n_t; i++)
                  tr_ptr[i] = cur_data_ptr[t_skip[c]+i];
               cur_data_ptr += n_t_full;
               tr_ptr += n_t;
            }
   }
   else
   {
      int s = smoothing_factor;

      int dxt = n_meas; 
      int dyt = n_x * dxt; 

      int dx = n_meas_full;
      int dy = n_x * dx; 

      float* y_smoothed_buf = intensity; // use intensity as a buffer

      for(int c=0; c<n_chan; c++)
      {
         for(int i=0; i<n_t; i++)
         {
            tr_idx = c*n_t + i;
            idx = c*n_t_full + t_skip[c] + i;

            //Smooth in y axis
            for(int x=0; x<n_x; x++)
            {
               for(int y=0; y<s; y++)
               {
                  tr_row_buf[y] = 0;
                  for(int yp=0; yp<y+s; yp++)
                     tr_row_buf[y] += cur_data_ptr[yp*dy+x*dx+idx];
                  tr_row_buf[y] /= y+s;
               }

              
               for(int y=s; y<n_y-s; y++ )
               {
                  tr_row_buf[y] = 0;
                  for(int yp=y-s; yp<=y+s; yp++)
                     tr_row_buf[y] += cur_data_ptr[yp*dy+x*dx+idx];
                  tr_row_buf[y] /= 2*s+1;
               }

               for(int y=n_y-s; y<n_y; y++ )
               {
                  tr_row_buf[y] = 0;
                  for(int yp=y-s; yp<n_y; yp++)
                     tr_row_buf[y] += cur_data_ptr[yp*dy+x*dx+idx];
                  tr_row_buf[y] /= n_y-(y-s);
               }

               for(int y=0; y<n_y; y++)
                  y_smoothed_buf[y*n_x+x] = tr_row_buf[y];
            }

            //Smooth in x axis
            for(int y=0; y<n_y; y++)
            {
               for(int x=0; x<s; x++)
               {
                  tr_row_buf[x] = 0;
                  for(int xp=0; xp<x+s; xp++)
                     tr_row_buf[x] += y_smoothed_buf[y*n_x+xp];
                  tr_row_buf[x] /= x+s;
               }

               for(int x=s; x<n_x-s; x++)
               {
                  tr_row_buf[x] = 0;
                  for(int xp=x-s; xp<=x+s; xp++)
                     tr_row_buf[x] += y_smoothed_buf[y*n_x+xp];
                  tr_row_buf[x] /= 2*s+1;
               }

               //
               for(int x=n_x-s; x<n_x; x++ )
               {
                  tr_row_buf[x] = 0;
                  for(int xp=x-s; xp<n_x; xp++)
                     tr_row_buf[x] += y_smoothed_buf[y*n_x+xp];
                  tr_row_buf[x] /= n_x-(x-s);
               }

               for(int x=0; x<n_x; x++)
                  tr_data[y*dyt+x*dxt+tr_idx] = tr_row_buf[x];

            }

         }
      }
   }
   
   float tvb_sum = 0;
   if (background_type == BG_TV_IMAGE)
      for(int i=0; i<n_meas; i++)
         tvb_sum += tvb_profile[i];

   
   // Calculate intensity
   float* intensity_ptr = intensity;
   cur_data_ptr = (T*) tr_buf;
   for(int p=0; p<n_px; p++)
   {
      *intensity_ptr = 0;
      for(int i=0; i<n_meas_full; i++)
         *intensity_ptr += cur_data_ptr[i];
      cur_data_ptr += n_meas_full;

      if (background_type == BG_VALUE)
         *intensity_ptr -= background_value * n_meas_full;
      else if (background_type == BG_IMAGE)
         *intensity_ptr -= background_image[p] * n_meas_full;
      else if (background_type == BG_TV_IMAGE)
         *intensity_ptr -= (tvb_sum * tvb_I_map[p] + background_value * n_meas_full) ;

      intensity_ptr++;
   }

   // Calculate Steady State Anisotropy
   if (polarisation_resolved)
   {
      float para;
      float perp;

      float* r_ptr = r_ss;
      cur_data_ptr = (T*) tr_data;
      for(int p=0; p<n_px; p++)
      {
         para = 0;
         perp = 0;

         for(int i=0; i<n_t; i++)
            para += cur_data_ptr[i];
         cur_data_ptr += n_t;
         for(int i=0; i<n_t; i++)
            perp += cur_data_ptr[i];
         cur_data_ptr += n_t;

         perp *= (float) g_factor;

         *r_ptr = (para - perp) / (para + 2 * perp);


         r_ptr++;
      }
   }




   // Subtract background
   if (background_type == BG_VALUE)
   {
      int n_tot = n_x * n_y * n_chan * n_t;
      for(int i=0; i<n_tot; i++)
      {
         tr_data[i] -= background_value;
         tr_data[i] *= photons_per_count;
      }
   }
   else if (background_type == BG_IMAGE)
   {
      int idx = 0;
      for(int p=0; p<n_px; p++)
         for(int i=0; i<n_meas; i++)
         {
            tr_data[idx] -= background_image[p];
            tr_data[idx] *= photons_per_count;
            idx++;
         }
   } 
   else if (background_type == BG_TV_IMAGE)
   {
      int idx = 0;
      for(int p=0; p<n_px; p++)
         for(int i=0; i<n_meas; i++)
         {
            tr_data[idx] -= (tvb_profile[i] * tvb_I_map[p] + background_value);
            tr_data[idx] *= photons_per_count;
            idx++;
         }
   }
   else
   {
      int n_tot = n_x * n_y * n_chan * n_t;
      for(int i=0; i<n_tot; i++)
         tr_data[i] *= photons_per_count;
   }
   

   // Set negative values to zero
   int n_tot = n_x * n_y * n_chan * n_t;
   for(int i=0; i<n_tot; i++)
   {
      if (tr_data[i] < 0)
         tr_data[i] = 0;
   }
   
   cur_transformed[thread] = im;
   MarkCompleted(slot);


}



#endif
