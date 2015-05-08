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

#include "FLIMData.h"
#include "FlagDefinitions.h"
#include <cmath>

FLIMData::FLIMData()
{
   has_data = false;
   has_acceptor = false;

   data_file = NULL;
   acceptor_ = NULL;
   loader_thread = NULL;


   image_t0_shift = NULL;


   stream_data = STREAM_DATA;


   background_value = 0;
   background_type = BG_NONE;


   n_masked_px = 0;

   background_value = 0;
   background_type = BG_NONE;

   SetNumThreads(1);
}

void FLIMData::SetAcquisitionParmeters(const AcquisitionParameters& acq)
{
   *static_cast<AcquisitionParameters*>(this) = acq;
   ResizeBuffers();
}

void FLIMData::SetNumImages(int n_im_)
{
   n_im = n_im_;

   n_im_used = n_im;

   use_im.resize(n_im);
   for (int i = 0; i < n_im; i++)
      use_im[i] = i;

   n_px = n_x * n_y;

   mask.resize(n_im, vector<uint8_t>(n_px, 1)); // include everything in mask by default
   use_im.resize(n_im);

   region_count.resize(n_im_used * MAX_REGION, 0);
   region_pos.resize(n_im_used * MAX_REGION, 0);
   region_idx.resize((n_im_used + 1) * MAX_REGION, -1);
   output_region_idx.resize(n_im_used * MAX_REGION, -1);

}

void FLIMData::SetMasking(int* use_im_, uint8_t mask_[], int merge_regions)
{
   if (use_im_ != NULL)
   {
      n_im_used = 0;
      for (int i = 0; i<n_im; i++)
      {
         std::copy(mask_ + i*n_x*n_y, mask_ + (i + 1)*n_x*n_y, mask[i].begin());
         if (use_im_[i])
            for (int j = 0; j<n_x*n_y; j++)
               if (mask_[i*n_x*n_y + j] > 0)
               {
                  use_im[n_im_used] = i;
                  n_im_used++;
                  break;
               }
      }
   }
   else
   {
      n_im_used = n_im;
   }
}

void FLIMData::SetThresholds(int threshold_, int limit_)
{
   // Make sure we exclude very dim pixels which 
   // can break the autosampling (we might end up with only one bin!)
   threshold = std::max(threshold_, 3);
   limit = limit_;
}

void FLIMData::SetGlobalMode(int global_mode_)
{
   // So that we can calculate errors properly
   if (global_mode_ == MODE_PIXELWISE && n_x == 1 && n_y == 1)
      global_mode_ = MODE_IMAGEWISE;

   global_mode = global_mode_;
}

void FLIMData::SetSmoothing(int smoothing_factor_)
{
   int dim_required = smoothing_factor_ * 2 + 2;
   if (n_x >= dim_required && n_y > dim_required)
   {
      smoothing_factor = smoothing_factor_;
      smoothing_area = (float)(2 * smoothing_factor + 1)*(2 * smoothing_factor + 1);
   }
}



void FLIMData::SetStatus(shared_ptr<FitStatus> status_)
{
   status = status_;

   // Make sure waiting threads are notified when we terminate
   status->AddConditionVariable(&data_avail_cond);
   status->AddConditionVariable(&data_used_cond);
}




void FLIMData::SetNumThreads(int n_thread_)
{
   n_thread = n_thread_;

   cur_transformed.resize(n_thread, -1);
   data_used.resize(n_thread, -1);
   data_loaded.resize(n_thread, -1);

   data_map_view = new boost::interprocess::mapped_region[n_thread]; //ok

   ResizeBuffers();
}

void FLIMData::ResizeBuffers()
{
   int n_p = n_x * n_y * n_meas_full;

   if (n_p > 0)
   {
      tr_data_.resize(n_thread, std::vector<float>(n_p));
      tr_buf_.resize(n_thread, std::vector<float>(n_p));
      intensity_.resize(n_thread, std::vector<float>(n_px));
      tr_row_buf_.resize(n_thread, std::vector<float>(n_x + n_y));

      if (polarisation_resolved)
         r_ss_.resize(n_thread, std::vector<float>(n_px));
      else
         r_ss_.resize(n_thread); // no data
   }
}



/**
 * Wrapper function for DataLoaderThread
 */
void StartDataLoaderThread(void* wparams)
{
   DataLoaderThreadParams* params = (DataLoaderThreadParams*) wparams;
   FLIMData* data = params->data;
  
   if (data->data_class == DATA_UINT16)
      data->DataLoaderThread<uint16_t>(params->only_load_non_empty_images);
   else
      data->DataLoaderThread<float>(params->only_load_non_empty_images);

   delete params;
}

void FLIMData::MarkCompleted(int slot)
{
   data_mutex.lock();
   data_loaded[slot] = -1;
   data_used[slot] = 1;
   data_mutex.unlock();

   data_used_cond.notify_all();
}

/*
{

//===================================================================================//

   #define FILE            "c:\\users\\scw09\\Documents\\h5ex_d_hyper.h5"
   #define DATASET         "DS1"
   #define DIM0            6
   #define DIM1            8

    int rdata[DIM0][DIM1];

    hid_t  file = H5Fopen (FILE, H5F_ACC_RDONLY, H5P_DEFAULT);
    hid_t  dset = H5Dopen (file, DATASET, H5P_DEFAULT);

    herr_t status = H5Dread (dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, rdata[0]);

    hsize_t     dims[2] = {DIM0, DIM1},
                start[2],
                stride[2],
                count[2],
                block[2];


    // Define and select the hyperslab to use for reading.

    hid_t space = H5Dget_space (dset);
    start[0]  = 0;
    start[1]  = 1;
    stride[0] = 4;
    stride[1] = 4;
    count[0]  = 2;
    count[1]  = 2;
    block[0]  = 2;
    block[1]  = 3;
    status = H5Sselect_hyperslab (space, H5S_SELECT_SET, start, stride, count, block);

    // Read the data using the previously defined hyperslab.
     
    status = H5Dread (dset, H5T_NATIVE_INT, H5S_ALL, space, H5P_DEFAULT,
                rdata[0]);

    //===================================================================================//


}
*/

int FLIMData::GetNumAuxillary()
{
   int num_aux = 1;  // intensity

   if (has_acceptor)
      num_aux++;

   if (polarisation_resolved)
      num_aux++;     // r_ss

   return num_aux;
}

int FLIMData::SetAcceptor(float acceptor[])
{
   this->acceptor_ = acceptor;
   has_acceptor = true;

   return SUCCESS;
}

void FLIMData::SetData(const vector<shared_ptr<FLIMImage>>& images_)
{
   SetNumImages(images_.size());
   images = images_;

   has_data = true;
   data_mode = DataFLIMImages;
   
   // TODO: harmonise these
   if (images_[0]->getDataClass() == FLIMImage::DataFloat)
      data_class = DATA_FLOAT;
   else
      data_class = DATA_UINT16;

   int err = 0;
   if (data_class == DATA_FLOAT)
      err = CalculateRegions<float>();
   else
      err = CalculateRegions<uint16_t>();

}

int FLIMData::SetData(const char* data_file, int data_class, int data_skip)
{

   this->data_skip = data_skip;
   this->data_class = data_class;

   has_data = false;

   data_mode = DataMappedFile;
   
   this->data_file = new char[ strlen(data_file) + 1 ]; //ok
   strcpy(this->data_file,data_file);

   data_map_file = boost::interprocess::file_mapping(data_file,boost::interprocess::read_only);

   has_data = true;

   int err = 0;
   if (data_class == DATA_FLOAT)
      err = CalculateRegions<float>();
   else
      err = CalculateRegions<uint16_t>();

   // We can't stream data globally with more than one region
   if (global_mode == MODE_GLOBAL && n_regions_total > 1)
      stream_data = false;

   return err;

}

int FLIMData::SetData(float* data)
{
   this->data = (void*) data;
   data_mode = DataInMemory;
   data_class = DATA_FLOAT;
   
   int err = CalculateRegions<float>();
   
   has_data = true;
   
   return err;
}

int FLIMData::SetData(uint16_t* data)
{
   this->data = (void*) data;
   data_mode = DataInMemory;
   data_class = DATA_UINT16;

   int err = CalculateRegions<uint16_t>();
   
   has_data = true;

   return err;
}

double FLIMData::GetPhotonsPerCount()
{
   return smoothing_area / counts_per_photon;
}

void FLIMData::ImageDataFinished(int im)
{
   if (stream_data)
   {
      for(int i=0; i<n_thread; i++)
      {
         if (data_loaded[i] >= 0 && data_loaded[i] == im)
            MarkCompleted(i);
      }
   }
}

void FLIMData::AllImageLowerDataFinished(int im)
{
   if (stream_data)
   {
      for(int i=0; i<n_thread; i++)
      {
         if (data_loaded[i] >= 0 && data_loaded[i] <= im)
            MarkCompleted(i);
      }
   }
}

void FLIMData::StartStreaming(bool only_load_non_empty_images)
{
   if (stream_data && loader_thread == NULL)
   {
      DataLoaderThreadParams* params = new DataLoaderThreadParams;
      params->data = this;
      params->only_load_non_empty_images = only_load_non_empty_images;

      loader_thread = new tthread::thread(StartDataLoaderThread,(void*)params); // ok
   }
}

void FLIMData::StopStreaming()
{
   if (stream_data && loader_thread != NULL)
   {
      // Wait for loader thread to terminate
      if (loader_thread->joinable())
         loader_thread->join();
      delete loader_thread;
      loader_thread = NULL;
   }
}

void FLIMData::SetBackground(float* background_image)
{
   this->background_image = background_image;
   this->background_type = BG_IMAGE;
}

void FLIMData::SetBackground(float background)
{
   this->background_value = background;
   this->background_type = BG_VALUE;
}

void FLIMData::SetTVBackground(float* tvb_profile, float* tvb_I_map, float const_background)
{
   this->tvb_profile = tvb_profile;
   this->tvb_I_map = tvb_I_map;
   this->background_value = const_background;
   this->background_type = BG_TV_IMAGE;
}

void FLIMData::SetImageT0Shift(double* image_t0_shift)
{
   this->image_t0_shift = image_t0_shift;
}


int FLIMData::GetRegionIndex(int im, int region)
{
   // If fitting globally, set im=-1 to get index of region for all datasets

   if (global_mode == MODE_GLOBAL)
         im++;

   return region_idx[region + im * MAX_REGION];
}

int FLIMData::GetOutputRegionIndex(int im, int region)
{
   return output_region_idx[region + im * MAX_REGION];
}

int FLIMData::GetRegionPos(int im, int region)
{
   if (im == -1)
      im = 0;

   return region_pos[region + im * MAX_REGION];
}

int FLIMData::GetRegionCount(int im, int region)
{
   return region_count[region + im * MAX_REGION];
}

int FLIMData::GetImLoc(int im)
{
   for(int i=0; i<n_im_used; i++)
   {
      if (use_im[i] == im)
         return i;
   }
   return -1;
}

int FLIMData::GetRegionData(int thread, int group, int region, RegionData& region_data, FitResults& results, int n_thread)
{
   int s = 0;
   int s_expected;
   
   float* masked_data;
   int* irf_idx;
   
   region_data.Clear();

   
   if ( global_mode == MODE_PIXELWISE || global_mode == MODE_IMAGEWISE )
   {
      s_expected = this->GetRegionCount(group, region);
      region_data.GetPointersForInsertion(s_expected, masked_data, irf_idx);

      s = GetMaskedData(thread, group, region, masked_data, irf_idx, results);

      assert( s == s_expected );
   }
   else if ( global_mode == MODE_GLOBAL )
   {
      
      int start = GetRegionPos(0, region);
       
      // we want dynamic with a chunk size of 1 as the data is being pulled from VM in order
      #pragma omp parallel for reduction(+:s) schedule(dynamic, 1) num_threads(n_thread)
      for(int i=0; i<n_im_used; i++)
      {
         if (status == nullptr || !status->terminate)
         {
            // This thread index will only be used if we're not streaming data,
            // make sure that we pass the right one in
            int r_thread;
            if (n_thread == 1)
               r_thread = thread;
            else
               r_thread = omp_get_thread_num();

            int pos = GetRegionPos(i, region) - start;
            
            int s_expected = this->GetRegionCount(i, region);

            region_data.GetPointersForArbitaryInsertion(pos, s_expected, masked_data, irf_idx);
            s += GetMaskedData(r_thread, i, region, masked_data, irf_idx, results);
            ImageDataFinished(i);
         }
      }
   }

   return s;
}


int FLIMData::GetMaskedData(int thread, int im, int region, float* masked_data, int* irf_idx, FitResults& results)
{
   int iml = use_im[im];

   int s = GetRegionCount(im, region);

   float *masked_intensity, *masked_r_ss, *masked_acceptor;
   float *aux_data = results.GetAuxDataPtr(im, region);

   int n_aux = GetNumAuxillary();

   masked_intensity = aux_data++;

   if (has_acceptor)
      masked_acceptor = aux_data++;

   if (polarisation_resolved)
      masked_r_ss = aux_data++;

   auto& im_mask = mask[iml];
   float* acceptor = acceptor_ + iml*n_x*n_y;

   vector<float>& tr_data = tr_data_[thread];
   vector<float>& intensity = intensity_[thread];
   vector<float>& r_ss = r_ss_[thread];

   if (data_class == DATA_FLOAT)
      TransformImage<float>(thread, im);
   else
      TransformImage<uint16_t>(thread, im);

   // Store masked values
   int idx = 0;

   for(int p=0; p<n_px; p++)
   {
      if (region < 0 || im_mask[p] == region || (merge_regions && im_mask[p] > 0))
      {
         masked_intensity[idx*n_aux] = intensity[p];
   
         if (polarisation_resolved)
            masked_r_ss[idx*n_aux] = r_ss[p];

         if (has_acceptor)
            masked_acceptor[idx*n_aux] = acceptor[p];
            
         for(int i=0; i<n_meas; i++)
            masked_data[idx*n_meas+i] = tr_data[p*n_meas+i];


         irf_idx[idx] = iml*n_px+p;
         idx++;
      }
   }

   assert(s == idx);

   return s;
}



void FLIMData::ClearMapping()
{
   if (data_map_view == NULL)
      return;
   for(int i=0; i<n_thread; i++)
      data_map_view[i] = boost::interprocess::mapped_region();
}


void FLIMData::GetAuxParamNames(vector<string>& param_names)
{   
   param_names.push_back("I");

   if ( has_acceptor )
      param_names.push_back("acceptor");

   if ( polarisation_resolved )
      param_names.push_back("r_ss");

}


FLIMData::~FLIMData()
{
   ClearMapping();

   delete[] data_map_view;
    
   if (data_file != NULL)
      delete[] data_file;

   if (loader_thread != NULL)
      delete loader_thread;
}



