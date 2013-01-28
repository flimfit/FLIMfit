//=========================================================================
//  
//  ImageStats.h
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//  Provides convenience class for handling image statistics
//
//=========================================================================

#ifndef IMAGE_STATS_H
#define IMAGE_STATS_H

/**
 * Convenience class to encapsulate returned results for a dataset
 */

template<typename T>
class ImageStats
{
public:

   ImageStats(T* params_mean, T* params_std, T* params_median, T* params_q1, T* params_q2, T* params_01, T* params_99, T* params_w_mean, T* params_w_std) :
                 idx(0), n_im(n_im), params_mean(params_mean), params_std(params_std), params_median(params_median), params_q1(params_q1),  
                 params_q2(params_q2), params_01(params_01), params_99(params_99), params_w_mean(params_w_mean), params_w_std(params_w_std)
   {};

   /**
    * Set the next parameter statistics to specified values
    */ 
   void SetNextParam(T mean, T std, T median, T q1, T q2, T p01, T p99, T w_mean, T w_std)
   {

      params_mean[idx] = mean; 
      params_std[idx] = std; 
      params_median[idx] = median; 
      params_q1[idx] = q1; 
      params_q2[idx] = q2; 
      params_01[idx] = p01; 
      params_99[idx] = p99; 

      params_w_mean[idx] = w_mean; 
      params_w_std[idx] = w_std; 

      idx++;
   }

   /**
    * Set the next parameter to @mean, parameter has no variance 
    */
   void SetNextParam(T mean)
   {

      params_mean[idx] = mean; 
      params_std[idx] = 0; 
      params_median[idx] = mean; 
      params_q1[idx] = mean; 
      params_q2[idx] = mean; 
      params_01[idx] = 0.99f*mean;  // These parameters are used for setting inital limits 
      params_99[idx] = 1.01f*mean;  // so must be different to mean for correct display

      params_w_mean[idx] = mean; 
      params_w_std[idx] = 0; 

      idx++;
   }

private:

   T* params_mean;
   T* params_std; 
   T* params_median;
   T* params_q1;
   T* params_q2;
   T* params_01;
   T* params_99;

   T* params_w_mean;
   T* params_w_std; 

   int idx;
   int n_im;
};

#endif