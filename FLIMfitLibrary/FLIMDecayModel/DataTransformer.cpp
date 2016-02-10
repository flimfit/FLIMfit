#include "DataTransformer.h"

DataTransformationSettings::DataTransformationSettings()
{
   background = std::make_shared<FLIMBackground>(0.0f);
}

const std::vector<float>& DataTransformer::getSteadyStateAnisotropy()
{
   getTransformedData();
   
   auto acq = image->getAcquisitionParameters();
   
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
   
   return r_ss;
}