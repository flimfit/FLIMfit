#pragma once

#include "FLIMImage.h"
#include "FLIMBackground.h"
#include "InstrumentResponseFunction.h"

#include <vector>
#include <QObject>

class DataTransformationSettings
{
public:
   
   DataTransformationSettings(std::shared_ptr<InstrumentResponseFunction> irf = nullptr);
   
   int smoothing_factor = 0;
   double t_start = 0;
   double t_stop = 25000;
   double intensity_min = 0;
   double intensity_max = std::numeric_limits<double>::max();
   double gate_max = 0;
   std::shared_ptr<FLIMBackground> background;
   std::shared_ptr<InstrumentResponseFunction> irf;
};


class QDataTransformationSettings : public QObject, public DataTransformationSettings
{
   Q_OBJECT

public:

   Q_PROPERTY(int smoothing_factor MEMBER smoothing_factor USER true);
   Q_PROPERTY(double t_start MEMBER t_start USER true);
   Q_PROPERTY(double t_stop MEMBER t_stop USER true);
   Q_PROPERTY(double intensity_min MEMBER intensity_min USER true);
   Q_PROPERTY(double intensity_max MEMBER intensity_max USER true);
   Q_PROPERTY(double gate_max MEMBER gate_max USER true);
   Q_PROPERTY(std::shared_ptr<FLIMBackground> background MEMBER background USER true);

private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
};

BOOST_CLASS_VERSION(QDataTransformationSettings, 3);

template<class Archive>
void QDataTransformationSettings::serialize(Archive & ar, const unsigned int version)
{
   ar & smoothing_factor;

   if (version < 2)
   {
      int i_t_start, i_t_stop, i_threshold, i_limit;
      ar & i_t_start;
      ar & i_t_stop;
      ar & i_threshold;
      ar & i_limit;
      
      t_start = (double) i_t_start;
      t_stop = (double) i_t_stop;
      intensity_min = (double) i_threshold;
      gate_max = (double) i_limit;
   }
   else
   {
      ar & t_start;
      ar & t_stop;
      ar & intensity_min;
      ar & gate_max;
   }

   if (version >= 3)
      ar & intensity_max;

   ar & background;
   ar & irf;
}



class TransformedDataParameters : public DataTransformationSettings
{
public:
   TransformedDataParameters(std::shared_ptr<AcquisitionParameters> acq, const DataTransformationSettings& transform) :
      DataTransformationSettings(transform), acq(acq)
   {      
      n_chan = acq->n_chan;
      
      const std::vector<double>& t_full = acq->getTimePoints();
      int n_t_full = static_cast<int>(t_full.size());
      
      if (t_start > t_full[n_t_full-1])
         throw std::runtime_error("Invalid t start");
      
      t_skip = 0;
      for (int i=0; i<n_t_full; i++)
      {
         if (t_full[i] < transform.t_start)
            t_skip = i+1;
         else if (t_full[i] <= transform.t_stop)
            timepoints.push_back(t_full[i]);
      }
      
      n_t = static_cast<int>(timepoints.size());
      n_meas = n_t * n_chan;
      
      // Copy the things we don't change
      irf = transform.irf;
      counts_per_photon = acq->counts_per_photon;
      t_int = acq->t_int;
      t_rep = acq->t_rep;
      polarisation = acq->polarisation;
      equally_spaced_gates = acq->equally_spaced_gates;

      n_x = acq->n_x;
      n_y = acq->n_y;
      
      int dim_required = transform.smoothing_factor * 2 + 2;

      if ((acq->n_x >= dim_required) && (acq->n_y >= dim_required))
         smoothing_factor = transform.smoothing_factor;
      else
         smoothing_factor = 0;

      smoothing_area = (float)(2 * smoothing_factor + 1)*(2 * smoothing_factor + 1);
   }

   const std::vector<double>& getTimepoints() { return timepoints; }
   const std::vector<double>& getGateIntegrationTimes() { return t_int; }
   const std::vector<Polarisation>& getPolarisation() { return polarisation; }

   bool equally_spaced_gates;
   int smoothing_factor;
   int smoothing_area;
   int n_t;
   int n_meas;
   int n_chan;
   int t_skip;
   int n_x;
   int n_y;
   std::shared_ptr<InstrumentResponseFunction> irf;
   double counts_per_photon;
   double t_rep;
   
   std::vector<float> tvb_profile; // todo -> sort this out for model
   
protected:
   
   std::shared_ptr<AcquisitionParameters> acq;
   
   std::vector<double> t_int;
   std::vector<double> timepoints;
   std::vector<Polarisation> polarisation;

private:
   
   TransformedDataParameters() {}
   
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
};

BOOST_CLASS_VERSION(TransformedDataParameters, 3)

template<class Archive>
void TransformedDataParameters::serialize(Archive & ar, const unsigned int version)
{
   bool polarisation_resolved;
   if (version <= 2)
      ar & polarisation_resolved;
   else
      ar & polarisation;
   ar & equally_spaced_gates;
   ar & smoothing_factor;
   ar & smoothing_area;
   ar & n_t;
   ar & n_meas;
   ar & n_chan;
   ar & t_skip;
   ar & irf;
   ar & counts_per_photon;
   ar & t_rep;
   ar & tvb_profile;
   ar & acq;
   ar & t_int;
   ar & timepoints;
   if (version >= 2)
   {
      ar & n_x;
      ar & n_y;
   }
}


class DataTransformer
{
public:
   DataTransformer(DataTransformationSettings& transform_);
   DataTransformer(std::shared_ptr<DataTransformationSettings> transform_);

   void setImage(std::shared_ptr<FLIMImage> image_);
   void setTransformationSettings(DataTransformationSettings& transform_);
   std::vector<float>::const_iterator getTransformedData();
   cv::Mat getMask();
   
   const std::vector<float>& getSteadyStateAnisotropy();
   
   int getNumMeasurements() { return dp->n_meas; }
   
private:

   void refresh();
   
   
   template <typename T>
   void transformData();
   
   template <typename T>
   void calculateMask();

   std::shared_ptr<FLIMImage> image;
   DataTransformationSettings transform;
   std::shared_ptr<TransformedDataParameters> dp;
   std::vector<float> tr_row_buf;
   std::vector<float> y_smoothed_buf;
   
   cv::Mat final_mask;
   std::vector<float> transformed_data;
   std::vector<float> r_ss;
    
   std::mutex transformation_mutex;
   bool transformed = false;
};



template <typename T>
void DataTransformer::calculateMask()
{
   cv::Mat seg_mask = image->getSegmentationMask();
   cv::Mat intensity = image->getIntensity();
   bool has_seg_mask = !seg_mask.empty();

   auto acq = image->getAcquisitionParameters();

   int n_px = acq->n_px;
   int n_meas_full = acq->n_meas_full;
   
   T* data_ptr = image->getDataPointerForRead<T>();
   final_mask = cv::Mat(acq->n_y, acq->n_x, CV_16U, cv::Scalar(1));
   
   for(int p=0; p<n_px; p++)
   {
      auto& mp = final_mask.at<uint16_t>(p);

      if (has_seg_mask)
      {
         mp = seg_mask.at<uint16_t>(p);
         if (mp == 0) continue; // no need to look at the intensity etc
      }
      
      T* ptr = data_ptr + p*n_meas_full;
      if (transform.gate_max > 0)
      {
         for(int i=0; i<n_meas_full; i++)
            if (ptr[i] >= (T) transform.gate_max)
            {
               mp = 0;
               break;
            }
      }
      
      float bg_val = transform.background->getAverageBackgroundPerGate(p) * n_meas_full;
      float intensity_value = intensity.at<float>(p) - bg_val;
      if ((intensity_value < transform.intensity_min) || (intensity_value > transform.intensity_max))
         mp = 0;
      
   }
   
   image->releasePointer<T>();
}

template <typename T>
void DataTransformer::transformData()
{
   if (transformed)
      return;

   auto acq = image->getAcquisitionParameters();
   int n_x = acq->n_x;
   int n_y = acq->n_y;
   int n_chan = acq->n_chan;
   int n_meas_full = acq->n_meas_full;

   y_smoothed_buf.resize(acq->n_px);
   tr_row_buf.resize(acq->n_y);

   transformed_data.resize(n_x * n_y * dp->n_meas);
   auto tr_data = transformed_data.begin();

   T* tr_buf = image->getDataPointerForRead<T>();
   T* cur_data_ptr = tr_buf;

   float photons_per_count = (float)(1 / acq->counts_per_photon);

   int s = transform.smoothing_factor;
   int s_min = 2 * s + 1;

   if ((s == 0) || (n_x < s_min) || (n_y < s_min))
   {
      auto tr_ptr = tr_data;
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

   transformed = true;
}