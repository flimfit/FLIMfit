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
#include <algorithm>

using namespace std;

FLIMData::FLIMData(const std::vector<std::shared_ptr<FLIMImage>>& images, const DataTransformationSettings& transform) :
transform(transform)
{
   image_t0_shift = NULL;
   n_masked_px = 0;
   
   setData(images);
   
   dp = make_shared<TransformedDataParameters>(images[0]->getAcquisitionParameters(), transform);
}

FLIMData::FLIMData(std::shared_ptr<FLIMImage> image, const DataTransformationSettings& transform) :
transform(transform)
{
   image_t0_shift = NULL;
   n_masked_px = 0;
   
   std::vector<std::shared_ptr<FLIMImage>> images = {image};
   
   setData(images);
   
   dp = make_shared<TransformedDataParameters>(images[0]->getAcquisitionParameters(), transform);
}


void FLIMData::setGlobalScope(GlobalScope global_scope_)
{
   bool changed = global_scope != global_scope_;
   global_scope = global_scope_;

   //if (changed)
   //   updateRegions();


   // TODO(P:Low)
   // So that we can calculate errors properly
   //if (global_scope_ == Pixelwise && n_x == 1 && n_y == 1)
   //   global_scope_ = Imagewise;

}



/*
void FLIMData::SetNumThreads(int n_thread_)
{
   n_thread = n_thread_;

   cur_transformed.resize(n_thread, -1);
   data_used.resize(n_thread, -1);
   data_loaded.resize(n_thread, -1);

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
*/


/**
 * Wrapper function for DataLoaderThread
 */
/*
void StartDataLoaderThread(void* wparams)
{
   DataLoaderThreadParams* params = (DataLoaderThreadParams*) wparams;
   FLIMData* data = params->data;
  
   if (data->data_class == FLIMImage::DataUint16)
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
*/

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

std::shared_ptr<RegionData> FLIMData::getNewRegionData()
{
   return std::make_shared<RegionData>(data_type, getMaxRegionSize(), dp->n_meas);
}


int FLIMData::getNumAuxillary()
{
   int num_aux = 1;  // intensity

   if (has_acceptor)
      num_aux++;

   if (polarisation_resolved)
      num_aux++;     // r_ss

   return num_aux;
}

void FLIMData::setData(const std::vector<std::shared_ptr<FLIMImage>>& images_)
{
   images = images_;

   n_im = static_cast<int>(images.size());
   n_im_used = n_im;
   
   use_im.resize(n_im);
   for (int i = 0; i < n_im; i++)
      use_im[i] = i;

   //updateRegions();  
}

void FLIMData::updateRegions()
{
   // TODO: make this a bit cleaner
   region_count.clear();
   region_pos.clear();
   region_idx.clear();
   output_region_idx.clear();

   region_count.resize(n_im_used, std::vector<int>(MAX_REGION, 0));
   region_pos.resize(n_im_used, std::vector<int>(MAX_REGION, 0));
   region_idx.resize(n_im_used+1, std::vector<int>(MAX_REGION, -1));
   output_region_idx.resize(n_im_used, std::vector<int>(MAX_REGION, -1));
   
   // TODO(P:Low): make sure all data is of the same class
   data_class = images[0]->getDataClass();
   has_acceptor = images[0]->hasAcceptor();
   polarisation_resolved = images[0]->isPolarisationResolved();
   data_type = images[0]->getAcquisitionParameters()->data_type;
   
   int err = 0;
   if (data_class == FLIMImage::DataFloat)
      err = calculateRegions<float>();
   else
      err = calculateRegions<uint16_t>();

   max_px_per_image = 0;
   for(auto& im : images)
      max_px_per_image = max(max_px_per_image, im->getAcquisitionParameters()->n_px);
}

int FLIMData::getMaxFitSize()
{
   if (global_scope == Global)
      return n_masked_px;
   else if (global_scope == Imagewise)
      return max_px_per_image;
   else
      return 1;
}

int FLIMData::getMaxRegionSize()
{
   if (global_scope == Global)
      return n_masked_px;
   else
      return max_px_per_image;
}

/*
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
   if (global_scope == Global && n_regions_total > 1)
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
*/

/*
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

      loader_thread = new std::thread(StartDataLoaderThread,(void*)params); // ok
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
*/

void FLIMData::setImageT0Shift(double* image_t0_shift)
{
   this->image_t0_shift = image_t0_shift;
}


int FLIMData::getRegionIndex(int im, int region)
{
   // If fitting globally, set im=-1 to get index of region for all datasets

   if (global_scope == Global)
         im++;

   return region_idx[im][region];
}

int FLIMData::getOutputRegionIndex(int im, int region)
{
   return output_region_idx[im][region];
}

int FLIMData::getRegionPos(int im, int region)
{
   if (im == -1)
      im = 0;

   return region_pos[im][region];
}

int FLIMData::getRegionCount(int im, int region)
{
   return region_count[im][region];
}

int FLIMData::getImLoc(int im)
{
   for(int i=0; i<n_im_used; i++)
   {
      if (use_im[i] == im)
         return i;
   }
   return -1;
}

int FLIMData::getRegionData(int thread, int group, int region, std::shared_ptr<RegionData> region_data, FitResults& results, int n_thread)
{
   int s = 0;
   int s_expected;
   
   float_iterator masked_data;
   int_iterator irf_idx;
   
   region_data->Clear();

   
   if ( global_scope == Pixelwise || global_scope == Imagewise )
   {
      s_expected = getRegionCount(group, region);
      region_data->GetPointersForInsertion(s_expected, masked_data, irf_idx);

      s = getMaskedData( group, region, masked_data, irf_idx, results);
      
      
      assert( s == s_expected );
   }
   else if ( global_scope == Global )
   {
      
      int start = getRegionPos(0, region);
       
      // we want dynamic with a chunk size of 1 as the data is being pulled from VM in order
      // TODO: #pragma omp parallel for reduction(+:s) schedule(dynamic, 1) num_threads(n_thread)
      for(int i=0; i<n_im_used; i++)
      {
         // add termination here?
            
         int pos = getRegionPos(i, region) - start;
         int s_expected = getRegionCount(i, region);

         region_data->GetPointersForArbitaryInsertion(pos, s_expected, masked_data, irf_idx);

         s += getMaskedData(i, region, masked_data, irf_idx, results);
      };
      
   }

   return s;
}


int FLIMData::getMaskedData(int im, int region, float_iterator masked_data, int_iterator irf_idx, FitResults& results)
{
   int iml = use_im[im];
   auto transformer = getPooledTransformer(iml);
   int s = getRegionCount(im, region);

   float_iterator masked_intensity, masked_r_ss, masked_acceptor;
   float_iterator aux_data = results.getAuxDataPtr(im, region);
   auto& mask = results.getMask(im);
   
   int n_aux = getNumAuxillary();

   masked_intensity = aux_data++;

   if (has_acceptor)
      masked_acceptor = aux_data++;

   if (polarisation_resolved)
      masked_r_ss = aux_data++;

   mask = transformer.getMask();
   auto& tr_data = transformer.getTransformedData();
   auto& r_ss = transformer.getSteadyStateAnisotropy();
   
   cv::Mat acceptor = images[iml]->getAcceptor();
   cv::Mat intensity = images[iml]->getIntensity();
   
   int n_meas = transformer.getNumMeasurements();
   
   // Store masked values
   int idx = 0;

   if (tr_data.empty())
      throw std::runtime_error("Error retrieving transformed data");

   int n_px = static_cast<int>(mask.size());
   for(int p=0; p<n_px; p++)
   {
      if (region < 0 || mask[p] == region || (merge_regions && mask[p] > 0))
      {
         masked_intensity[idx*n_aux] = intensity.at<float>(p);
   
         if (polarisation_resolved)
            masked_r_ss[idx*n_aux] = r_ss[p];

         if (has_acceptor)
            masked_acceptor[idx*n_aux] = acceptor.at<float>(p);
            
         for(int i=0; i<n_meas; i++)
            masked_data[idx*n_meas+i] = tr_data[p*n_meas+i];


         irf_idx[idx] = p;
         idx++;
      }
   }

   releasePooledTranformer(iml);

   assert(s == idx);
   return s;
}


std::vector<std::string> FLIMData::getAuxParamNames()
{   
   std::vector<std::string> param_names;
   param_names.push_back("I");

   if ( has_acceptor )
      param_names.push_back("acceptor");

   if ( polarisation_resolved )
      param_names.push_back("r_ss");

   return param_names;
}


DataTransformer& FLIMData::getPooledTransformer(int im)
{
   std::lock_guard<std::mutex> lk(pool_mutex);
   
   int n_pool = static_cast<int>(transformer_pool.size());
   for (int i=0; i<n_pool; i++)
   {
      if (transformer_pool[i].im == im)
      {
         transformer_pool[i].refs++;
         return transformer_pool[i].transformer;
      }
   }
   
   // No pooled transformers for the current image... see if there are any we can replace
   for (int i=0; i<n_pool; i++)
   {
      if (transformer_pool[i].refs == 0)
      {
         transformer_pool[i].refs++;
         transformer_pool[i].im = im;
         transformer_pool[i].transformer.setImage(images[im]);
         return transformer_pool[i].transformer;
      }
   }
   
   transformer_pool.push_back(PoolTransformer(transform));
   transformer_pool[n_pool].refs++;
   transformer_pool[n_pool].im = im;
   transformer_pool[n_pool].transformer.setImage(images[im]);
   return transformer_pool[n_pool].transformer;
}

void FLIMData::releasePooledTranformer(int im)
{
   std::lock_guard<std::mutex> lk(pool_mutex);
   
   int n_pool = static_cast<int>(transformer_pool.size());
   for (int i=0; i<n_pool; i++)
   {
      if (transformer_pool[i].im == im)
      {
         transformer_pool[i].refs--;
         assert(transformer_pool[i].refs >= 0);
         return;
      }
   }
   
   assert(false); // shouldn't reach here - why are you releasing?
}




