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
#include <cmath>
//#include "hdf5.h"

FLIMData::FLIMData(AcquisitionParameters& acq, int n_im, int n_x, int n_y, 
                   int* use_im, uint8_t mask[], int threshold, int limit, int global_mode, int smoothing_factor, int use_autosampling, int n_thread, FitStatus* status) :
   AcquisitionParameters(acq),   
   n_im(n_im), 
   n_x(n_x),
   n_y(n_y),
   use_im(use_im),
   mask(mask),
   threshold(threshold),
   limit(limit),
   smoothing_factor(smoothing_factor),
   use_autosampling(use_autosampling),
   n_thread(n_thread),
   status(status)
{
   has_data = false;
   has_acceptor = false;

   data_file = NULL;
   acceptor_  = NULL;
   loader_thread = NULL;


   // Make sure waiting threads are notified when we terminate
   status->AddConditionVariable(&data_avail_cond);
   status->AddConditionVariable(&data_used_cond);


   // So that we can calculate errors properly
   if (global_mode == MODE_PIXELWISE && n_x == 1 && n_y == 1)
      global_mode = MODE_IMAGEWISE;

   this->global_mode = global_mode;

   stream_data = STREAM_DATA;

   n_masked_px = 0;

   // Make sure we exclude very dim pixels which 
   // can break the autosampling (we might end up with only one bin!)
   if (threshold < 3)
      threshold = 3;

   supplied_mask = (mask != NULL);

   if (!supplied_mask)
   {
      int sz_mask = n_im * n_x * n_y;
      this->mask = new uint8_t[sz_mask]; //ok
      supplied_mask = false;
      for(int i=0; i<sz_mask; i++)
         this->mask[i] = 1;
   }


   n_im_used = 0;
   if (use_im != NULL)
   {
      for(int i=0; i<n_im; i++)
      {
         if (use_im[i])
            for(int j=0; j<n_x*n_y; j++)
               if(this->mask[i*n_x*n_y+j] > 0)
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

   n_meas = n_chan * n_t;
   n_meas_full = n_chan * n_t_full;

   background_value = 0;
   background_type = BG_NONE;

   if (n_thread < 1)
      n_thread = 1;

   n_px = n_x * n_y;
   n_p  = n_x * n_y * n_meas_full;



   tr_data_    = new float[ n_thread * n_p ]; //ok
   tr_buf_     = new float[ n_thread * n_p ]; //ok
   intensity_  = new float[ n_thread * n_px ];

   if (polarisation_resolved)
      r_ss_ = new float[ n_thread * n_px ];

   tr_row_buf_ = new float[ n_thread * (n_x+n_y) ]; //ok

   region_count = new int[ n_im_used * MAX_REGION ];
   region_pos   = new int[ n_im_used * MAX_REGION ];
   region_idx   = new int[ (n_im_used+1) * MAX_REGION ];
   output_region_idx   = new int[ n_im_used * MAX_REGION ];

   for (int i=0; i<n_im_used * MAX_REGION; i++)
   {
      region_count[i] = 0;
      region_pos[i] = 0;
      region_idx[i] = -1;
      output_region_idx[i] = -1;
   }
   for (int i=0; i<MAX_REGION; i++)
      region_idx[n_im_used * MAX_REGION + i] = -1;
   
   data_map_view = new boost::interprocess::mapped_region[n_thread]; //ok

   cur_transformed = new int[n_thread]; //ok 

   data_used = new int[n_thread];
   data_loaded = new int[n_thread];

   for (int i=0; i<n_thread; i++)
   {
      cur_transformed[i] = -1;
      data_used[i] = 1;
      data_loaded[i] = -1;
   }

   int dim_required = smoothing_factor*2 + 2;
   if (n_x < dim_required || n_y < dim_required)
      this->smoothing_factor = 0;

   smoothing_area = (float) (2*this->smoothing_factor+1)*(2*this->smoothing_factor+1);


}


/**
 * Wrapper function for DataLoaderThread
 */
void StartDataLoaderThread(void* wparams)
{
   FLIMData* data = (FLIMData*) wparams;
  
   if (data->data_class == DATA_UINT16)
      data->DataLoaderThread<uint16_t>();
   else
      data->DataLoaderThread<float>();

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

int FLIMData::SetData(char* data_file, int data_class, int data_skip)
{

   this->data_skip = data_skip;
   this->data_class = data_class;

   has_data = false;

   data_mode = DATA_MAPPED;
   
   this->data_file = new char[ strlen(data_file) + 1 ]; //ok
   strcpy(this->data_file,data_file);

   try
   {
      data_map_file = boost::interprocess::file_mapping(data_file,boost::interprocess::read_only);
   }
   catch(std::exception& e)
   {
      e = e;
      return ERR_COULD_NOT_OPEN_MAPPED_FILE;
   }

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
   data_mode = DATA_DIRECT;
   data_class = DATA_FLOAT;
   
   int err = CalculateRegions<float>();
   
   has_data = true;
   
   return err;
}

int FLIMData::SetData(uint16_t* data)
{
   this->data = (void*) data;
   data_mode = DATA_DIRECT;
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

void FLIMData::StartStreaming()
{
   if (stream_data && loader_thread == NULL)
      loader_thread = new tthread::thread(StartDataLoaderThread,(void*)this); // ok
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
   
   float* masked_data;
   int* irf_idx;
   
   region_data.Clear();

   
   if ( global_mode == MODE_IMAGEWISE )
   {
      region_data.GetPointersForInsertion(s, masked_data, irf_idx);

      s = GetMaskedData(thread, group, region, masked_data, irf_idx, results);
   }
   else if ( global_mode == MODE_GLOBAL )
   {
      s = 0;
      int start = GetRegionPos(0, region);
       
     // we want dynamic with a chunk size of 1 as the data is being pulled from VM in order
      #pragma omp parallel for reduction(+:s) schedule(dynamic, 1) num_threads(n_thread)
      for(int i=0; i<n_im_used; i++)
      {
         if (!status->terminate)
         {
            // This thread index will only be used if we're not streaming data,
            // make sure that we pass the right one in
            int r_thread;
            if (n_thread == 1)
               r_thread = thread;
            else
               r_thread = omp_get_thread_num();

            int pos = GetRegionPos(i, region) - start;
            
            region_data.GetPointersForArbitaryInsertion(pos, s, masked_data, irf_idx);
            s += GetMaskedData(r_thread, i, region, masked_data, irf_idx, results);
            ImageDataFinished(i);
         }
      }
   }

   return s;
}


int FLIMData::GetMaskedData(int thread, int im, int region, float* masked_data, int* irf_idx, FitResults& results)
{
   int iml = im;
   if (use_im != NULL)
      iml = use_im[im];

   int s = GetRegionCount(im, region);

   float *masked_intensity, *masked_r_ss, *masked_acceptor;
   float *aux_data = results.GetAuxDataPtr(im, region);

   int n_aux = GetNumAuxillary();

   masked_intensity = aux_data++;

   if (has_acceptor)
      masked_acceptor = aux_data++;

   if (polarisation_resolved)
      masked_r_ss = aux_data++;

   uint8_t* im_mask = mask + iml*n_x*n_y;
   float*   tr_data   = tr_data_ + thread * n_p;
   float*   intensity = intensity_ + thread * n_px;
   float*   r_ss      = r_ss_ + thread * n_px;
   float*   acceptor  = acceptor_ + iml*n_x*n_y;

   if (data_class == DATA_FLOAT)
      TransformImage<float>(thread, im);
   else
      TransformImage<uint16_t>(thread, im);

   for(int i=0; i<n_meas; i++)
      masked_data[i] = 0;

   // Store masked values
   int idx = 0;

   for(int p=0; p<n_px; p++)
   {
      if (region < 0 || im_mask[p] == region)
      {
         masked_intensity[idx*n_aux] = intensity[p];
   
         if (polarisation_resolved)
            masked_r_ss[idx*n_aux] = r_ss[p];

         if (has_acceptor)
            masked_acceptor[idx*n_aux] = acceptor[p];
            
         for(int i=0; i<n_meas; i++)
            masked_data[idx*n_meas+i] = tr_data[p*n_meas+i];


         irf_idx[idx] = p;
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

   delete[] tr_data_;
   delete[] tr_buf_;
   delete[] tr_row_buf_;
   delete[] intensity_;

   delete[] cur_transformed;
   delete[] data_map_view;
 
   delete[] data_used;
   delete[] data_loaded;

   delete[] region_count;
   delete[] region_pos;
   delete[] region_idx;
   delete[] output_region_idx;
   if (!supplied_mask) 
      delete[] mask;
   
   if (polarisation_resolved)
      delete[] r_ss_;
  
   if (data_file != NULL)
      delete[] data_file;

   if (loader_thread != NULL)
      delete loader_thread;
}



