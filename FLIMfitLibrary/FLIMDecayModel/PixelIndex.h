#pragma once

class PixelIndex
{
public:

   PixelIndex(int pixel_ = 0, int image_ = 0)
   {
      pixel = pixel_;
      image = image_;
   }

   PixelIndex& operator=(int pixel_)
   {
      pixel = pixel_;
      return *this;
   }

   int image = 0;
   int pixel = 0;
};