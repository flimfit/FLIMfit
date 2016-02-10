#pragma once 

#define _USE_MATH_DEFINES

#include "FLIMImage.h"
#include <vector>
#include <cv.h>
#include <cstdint>
#include <map>
#include <memory>
#include <cmath>
#include "DataTransformer.h"

class Phasor
{
public:
   Phasor(float g = 1, float s = 0, float I = 1) :
      g(g), s(s), I(I)
   {
   }
   
   float g;
   float s;
   float I;
   
   friend Phasor operator/(const Phasor &a, const Phasor &b);
};



class PhasorCalculator
{
public:
   
   PhasorCalculator()
   {}
   
   template<typename T>
   std::vector<Phasor> calculatePhasor(std::shared_ptr<FLIMImage> im, int channel);

   void setImageToDisplay(std::shared_ptr<FLIMImage> image)
   {
      display_all = false;
      selected_image = image;
   }
   
   void displayAllImages()
   {
      display_all = true;
   }
   
   void setImages(std::vector<std::shared_ptr<FLIMImage>> images, std::shared_ptr<DataTransformationSettings> transform);
   void setChannel(int channel);
   cv::Mat getMap();
   
protected:
   
   void calculate();
   
   
   Phasor getIRFPhasor(std::shared_ptr<InstrumentResponseFunction> irf, float omega, int channel);

protected:
   
   std::map<std::shared_ptr<FLIMImage>, std::vector<Phasor>> phasors;
   std::shared_ptr<DataTransformationSettings> transform;
   std::vector<std::shared_ptr<FLIMImage>> images;
   std::shared_ptr<FLIMImage> selected_image;
   int image_size = 500;
   int channel = 0;
   bool display_all = true;
};


template<typename T>
std::vector<Phasor> PhasorCalculator::calculatePhasor(std::shared_ptr<FLIMImage> im, int channel)
{
   auto acq = im->getAcquisitionParameters();
   int n_px = acq->n_px;
   int n_t = acq->n_t_full;
   auto t = acq->getTimePoints();
   float omega = 2.0*M_PI/acq->t_rep;
   
   std::vector<Phasor> phasor(n_px);
   
   Phasor irf_phasor;
   if (transform->irf != nullptr)
      irf_phasor = getIRFPhasor(transform->irf, omega, channel);
   
   T* data = im->getDataPointerForRead<T>();
   
   std::vector<float> cost(n_t);
   std::vector<float> sint(n_t);
   
   for (int i=0; i<n_t; i++)
   {
      cost[i] = cos(omega * t[i]);
      sint[i] = sin(omega * t[i]);
   }
   
   for (int p=0; p<n_px; p++)
   {
      T* px_data = data + p * acq->n_meas_full + channel * n_t;
      
      float sum = 0;
      float g = 0;
      float s = 0;
      
      for (int i=0; i<n_t; i++)
      {
         sum += px_data[i];
         g += px_data[i] * cost[i];
         s += px_data[i] * sint[i];
      }
      
      g /= sum;
      s /= sum;
      
      phasor[p] = Phasor(g, s, sum) / irf_phasor;
   }
   
   im->releasePointer<T>();
   
   return phasor;
}
