#pragma once 

#include <boost/serialization/shared_ptr.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/base_object.hpp>

#include <vector>
#include <cv.h>

class FLIMBackground
{
public:
   enum BackgroundType { ConstantBackground, ImageBackground, TimeVaryingBackground, SpatiallyVaryingTimeVaryingBackground };

   FLIMBackground(float background_value_ = 0)
   {
      background_type = ConstantBackground;
      background_value = background_value_;
   }

   FLIMBackground(cv::Mat background_image_)
   {
      background_type = ImageBackground;
      background_image = background_image_;
   }
   
   FLIMBackground(std::vector<float> tvb_profile_, float background_value_ = 0)
   {
      background_type = TimeVaryingBackground;
      tvb_profile = tvb_profile_;
      background_value = background_value_;

      tvb_mean = 0;
      for (auto& b : tvb_profile)
         tvb_mean += b;
      tvb_mean /= tvb_profile.size();
   }
   
   FLIMBackground(std::vector<float> tvb_profile_, cv::Mat tvb_I_map_, float background_value_ = 0)
   {
      background_type = SpatiallyVaryingTimeVaryingBackground;
      tvb_profile = tvb_profile_;
      tvb_I_map = tvb_I_map_;
      background_value = background_value_;
      
      tvb_mean = 0;
      for(auto& b : tvb_profile)
         tvb_mean += b;
      tvb_mean /= tvb_profile.size();
   }
  


   float getAverageBackgroundPerGate(int p)
   {
      switch ( background_type )
      {
         case ConstantBackground:
            return background_value;
         case ImageBackground:
            return background_image.at<float>(p);
         case TimeVaryingBackground:
            return tvb_mean * tvb_I_map.at<float>(p) + background_value;
      }
      return 0;
   }
   
   float getBackgroundValue(int p, int m)
   {
      switch ( background_type )
      {
         case ConstantBackground:
            return background_value;
         case ImageBackground:
            return background_image.at<float>(p);
         case TimeVaryingBackground:
            return tvb_profile[m] + background_value;
         case SpatiallyVaryingTimeVaryingBackground:
            return tvb_profile[m] * tvb_I_map.at<float>(p) + background_value;
      }
      return 0;
   }
   
   
   double getBackgroundValue(int x, int y, int m)
   {
      return getBackgroundValue(x+y*n_x, m);
   }
   
   void SetBackground(float* background_image);
   void SetBackground(float background);
   void SetTVBackground(float* tvb_profile, float* tvb_I_map, float const_background);

protected:
   int n_x = 0;
   int n_y = 0;
   int n_meas = 0;
   
   BackgroundType background_type = ConstantBackground;
   float background_value = 0;
   cv::Mat background_image;
   cv::Mat tvb_I_map;
   float tvb_mean;
   std::vector<float> tvb_profile;
   
private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
};

template<class Archive>
void FLIMBackground::serialize(Archive & ar, const unsigned int version)
{
   ar & n_x;
   ar & n_y;
   ar & n_meas;
   ar & background_type;
   ar & background_value;
   ar & background_image;
   ar & tvb_I_map;
   ar & tvb_mean;
   ar & tvb_profile;
};



