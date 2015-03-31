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

#include <boost\math\special_functions\fpclassify.hpp>
#include "util.h"
#include "FlagDefinitions.h"

/**
 * Convenience class to encapsulate returned results for a dataset
 */

template<typename T>
class ImageStats
{
public:

   ImageStats(int n_regions, int n_params, T* params) :
      n_regions(n_regions),   
      n_params(n_params),
      params(params)
   {
      param_idx = new int[n_regions];

      for(int i=0; i<n_regions; i++)
         param_idx[i] = 0;
   };

   ~ImageStats()
   {
      delete[] param_idx;
   }


   /**
    * Set the next parameter statistics to specified values
    */ 
   void SetNextParam(int region, T mean, T w_mean, T std, T w_std, T median, T q1, T q2, T p01, T p99, T err_lower, T err_upper )
   {
      _ASSERT( param_idx[region] < n_params );

      T* next_param = params + region * n_params * N_STATS + param_idx[region] * N_STATS;

      next_param[PARAM_MEAN] = mean; 
      next_param[PARAM_W_MEAN] = w_mean; 
      next_param[PARAM_STD] = std; 
      next_param[PARAM_W_STD] = w_std; 
      next_param[PARAM_MEDIAN] = median; 
      next_param[PARAM_Q1] = q1; 
      next_param[PARAM_Q2] = q2; 
      next_param[PARAM_01] = p01; 
      next_param[PARAM_99] = p99; 

      next_param[PARAM_ERR_LOWER] = err_lower;
      next_param[PARAM_ERR_UPPER] = err_upper;

      param_idx[region]++;

   }

   /**
    * Set the next parameter to @mean, parameter has no variance 
    */
   void SetNextParam(int region, T mean)
   {
      assert( param_idx[region] < n_params );

      T* next_param = params + region * n_params * N_STATS + param_idx[region] * N_STATS;

      next_param[PARAM_MEAN] = mean; 
      next_param[PARAM_W_MEAN] = mean; 
      next_param[PARAM_STD] = (T) FP_NAN; 
      next_param[PARAM_W_STD] = (T) FP_NAN; 
      next_param[PARAM_MEDIAN] = mean; 
      next_param[PARAM_Q1] = mean; 
      next_param[PARAM_Q2] = mean; 
      next_param[PARAM_01] = 0.99f*mean;  // These parameters are used for setting inital limits 
      next_param[PARAM_99] = 1.01f*mean;  // so must be different to mean for correct display

      next_param[PARAM_ERR_LOWER] = (T) FP_NAN;
      next_param[PARAM_ERR_UPPER] = (T) FP_NAN;

      param_idx[region]++;

   }

   /**
    * Set the next parameter to @mean, parameter has no variance 
    */
   void SetNextParam(int region, T mean, T err_lower, T err_upper)
   {
      _ASSERT( param_idx[region] < n_params );

      T* next_param = params + region * n_params * N_STATS + param_idx[region] * N_STATS;

      next_param[PARAM_MEAN] = mean; 
      next_param[PARAM_W_MEAN] = mean; 
      next_param[PARAM_STD] = (T) FP_NAN; 
      next_param[PARAM_W_STD] = (T) FP_NAN; 
      next_param[PARAM_MEDIAN] = mean; 
      next_param[PARAM_Q1] = mean; 
      next_param[PARAM_Q2] = mean; 
      next_param[PARAM_01] = 0.99f*mean;  // These parameters are used for setting inital limits 
      next_param[PARAM_99] = 1.01f*mean;  // so must be different to mean for correct display

      next_param[PARAM_ERR_LOWER] = err_lower;
      next_param[PARAM_ERR_UPPER] = err_upper;

      param_idx[region]++;

   }

private:

   int n_regions;
   int n_params;
   int* param_idx;

   T* params;

};

#endif