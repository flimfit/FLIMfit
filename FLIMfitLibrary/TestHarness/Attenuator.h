#pragma once

#include <functional>
#include <boost/random/binomial_distribution.hpp>
#include <boost/random/lagged_fibonacci.hpp>
#include "FLIMImage.h"

class Attenuator
{
public:

   Attenuator(std::function<double(int, int)> transmission, int chan) : 
      transmission(transmission), chan(chan)
   {
      gen.seed(100);
   }

   void attenuate(std::shared_ptr<FLIMImage> image)
   {
      auto data_class = image->getDataClass();
      if (data_class == FLIMImage::DataClass::DataFloat)
         attenuate_<float>(image);
      else if (data_class == FLIMImage::DataClass::DataUint16)
         attenuate_<uint16_t>(image);
      else if (data_class == FLIMImage::DataClass::DataUint32)
         attenuate_<uint32_t>(image);
   }

private:
 
   template <typename T>
   void attenuate_(std::shared_ptr<FLIMImage> image)
   {

      auto acq = image->getAcquisitionParameters();
      int n_x = acq->n_x;
      int n_y = acq->n_y;
      int n_t = acq->n_t_full;
      int n_chan = acq->n_chan;

      auto data_ptr = image->getDataPointer<T>();

      for (int y = 0; y < n_y; y++)
         for (int x = 0; x < n_x; x++)
            for (int t = 0; t < n_t; t++)
            {
               int idx = t + (chan + (x + y * n_x) * n_chan) * n_t;
               int m = data_ptr[idx];
               boost::random::binomial_distribution<int,double> dist(m, transmission(x, y));
               data_ptr[idx] = (T) dist(gen);
            }

      image->releaseModifiedPointer<T>();
   }

   int chan;
   boost::lagged_fibonacci44497 gen;
   boost::random::binomial_distribution<int> dist;
   std::function<double(int, int)> transmission;
};