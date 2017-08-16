#pragma once

#include <vector>
#include <memory>

class DecayResampler
{
public:
   DecayResampler(int n, int n_min) : 
      n(n), n_min(n_min), n_resampled(n)
   {
      incr.resize(n, true);
   }

   template<typename T>
   void determineSampling(const T* decay)
   {
      T eps = std::numeric_limits<T>::min();

      n_resampled = n;
      std::fill(incr.begin(), incr.end(), 1);

      for(int i=0; i<(n-1); i++)
      {
         if (decay[i] <= eps && n_resampled > n_min)
         {
            incr[i] = 0;
            n_resampled--;
         }
      }

      return;
      
      if (decay[n-1] <= eps && n_resampled > n_min)
      {
         if (incr[n-2] == 1)
            n_resampled--;
         incr[n-2] = 0;         
      }

      
   }

   template<typename T, typename U>
   void resample(T* decay, U* resampled)
   {
      for(int i=0; i<n; i++)
         resampled[i] = (T) decay[i];
      resample(resampled);
   }


   template<typename T>
   void resample(T* decay)
   {
      int idx = 0;
      for(int i=0; i<n; i++)
      {
         if (i > idx)
         {
            decay[idx] += decay[i];
            decay[i] = 0;            
         }
         idx += incr[i];
      }
   }

   int resampledSize() { return n_resampled; }



private:

   std::vector<bool> incr;

   int n;
   int n_min;
   int n_resampled;

};