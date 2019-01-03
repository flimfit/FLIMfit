#include "DataTransformer.h"

DataTransformationSettings::DataTransformationSettings(std::shared_ptr<InstrumentResponseFunction> irf) :
   irf(irf)
{
   background = std::make_shared<FLIMBackground>(0.0f);
}

const std::vector<float>& DataTransformer::getSteadyStateAnisotropy()
{
   getTransformedData();
   
   auto acq = image->getAcquisitionParameters();
   
   /* TODO : do we still want to calculate this?
   // Calculate Steady State Anisotropy
   if (acq->polarisation_resolved)
   {
      
      float g_factor = transform.irf->g_factor;
      int n_t = dp->n_t;
      int n_px = acq->n_px;
      
      r_ss.resize(n_px);
      float para;
      float perp;
      
      float* r_ptr = r_ss.data();
      float*  tr_data_ptr = transformed_data.data();
      
      for(int p=0; p<n_px; p++)
      {
         para = 0;
         perp = 0;
         
         for(int i=0; i<n_t; i++)
            para += tr_data_ptr[i];
         tr_data_ptr += n_t;
         for(int i=0; i<n_t; i++)
            perp += tr_data_ptr[i];
         tr_data_ptr += n_t;
         
         perp *= g_factor;
         
         *r_ptr = (para - perp) / (para + 2 * perp);
         
         
         r_ptr++;
      }
      
   }
   */
   return r_ss;
}


DataTransformer::DataTransformer(DataTransformationSettings& transform_)
{
   transform = transform_;
   refresh();
}

DataTransformer::DataTransformer(std::shared_ptr<DataTransformationSettings> transform_)
{
   transform = *transform_.get();
   refresh();
}


void DataTransformer::setImage(std::shared_ptr<FLIMImage> image_)
{
   if (image == image_)
      return;

   image = image_;
   refresh();
}

void DataTransformer::setTransformationSettings(DataTransformationSettings& transform_)
{
   transform = transform_;
   refresh();
}

const std::vector<float>::iterator DataTransformer::getTransformedData()
{
   switch (image->getDataClass())
   {
   case FLIMImage::DataFloat:
      transformData<float>();
      break;
   case FLIMImage::DataUint32:
      transformData<uint32_t>();
      break;
   case FLIMImage::DataUint16:
      transformData<uint16_t>();
      break;
   }

   return transformed_data.begin();
}

void DataTransformer::refresh()
{
   //already_transformed = false;

   if (image == nullptr)
      return;

   auto acq = image->getAcquisitionParameters();
   dp = std::make_shared<TransformedDataParameters>(acq, transform);

   switch (image->getDataClass())
   {
   case FLIMImage::DataFloat:
      calculateMask<float>();
      break;
   case FLIMImage::DataUint32:
      calculateMask<uint32_t>();
      break;
   case FLIMImage::DataUint16:
      calculateMask<uint16_t>();
      break;
   }
}
