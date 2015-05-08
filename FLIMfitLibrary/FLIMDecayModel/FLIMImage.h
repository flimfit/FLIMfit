#pragma once

#include "AcquisitionParameters.h"
#include <cstdint>
#include <typeindex> 
#include <string>
#include <cv.h>
#include <string>
#include <fstream>
#include <boost/interprocess/file_mapping.hpp>

#include <boost/interprocess/mapped_region.hpp>
#include <boost/filesystem.hpp>

class FLIMImage
{
public:

   enum DataClass { DataUint16, DataFloat };
   enum DataMode { InMemory, MappedFile };

   template<typename T>
   FLIMImage(shared_ptr<AcquisitionParameters> acq, DataMode data_mode, T* data_, uint8_t* mask_ = nullptr);
   FLIMImage(shared_ptr<AcquisitionParameters> acq, std::type_index type, DataMode data_mode = MappedFile);
   ~FLIMImage();
   
   void init();

   template<typename T> T* getDataPointer();
   template<typename T> void releasePointer();
   template<typename T> void releaseModifiedPointer();
   template<typename T> void compute();
   
   void getDecay(cv::Mat mask, std::vector<std::vector<double>>& decay);

   const std::string& getName() { return name; }
   void setName(const std::string& name_) { name = name_; }
   DataClass getDataClass() { return data_class; }
   cv::Mat getIntensity() { return intensity; }
   const std::vector<uint8_t>& getSegmentationMask() { return mask; }
   std::shared_ptr<AcquisitionParameters> getAcquisitionParameters() { return acq; }
   
protected:

   template<typename T>
   void getDecayImpl(cv::Mat mask, std::vector<std::vector<double>>& decay);
   
   shared_ptr<AcquisitionParameters> acq;
   DataClass data_class;
   vector<uint8_t> data;
   vector<uint8_t> acceptor;
   vector<uint8_t> mask;
   std::type_index stored_type;
   std::string name;
   cv::Mat intensity;
   
   std::string map_file_name;
   boost::interprocess::file_mapping data_map_file;
   boost::interprocess::mapped_region data_map_view;
   size_t map_offset = 0;
   size_t map_length = 0;
   DataMode data_mode = InMemory;
   int open_pointers = 0;

};


template<typename T>
FLIMImage::FLIMImage(shared_ptr<AcquisitionParameters> acq, DataMode data_mode, T* data_, uint8_t* mask_) :
acq(acq)
{
   init();
   
   T* data_ptr = getDataPointer<T>();
   memcpy(data_ptr, data_, map_length);
   releaseModifiedPointer<T>();
   
   if (mask_ != nullptr)
   {
      mask.resize(acq->n_px);
      memcpy(mask.data(), mask_, acq->n_px * sizeof(uint8_t));
   }
   
   compute<T>();
}

// TODO: need some mutexes here
template <typename T>
T* FLIMImage::getDataPointer()
{
   using namespace boost::interprocess;

   if (stored_type != typeid(T))
   {
      throw std::runtime_error("Attempting to retrieve incorrect data type");
      return reinterpret_cast<T*>(data.data());
   }

   open_pointers++;
   
   switch (data_mode)
   {
      case MappedFile:
         
         // only create mapped region if we're the first
         if (open_pointers == 1)
            data_map_view = mapped_region(data_map_file, read_only, map_offset, map_length);
         
         return reinterpret_cast<T*>(data_map_view.get_address());
       
      case InMemory:
         return reinterpret_cast<T*>(data);
   }
 
   return nullptr;
}

template<typename T>
void FLIMImage::releasePointer()
{
   open_pointers--;
   assert(open_pointers >= 0);
   
   // Clear mapped region
   if (open_pointers == 0 && data_mode == MappedFile)
      data_map_view = boost::interprocess::mapped_region();
}

template<typename T>
void FLIMImage::releaseModifiedPointer()
{
   compute<T>();
   
   if (data_mode == MappedFile)
      data_map_view.flush(map_offset, map_length);
   
   releasePointer<T>();
}

template<typename T>
void FLIMImage::compute()
{
   int n_px = acq->n_px;
   int n_meas = acq->n_meas_full;
   intensity = cv::Mat(acq->n_x, acq->n_y, CV_32F);
   
   T* data = getDataPointer<T>();
   
   for (int i=0; i<n_px; i++)
      for (int j=0; j<n_meas; j++)
         intensity.at<float>(i) += data[i*n_meas + j];
   
}


template<typename T>
void FLIMImage::getDecayImpl(cv::Mat mask, std::vector<std::vector<double>>& decay)
{
   assert(mask.size() == intensity.size());
   
   decay.resize(acq->n_chan);
   for(auto& d : decay)
      d.assign(acq->n_t_full, 0);
   
   T* data = getDataPointer<T>();
   
   for(int i=0; i<acq->n_px; i++)
   {
      if (mask.at<uint8_t>(i) > 0)
      {
         for(int j=0; j<acq->n_chan; j++)
            for (int k=0; k<acq->n_t_full; k++)
               decay[j][k] += data[i*acq->n_meas_full + j*(acq->n_t_full) + k];
         
      }
   }
}

