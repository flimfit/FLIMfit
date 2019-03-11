#pragma once

#include "cvmat_serialization.h"

#include "AcquisitionParameters.h"
#include <cstdint>
#include <typeindex> 
#include <string>
#include <cv.h>
#include <string>
#include <fstream>
#include <future>
#include <functional>
#include <mutex>
#include <condition_variable>
#include <memory>

#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>

typedef uint16_t mask_type;

class FLIMImage
{
public:

   enum DataClass { DataUint16, DataUint32, DataFloat };
   enum DataMode { InMemory, MappedFile };

   template<typename T>
   FLIMImage(std::shared_ptr<AcquisitionParameters> acq, DataMode data_mode, T* data_, mask_type* mask_ = nullptr);
   FLIMImage(std::shared_ptr<AcquisitionParameters> acq, DataMode data_mode, DataClass data_class, void* data_ = nullptr);
   FLIMImage(std::shared_ptr<AcquisitionParameters> acq, const std::string& map_file_name, DataClass data_class, size_t map_offset);

   // for loading ffdata
   FLIMImage(std::shared_ptr<AcquisitionParameters> acq, std::type_index type, const std::string& name, DataMode data_mode = MappedFile, const std::string& root = "");

   ~FLIMImage();
   
   void init();

   void setSegmentationMask(cv::Mat mask_)
   {
      if ((mask_.cols != acq->n_x) || (mask_.rows != acq->n_y))
         throw std::runtime_error("Mask was unexpected size");

      mask = mask_;
   }

   // Caller must ensure that size of mask_ is greater or equal to n_px
   void setSegmentationMask(const mask_type* mask_, int numel)
   {
      if (numel != acq->n_px)
         throw(std::runtime_error("Mask was unexpected size"));

      mask = cv::Mat(acq->n_y, acq->n_x, CV_16U);
      std::copy_n(mask_, acq->n_px, (uint16_t*) mask.data);
   }


   void setAcceptor(cv::Mat acceptor)
   {
      // TODO
   }

   template<typename T> T* getDataPointerForRead();
   template<typename T> T* getDataPointer();
   template<typename T> void releasePointer();
   template<typename T> void releaseModifiedPointer();
   template<typename T> void compute();
   
   void getDecay(cv::Mat mask, std::vector<std::vector<double>>& decay);
   cv::Mat getIntensity();
   std::shared_ptr<FLIMImage> getRegionAsImage(cv::Mat mask);
   
   
   const std::string& getName() { return name; }
   void setName(const std::string& name_) { name = name_; }
   DataClass getDataClass() { return data_class; }
   cv::Mat getAcceptor() { return acceptor; }
   cv::Mat getRatio();
   cv::Mat getSegmentationMask() { return mask; }
   std::shared_ptr<AcquisitionParameters> getAcquisitionParameters() const { return acq; }
   
//   bool isPolarisationResolved() { return acq->polarisation_resolved; }
   bool hasAcceptor() { return has_acceptor; }
   
   size_t getImageSizeInBytes() { return map_length; }
   
   void setRoot(const std::string& root_) { root = root_; } // TODO -> move mapped file
   
   bool hasData() { return has_data; }
   void setReadFuture(std::shared_future<void> reader_future_) { reader_future = reader_future_; }
   
protected:
   
   template<typename T>
   void setData(T* data);

   template<typename T>
   void getDecayImpl(cv::Mat mask, std::vector<std::vector<double>>& decay);
   
   template<typename T>
   std::shared_ptr<FLIMImage> getRegionAsImageImpl(cv::Mat mask);
   
   void ensureAllocated();
   
   void waitForData();
   
   bool writable = false;
   bool has_acceptor = false;
   bool has_data = false;
   std::shared_future<void> reader_future;
   
   
   std::shared_ptr<AcquisitionParameters> acq;
   DataClass data_class;
   std::vector<uint8_t> data;
   std::type_index stored_type;
   std::string name;
   cv::Mat mask;
   cv::Mat intensity;
   cv::Mat acceptor;
   cv::Mat ratio;
   
   std::string map_file_name;
   boost::interprocess::file_mapping data_map_file;
   boost::interprocess::mapped_region data_map_view;
   size_t map_offset = 0;
   size_t map_length = 0;
   DataMode data_mode = MappedFile;
   int open_pointers = 0;
   std::string root;
   
private:
   
   std::future<void> clearing_future;
   std::mutex data_mutex;
   std::condition_variable data_cv;
   
   FLIMImage() :
   stored_type(typeid(void))
   {};
   
   bool allocated = false;
   
   template<class Archive>
   void save(Archive & ar, const unsigned int version) const
   {
      ar & acq;
      ar & data_class;
      ar & data;
      ar & mask;
      ar & name;
      ar & intensity;
      ar & acceptor;
      ar & map_file_name;
      ar & map_offset;
      ar & map_length;
      ar & data_mode;
      ar & has_data;
   }
   
   template<class Archive>
   void load(Archive & ar, const unsigned int version)
   {
      ar & acq;
      ar & data_class;
      ar & data;
      ar & mask;
      ar & name;
      ar & intensity;
      ar & acceptor;
      ar & map_file_name;
      ar & map_offset;
      ar & map_length;
      ar & data_mode;
      ar & has_data;
      
      init();
   }
   
   friend class boost::serialization::access;
   BOOST_SERIALIZATION_SPLIT_MEMBER()
};



template<typename T>
FLIMImage::FLIMImage(std::shared_ptr<AcquisitionParameters> acq, DataMode data_mode, T* data_, mask_type* mask_) :
acq(acq),
stored_type(typeid(T)),
data_mode(data_mode)
{
   init();

   if (mask_ != nullptr)
   {
      mask.resize(acq->n_px);
      memcpy(mask.data(), mask_, acq->n_px * sizeof(mask_type));
   }
   
   setData(data_);
}

template<typename T>
void FLIMImage::setData(T* data_)
{
   T* data_ptr = getDataPointer<T>();
   memcpy(data_ptr, data_, map_length);
   releaseModifiedPointer<T>();
}

template <typename T>
T* FLIMImage::getDataPointerForRead()
{
   waitForData();

   std::unique_lock<std::mutex> lk(data_mutex);
   while (!has_data)
      data_cv.wait(lk);
   
   return getDataPointer<T>();
}

template <typename T>
T* FLIMImage::getDataPointer()
{
   ensureAllocated();
   
   if (clearing_future.valid())
      clearing_future.wait();
   
   if (stored_type != typeid(T))
      throw std::runtime_error("Attempting to retrieve incorrect data type");

   open_pointers++;
   
   // is mapped file writeable?
   boost::interprocess::mode_t mode = (writable) ? boost::interprocess::mode_t::read_write : boost::interprocess::mode_t::read_only;

   switch (data_mode)
   {
      case MappedFile:
         
         // only create mapped region if we're the first
         if (open_pointers == 1)
            data_map_view = boost::interprocess::mapped_region(data_map_file, mode, map_offset, map_length);
         
         return reinterpret_cast<T*>(data_map_view.get_address());
       
      case InMemory:
         return reinterpret_cast<T*>(data.data());
   }
 
   return nullptr;
}

template<typename T>
void FLIMImage::releasePointer()
{
   if (clearing_future.valid())
      clearing_future.wait();
   
   open_pointers--;
   assert(open_pointers >= 0);
   
   // Clear mapped region
   if (open_pointers == 0 && data_mode == MappedFile)
   {
      //// Launch in seperate thread as this may take a while to flush to disk
      //clearing_future = std::async(std::launch::async, [this](){
      data_map_view.flush();
      data_map_view = boost::interprocess::mapped_region();
      //});
   }
}

template<typename T>
void FLIMImage::releaseModifiedPointer()
{
   compute<T>();
   releasePointer<T>();
   
   std::unique_lock<std::mutex> lk(data_mutex);
   has_data = true;
   data_cv.notify_all();
}

template<typename T>
void FLIMImage::compute()
{
   int n_px = acq->n_px;
   int n_meas = acq->n_meas_full;
   int n_chan = acq->n_chan;
   int n_t = acq->n_t_full;
   bool has_ratio = acq->n_chan > 1;

   intensity = cv::Mat(acq->n_x, acq->n_y, CV_32F);
   
   if (has_ratio)
      ratio = cv::Mat(acq->n_x, acq->n_y, CV_32F);

   T* data = getDataPointer<T>();
   
   for (int i = 0; i < n_px; i++)
   {
      T I[2] = { 0, 0 };
      for (int c = 0; c < n_chan; c++)
      {
         int idx = c > 0 ? 1 : 0;
         for (int j = 0; j < n_t; j++)
            I[idx] += data[i*n_meas + c*n_t + j];
      }

      intensity.at<float>(i) = (float) (I[0] + I[1]);
      if (has_ratio)
         ratio.at<float>(i) = ((float)I[1]) / I[0];
   }
   
   releasePointer<T>();
}



template<typename T>
void FLIMImage::getDecayImpl(cv::Mat mask, std::vector<std::vector<double>>& decay)
{
   decay.resize(acq->n_chan);
   for(auto& d : decay)
      d.assign(acq->n_t_full, 0);
   
   T* data = getDataPointerForRead<T>();
 
   assert(mask.size() == intensity.size());

   for(int i=0; i<acq->n_px; i++)
   {
      int x = i % acq->n_x;
      int y = i / acq->n_x;
      
      if (mask.at<uint8_t>(x,y) > 0)
      {
         for(int j=0; j<acq->n_chan; j++)
            for (int k=0; k<acq->n_t_full; k++)
               decay[j][k] += data[i*acq->n_meas_full + j*(acq->n_t_full) + k];
         
      }
   }
   
   releasePointer<T>();
}


template<typename T>
std::shared_ptr<FLIMImage> FLIMImage::getRegionAsImageImpl(cv::Mat mask)
{
   
   auto new_acq = std::shared_ptr<AcquisitionParameters>(new AcquisitionParameters(*acq.get()));
   new_acq->setImageSize(1, 1);
   
   auto new_image = std::make_shared<FLIMImage>(new_acq, typeid(float), name, DataMode::InMemory);
      
   T* data = getDataPointer<T>();
   float* new_data = new_image->getDataPointer<float>();
   
   assert(mask.size() == intensity.size());
   
   for(int i=0; i<acq->n_px; i++)
   {
      int x = i % acq->n_x;
      int y = i / acq->n_x;
      
      if (mask.at<uint8_t>(x,y) > 0)
      {
         for(int j=0; j<acq->n_meas_full; j++)
            new_data[j] += data[i*acq->n_meas_full + j];
         
      }
   }
   
   new_image->releaseModifiedPointer<float>();
   releasePointer<T>();
   
   return new_image;
}

