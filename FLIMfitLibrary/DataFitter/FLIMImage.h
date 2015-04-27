#pragma once
#include "AcquisitionParameters.h"
#include <cstdint>
#include <typeindex> 
#include <string>

class FLIMImage
{
public:

   enum DataClass { DataUint16, DataFloat };

   template<typename T>
   FLIMImage(shared_ptr<AcquisitionParameters> acq, T* data_) :
      acq(acq)
   {
      Init(T);
      memcpy(data.data(), data_, sz * sizeof(*data_));
      Compute();
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
         throw std::exception("Unsupported data type");

      int n_bytes = 1;
      if (stored_type == typeid(float))
         n_bytes = 4;
      else if (stored_type == typeid(uint16_t))
         n_bytes = 2;


      int sz = acq->n_meas_full * acq->n_x * acq->n_y * n_bytes;
      data.resize(sz);
   }


   template<typename T>
   T* dataPointer()
   { 
      if (stored_type != typeid(T))
         throw std::exception("Attempting to retrieve incorrect data type");
      return reinterpret_cast<T*>(data.data()); 
   }

   std::shared_ptr<AcquisitionParameters> acquisitionParameters()
   {
      return acq;
   }


   void compute()
   {

   }

   const std::string& name() { return name_; }
   void setName(const std::string& name) { name_ = name; }
   DataClass dataClass() { return data_class; }

protected:
  
   shared_ptr<AcquisitionParameters> acq;
   DataClass data_class;
   vector<uint8_t> data;
   std::type_index stored_type;
   std::string name_;
};

