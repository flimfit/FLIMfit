//=========================================================================
//  
//  FLIMfit
//
//  Code derived from: 
//  * Fast Computation of Trimmed Means. Gleb Beliakov
//  * http://www.jstatsoft.org/v39/c02/paper
//  * Modified 2013 Sean Warren
//  * Subject to the terms of the GPLv2 (JStatSoft)
//
//  Routines for calculating region statistics including trimmed mean,
//  median, percentile ranges etc
//
//=========================================================================


#ifndef TRIMMED_MEAN_H
#define TRIMMED_MEAN_H

#include "RegionStats.h"
#include "util.h"
#define SWAP(a,b) temp=(a);(a)=(b);(b)=temp;

#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics.hpp>
#include <boost/accumulators/statistics/mean.hpp>
#include <boost/accumulators/statistics/variance.hpp>
#include <boost/accumulators/statistics/weighted_mean.hpp>
#include <boost/accumulators/statistics/weighted_variance.hpp>
#include <boost/accumulators/statistics/tail_quantile.hpp>
#include <boost/accumulators/statistics/median.hpp>
#include <boost/accumulators/statistics/weighted_sum_kahan.hpp>


/**
 * Classic quickselect algorithm
 */
template <typename T>
float quickselect(T *arr, unsigned long n, unsigned long k) 
{
   unsigned long i,ir,j,l,mid;
   T a,temp;

   l=0;
   ir=n-1;
   for(;;) 
   {
      if (ir <= l+1) 
      { 
         if (ir == l+1 && arr[ir] < arr[l]) 
         {
            SWAP(arr[l],arr[ir]);
         }
         return arr[k];
      }
      else 
      {
         mid=(l+ir) >> 1; 
         SWAP(arr[mid],arr[(l+1)]);
         if (arr[l] > arr[ir]) 
         {
            SWAP(arr[l],arr[ir]);
         }
         if (arr[(l+1)] > arr[ir]) 
         {
            SWAP(arr[(l+1)],arr[ir]);
         }
         if (arr[l] > arr[(l+1)]) 
         {
            SWAP(arr[l],arr[(l+1)]);
         }
         i=l+1; 
         j=ir;
         a=arr[(l+1)]; 
         for (;;)
         { 
            do i++; while (arr[i] < a && i<n-1); 
            do j--; while (arr[j] > a && j>0); 
            if (j < i) break; 
            SWAP(arr[i],arr[j]);
         } 
         arr[(l+1)]=arr[j]; 
         arr[j]=a;
         if (j >= k) ir=j-1; 
         if (j <= k) l=i;
      }
   }
}

template <typename T>
float Weighted(T x, T t1, T t2, T w1, T w2)
{
   if(x<t2 && x>t1) return 1;
   if(x<t1) return 0;
   if(x>t2) return 0;
   if(x==t1) return w1;
   return w2; // if(x==t2)
}

template <typename T>
void TrimmedMean(T x[], T w[], int n, int K, T conf_factor, RegionStats<T>& stats_, int region)
{
   using namespace boost::accumulators;

   T OS1, OS2, wt, q1, q2, med;
   double p_mean, p_std, p_w_mean, p_w_std, p_err;

   accumulator_set< double, features< tag::variance, tag::weighted_variance, tag::median > > acc0;
   accumulator_set< double, features< tag::tail_quantile<left>, tag::tail_quantile<right> > > acc1( tag::tail<left>::cache_size = n, tag::tail<right>::cache_size = n );

   if (n == 0)
   {
      SetNaN(&q1,1);
      stats_.SetNextParam(region, q1);
      return;
   }


   /*
   OS1    = quickselect(x, n, K);
   q1     = quickselect(x, n, (unsigned long)(0.25*n));
   median = quickselect(x, n, (unsigned long)(0.5*n));
   q2     = quickselect(x, n, (unsigned long)(0.75*n));
   OS2    = quickselect(x, n, n-K-1);

   // compute weights
   T a, b=0, c, d=0, dm=0, bm=0, r;

   for(int i=0; i<n; i++)
   {
      r = x[i];
      if(r < OS1) bm += 1;
      else if(r == OS1) b += 1;
      if(r < OS2) dm += 1;
      else if(r == OS2) d += 1;
   }

   a = b + bm - K;
   c = n - K - dm;
   w1 = a/b;
   w2 = c/d;

   */

   q1 = 0;
   q2 = 0;
   med = 0;

   OS1 = 0;
   OS2 = 1;

   if (OS1==OS2)
   {
      stats_.SetNextParam(region, x[0]);
   }
   else
   {
      for(int i=0; i<n; i++)
      {
         wt = 1.0; // Weighted(x[i], OS1, OS2, w1, w2);
         acc0(x[i], weight = w[i]);
         acc1(x[i]);
      } 

      OS1 = quantile(acc1, quantile_probability = 0.05);
      q1 = quantile(acc1, quantile_probability = 0.25);
      q2 = quantile(acc1, quantile_probability = 0.75);
      OS2 = quantile(acc1, quantile_probability = 0.95);
      med = median(acc0);

      p_mean = mean(acc0);
      p_std = sqrt(variance(acc0));

	   p_w_mean = weighted_mean(acc0);
      p_w_std = sqrt(weighted_variance(acc0));

      p_err = conf_factor * p_std / sqrt((double) n );

      stats_.SetNextParam(region, (T) p_mean, (T) p_w_mean, (T) p_std,  (T) p_w_std, med, q1, q2, OS1, OS2, (T) p_err, (T) p_err);

   }

   

}

#endif