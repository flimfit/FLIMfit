#pragma once

#include "FLIMImage.h"
#include "FLIMBackground.h"
#include <vector>

class DataTransformationSettings
{
public:
   int smoothing_factor = 0;
   int t_start = 0;
   int t_stop = 0;
   int threshold = 0;
   int limit = 1<<31;
   std::shared_ptr<FLIMBackground> background;
};



class TransformedDataParameters : public DataTransformationSettings
{
public:
   TransformedDataParameters(std::shared_ptr<AcquisitionParameters> acq_, const DataTransformationSettings& transform) :
   DataTransformationSettings(transform)
   {
      acq = acq_;
      
      n_chan = acq->n_chan;
      
      const std::vector<double>& t_full = acq->GetTimePoints();
      int n_t_full = t_full.size();
      
      if (t_start > t_full[n_t_full-1])
         throw std::runtime_error("Invalid t start");
      
      for (int i=0; i<n_t_full; i++)
      {
         if (t_full[i] < transform.t_start)
            t_skip = i+1;
         else if (t_full[i] <= transform.t_stop)
            timepoints.push_back(t_full[i]);
      }
      
      n_t = timepoints.size();
      n_meas = n_t * n_chan;
   }

   int n_t;
   int n_meas;
   int n_chan;
   int t_skip;
   
protected:
   
   std::shared_ptr<AcquisitionParameters> acq;
   
   std::vector<double> timepoints;
};

class DataTransformer
{
public:
   DataTransformer()
   {
      
   }

   void setImage(std::shared_ptr<FLIMImage> image_)
   {
      image = image_;
      auto acq = image->getAcquisitionParameters();
      dp = std::make_shared<TransformedDataParameters>(acq, transform);
      
      y_smoothed_buf.resize(acq->n_px);
      tr_row_buf.resize(acq->n_y);
   };

   void setTransformationSettings(DataTransformationSettings& transform_ )
   {
      transform = transform_;
      if (image != nullptr)
         setImage(image);
   };
   
   template <typename T>
   void getTransformedData(T* data);

   template <typename T>
   void getDataMask(std::vector<uint8_t> final_mask);
   
private:
   std::shared_ptr<FLIMImage> image;
   DataTransformationSettings transform;
   std::shared_ptr<TransformedDataParameters> dp;
   vector<float> tr_row_buf;
   vector<float> y_smoothed_buf;
};

template <typename T>
void DataTransformer::getDataMask(std::vector<uint8_t> final_mask)
{
   const vector<uint8_t> seg_mask = image->getSegmentationMask();
   cv::Mat intensity = image->getIntensity();
   bool has_seg_mask = seg_mask.size() > 0;

   auto acq = image->getAcquisitionParameters();

   int n_px = acq->n_px;
   int n_meas_full = acq->n_meas_full;
   
   T* data_ptr = image->getDataPointer<T>();
   
   for(int p=0; p<n_px; p++)
   {
      if (has_seg_mask)
      {
         final_mask[p] = seg_mask[p];
         if (final_mask[p] == 0) continue; // no need to look at the intensity etc
      }
      else
      {
       final_mask[p] = 1;
      }
      
      T* ptr = data_ptr + p*n_meas_full;
      if (transform.limit > 0)
      {
         for(int i=0; i<n_meas_full; i++)
            if (transform.limit > 0 && ptr[i] >= transform.limit)
            {
               final_mask[p] = 0;
               break;
            }
      }
      
      float bg_val = transform.background->getAverageBackgroundPerGate(p) * n_meas_full;
      if ((intensity.at<float>(p)-bg_val) < transform.threshold || final_mask[p] < 0)
         final_mask[p] = 0;
      
   }
   
   image->releasePointer<T>();
}

template <typename T>
void DataTransformer::getTransformedData(T* tr_data)
{
   //int idx, tr_idx;
   
   auto acq = image->getAcquisitionParameters();
   int n_x = acq->n_x;
   int n_y = acq->n_y;
   int n_chan = acq->n_chan;
   int n_meas_full = acq->n_meas_full;

   T* tr_buf = image->getDataPointer<T>();
   T* cur_data_ptr = tr_buf;
   
   float photons_per_count = (float) (1/acq->counts_per_photon);
   
   
   
   if ( transform.smoothing_factor == 0 )
   {
      float* tr_ptr = tr_data;
      // Copy data from source to tr_data, skipping cropped time points
      for(int y=0; y<n_y; y++)
         for(int x=0; x<n_x; x++)
            for(int c=0; c<n_chan; c++)
            {
               for(int i=0; i<dp->n_t; i++)
                  tr_ptr[i] = cur_data_ptr[dp->t_skip+i];
               cur_data_ptr += acq->n_t_full;
               tr_ptr += dp->n_t;
            }
   }
   else
   {
      int s = transform.smoothing_factor;
      
      int dxt = dp->n_meas;
      int dyt = n_x * dxt;
      
      int dx = n_meas_full;
      int dy = n_x * dx;
      
      float sa = (float) 2*s+1;
      
      for(int c=0; c<n_chan; c++)
      {
         for(int i=0; i<dp->n_t; i++)
         {
            int tr_idx = c*dp->n_t + i;
            int idx = c*acq->n_t_full + dp->t_skip + i;
            
            //Smooth in y axis
            for(int x=0; x<n_x; x++)
            {
               for(int y=0; y<s; y++)
               {
                  tr_row_buf[y] = 0;
                  for(int yp=0; yp<y+s; yp++)
                     tr_row_buf[y] += cur_data_ptr[yp*dy+x*dx+idx];
                  tr_row_buf[y] *= (sa / (y+s));
               }
               
               
               for(int y=s; y<n_y-s; y++ )
               {
                  tr_row_buf[y] = 0;
                  for(int yp=y-s; yp<=y+s; yp++)
                     tr_row_buf[y] += cur_data_ptr[yp*dy+x*dx+idx];
               }
               
               for(int y=n_y-s; y<n_y; y++ )
               {
                  tr_row_buf[y] = 0;
                  for(int yp=y-s; yp<n_y; yp++)
                     tr_row_buf[y] += cur_data_ptr[yp*dy+x*dx+idx];
                  tr_row_buf[y] *= (sa / (n_y-y+s));
               }
               
               for(int y=0; y<n_y; y++)
                  y_smoothed_buf[y*n_x+x] = tr_row_buf[y];
            }
            
            //Smooth in x axis
            for(int y=0; y<n_y; y++)
            {
               for(int x=0; x<s; x++)
               {
                  tr_row_buf[x] = 0;
                  for(int xp=0; xp<x+s; xp++)
                     tr_row_buf[x] += y_smoothed_buf[y*n_x+xp];
                  tr_row_buf[x] *= (sa / (x+s));
               }
               
               for(int x=s; x<n_x-s; x++)
               {
                  tr_row_buf[x] = 0;
                  for(int xp=x-s; xp<=x+s; xp++)
                     tr_row_buf[x] += y_smoothed_buf[y*n_x+xp];
               }
               
               for(int x=n_x-s; x<n_x; x++ )
               {
                  tr_row_buf[x] = 0;
                  for(int xp=x-s; xp<n_x; xp++)
                     tr_row_buf[x] += y_smoothed_buf[y*n_x+xp];
                  tr_row_buf[x] *= (sa / (n_x-x+s));
               }
               
               for(int x=0; x<n_x; x++)
                  tr_data[y*dyt+x*dxt+tr_idx] = tr_row_buf[x];
               
            }
            
         }
      }
   }
   
   
   std::shared_ptr<FLIMBackground> background = transform.background;
   
   // Subtract background
   int idx = 0;
   for(int p=0; p<acq->n_px; p++)
   {
      for(int i=0; i<dp->n_meas; i++)
      {
         tr_data[idx] -= background->getBackgroundValue(p, i);
         tr_data[idx] *= photons_per_count;
         if (tr_data[i] < 0) tr_data[i] = 0;
         idx++;
      }
   }
   
   image->releasePointer<T>();
   
}