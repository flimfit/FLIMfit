#include "PhasorCalculator.h"

Phasor operator/(const Phasor &a, const Phasor &b)
{
   float norm = b.g*b.g + b.s*b.s;
   
   float g = (a.g * b.g + a.s * b.s) / norm;
   float s = (a.s * b.g - a.g * b.s) / norm;
   float I = a.I / b.I;
   
   return Phasor(g,s,I);
}



void PhasorCalculator::setImages(std::vector<std::shared_ptr<FLIMImage>> images_, std::shared_ptr<DataTransformationSettings> transform_)
{
   images = images_;
   
   transform = transform_;
   calculate();
}

void PhasorCalculator::setChannel(int channel_)
{
   channel = channel_;
   calculate();
}

cv::Mat PhasorCalculator::getMap()
{
   cv::Mat phasor_map(image_size, image_size, CV_32F, 0.0f);
   
   std::vector<std::shared_ptr<FLIMImage>> display_images;
   
   if (display_all)
      display_images = images;
   else
      display_images.push_back(selected_image);
   
   for (auto& im : display_images)
   {
      if (im == nullptr)
         continue;
      
      std::vector<Phasor>& phasor = phasors[im];
      
      auto intensity = im->getIntensity();
      
      int valid = 0, invalid = 0;
      for(size_t i=0; i<phasor.size(); i++)
      {
         
         int x = std::round(phasor[i].g * image_size);
         int y = std::round(image_size-1 - phasor[i].s * image_size);
         
         if (x >= 0 && x < image_size && y >=0 && y < image_size)
         {
            valid++;
            phasor_map.at<float>(x,y) += phasor[i].I;
         }
         else
         {
            invalid++;
         }
      }
      std::cout << valid << ", " << invalid << "\n";
   }
   return phasor_map;
}

void PhasorCalculator::calculate()
{
   for (auto& im : images)
   {
      auto data_class = im->getDataClass();
      
      if (data_class == FLIMImage::DataUint16)
         phasors[im] = calculatePhasor<uint16_t>(im, channel);
      else if (data_class == FLIMImage::DataFloat)
         phasors[im] = calculatePhasor<double>(im, channel);
      
   }
}


Phasor PhasorCalculator::getIRFPhasor(std::shared_ptr<InstrumentResponseFunction> irf, float omega, int channel)
{
   Phasor phasor;
   
   double t0 = irf->timebin_t0;
   double dt = irf->timebin_width;
   int n_t = irf->n_irf;
   
   
   std::vector<double> buf(n_t * irf->n_chan);
   double* data = irf->GetIRF(0, 0, buf.data()) + n_t * channel;
   
   double g = 0;
   double s = 0;
   double sum = 0;
   
   for (int i=0; i<n_t; i++)
   {
      double t = t0 + dt * i;
      
      sum += data[i];
      g += data[i] * cos(omega * t);
      s += data[i] * sin(omega * t);
   }
   
   phasor.g = g / sum;
   phasor.s = s / sum;
   phasor.I = 1;
   
   return phasor;
}
