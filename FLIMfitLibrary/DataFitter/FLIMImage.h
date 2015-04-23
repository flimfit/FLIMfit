#pragma once
#include "AcquisitionParameters.h"
#include <stdint.h>

class FLIMDataSet
{
public:

   enum DataClass { DataUint16, DataFloat };

   FLIMDataSet(shared_ptr<AcquisitionParameters> acq, float* data_) :
      acq(acq),
      data_class(DataFloat)
   {
      int sz = acq->n_meas_full * acq->n_x * acq->n_y;
      data.resize(sz);
      memcpy(data.data(), data_, sz * sizeof(*data_));
   }

   FLIMDataSet(shared_ptr<AcquisitionParameters> acq, uint16_t* data_) :
      acq(acq),
      data_class(DataUint16)
   {
      int sz = acq->n_meas_full * acq->n_x * acq->n_y;
      data.resize(sz);
      memcpy(data.data(), data_, sz * sizeof(*data_));
   }

   template<typename T>
   T* GetData() { reinterpret_cast<T*>(data.data()); }

protected:
   shared_ptr<AcquisitionParameters> acq;
   DataClass data_class;
   vector<uint8_t> data;
};