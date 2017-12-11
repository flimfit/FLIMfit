#pragma once

#include <vector>
#include <memory>

#include <boost/random/mersenne_twister.hpp>
#include <boost/random/uniform_int.hpp>
#include <boost/random/poisson_distribution.hpp>


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

      std::fill(incr.begin(), incr.end(), true);

      int idx = 0;
      int c = 0;
      double ss = 0;
      int q = 0;
      while (idx < n)
      {
         if (c > 0)
         {
            incr[idx] = 0;
            ss += decay[idx];
            c--;
         }
         else if ((c == 0) & (ss < 5))
         {
            incr[idx] = 0;
            ss += decay[idx];
            c = 5;
         }
         else if (decay[idx] < 1)
         {
            c = 10;
            ss = 0;
            //incr[idx] = 0;
         }
         idx++;
      }

      //for (int i = 0; i < n; i++)
      //   incr[i] = (decay[i] > 0);
 
      n_resampled = n;
      for (int i = 0; i < (n - 1); i++)
         n_resampled -= (incr[i] == 0);

      return;
      


      std::fill(incr.begin(), incr.end(), true);

      double s = 0;
      for(int i=0; i<n; i++)
      {
         s += decay[i];
         if (s <= 5.0 + eps && (n_resampled > n_min))
            incr[i] = 0;
         else
            s = 0;
      }

      for (int i = n - 1; i >= 1; i--)
      {
         if (decay[i] <= eps)
               incr[i - 1] = 0;
         else
            break;
      }

      n_resampled = n;
      for (int i = 0; i < (n-1); i++)
         n_resampled -= (incr[i] == 0);

      
   }

   template<typename T, typename U>
   void resample(T* decay, U* resampled)
   {
      for(int i=0; i<n; i++)
         resampled[i] = (U) decay[i];
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