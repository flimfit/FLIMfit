//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

#ifndef IMAGE_STATS_H
#define IMAGE_STATS_H

#include "util.h"
#include "FlagDefinitions.h"

/**
 * Convenience class to encapsulate returned results for a dataset
 */

template<typename T>
class ImageStats
{
public:

   ImageStats(int n_regions = 0, int n_params = 0) :
      n_regions(n_regions),
      n_params(n_params)
   {
      SetSize(n_regions, n_params);
   }

   void SetSize(int n_regions, int n_params)
   {
      params.resize(n_regions * n_params * N_STATS);
      param_idx.resize(n_regions);

      for(int i=0; i<n_regions; i++)
         param_idx[i] = 0;
   };

   int GetNumStats() { return N_STATS; }
   int GetNumParams() { return n_params; }
   vector<T>& GetStats() { return params; }

   /**
    * Set the next parameter statistics to specified values
    */ 
   void SetNextParam(int region, T mean, T w_mean, T std, T w_std, T median, T q1, T q2, T p01, T p99, T err_lower, T err_upper )
   {
      _ASSERT( param_idx[region] < n_params );

      T* next_param = params.data() + region * n_params * N_STATS + param_idx[region] * N_STATS;

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

      T* next_param = params.data() + region * n_params * N_STATS + param_idx[region] * N_STATS;

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

      T* next_param = params.data() + region * n_params * N_STATS + param_idx[region] * N_STATS;

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
   std::vector<int> param_idx;
   std::vector<T> params;

};

#endif