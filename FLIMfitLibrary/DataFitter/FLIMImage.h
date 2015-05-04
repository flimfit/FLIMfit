#pragma once
#include "AcquisitionParameters.h"
#include <cstdint>
#include <typeindex> 
#include <string>
#include <cv.h>

class FLIMImage
{
public:

   enum DataClass { DataUint16, DataFloat };

   template<typename T>
   FLIMImage(shared_ptr<AcquisitionParameters> acq, T* data_) :
      acq(acq)
   {
      init();
      size_t sz = acq->n_px * acq->n_meas;
      memcpy(data.data(), data_, sz * sizeof(*data_));
      compute<T>();
   }

   FLIMImage(shared_ptr<AcquisitionParameters> acq, std::type_index type) :
      acq(acq),
      stored_type(type)
   {
      init();
   }

   void init()
   {
      if (stored_type == typeid(float))
         data_class = DataFloat;
      else if (stored_type == typeid(uint16_t))
         data_class = DataUint16;
      else
         throw std::runtime_error("Unsupported data type");

      int n_bytes = 1;
      if (stored_type == typeid(float))
         n_bytes = 4;
      else if (stored_type == typeid(uint16_t))
         n_bytes = 2;


      int sz = acq->n_meas_full * acq->n_x * acq->n_y * n_bytes;
      data.resize(sz);
   }


   template<typename T>
   T* getDataPointer()
   { 
      if (stored_type != typeid(T))
         throw std::runtime_error("Attempting to retrieve incorrect data type");
      return reinterpret_cast<T*>(data.data()); 
   }
   
   template<typename T>
   void releasePointer()
   {
      compute<T>();
   }

   std::shared_ptr<AcquisitionParameters> getAcquisitionParameters()
   {
      return acq;
   }


   template<typename T>
   void compute()
   {
      int n_px = acq->n_px;
      int n_meas = acq->n_meas;
      intensity = cv::Mat(acq->n_x, acq->n_y, CV_32F);
      
      
      T* data = getDataPointer<T>();
      
      for (int i=0; i<n_px; i++)
         for (int j=0; j<n_meas; j++)
            intensity.at<float>(i) += data[i*n_meas + j];
      
   }

   void getDecay(cv::Mat mask, std::vector<std::vector<double>>& decay)
   {
      if (stored_type == typeid(float))
         getDecayImpl<float>(mask, decay);
      else if (stored_type == typeid(uint16_t))
         getDecayImpl<uint16_t>(mask, decay);
   }   

   const std::string& getName() { return name; }
   void setName(const std::string& name_) { name = name_; }
   DataClass getDataClass() { return data_class; }
   cv::Mat getIntensity() { return intensity; }
protected:

   template<typename T>
   void getDecayImpl(cv::Mat mask, std::vector<std::vector<double>>& decay)
   {
      assert(mask.size() == intensity.size());
      
      decay.resize(acq->n_chan);
      for(auto& d : decay)
         d.assign(acq->n_t, 0);
      
      T* data = getDataPointer<T>();
      
      for(int i=0; i<acq->n_px; i++)
      {
         if (mask.at<uint8_t>(i) > 0)
         {
            for(int j=0; j<acq->n_chan; j++)
               for (int k=0; k<acq->n_t; k++)
                  decay[j][k] += data[i*acq->n_meas + j*(acq->n_t) + k];
            
         }
      }
   }

   
   shared_ptr<AcquisitionParameters> acq;
   DataClass data_class;
   vector<uint8_t> data;
   std::type_index stored_type;
   std::string name;
   cv::Mat intensity;
};

