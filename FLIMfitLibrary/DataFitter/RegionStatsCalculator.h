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
// but WITHOUfloat ANY WARRANTY; without even the implied warranty of
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

#pragma once 
#include "util.h"

#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics.hpp>
#include <boost/accumulators/statistics/mean.hpp>
#include <boost/accumulators/statistics/variance.hpp>
#include <boost/accumulators/statistics/weighted_mean.hpp>
#include <boost/accumulators/statistics/weighted_variance.hpp>
#include <boost/accumulators/statistics/tail_quantile.hpp>
#include <boost/accumulators/statistics/median.hpp>
#include <boost/accumulators/statistics/weighted_sum_kahan.hpp>
#include <boost/math/special_functions/fpclassify.hpp>

#include <limits>
#include <vector>


typedef std::vector<float>::const_iterator const_float_iterator;
typedef std::vector<float>::iterator float_iterator;

class RegionStatsCalculator
{
public:
   RegionStatsCalculator(float confidence_factor) :
      confidence_factor(confidence_factor)
   {
   }

   template <typename T>
   void computeStatistics(const_float_iterator x, const_float_iterator w, int n, int K, float conf_factor, RegionStats<T>& stats_, int region)
   {
      using namespace boost::accumulators;

      accumulator_set< T, stats< tag::mean, tag::variance, tag::median > > acc00;
      accumulator_set< T, stats< tag::weighted_mean, tag::weighted_variance >, float > acc0;
      accumulator_set< T, stats< tag::tail_quantile<left>, tag::tail_quantile<right> > > acc1(tag::tail<left>::cache_size = n, tag::tail<right>::cache_size = n);

      if (n == 0)
      {
         double nan = std::numeric_limits<double>::quiet_NaN();
         stats_.SetNextParam(region, nan);
         return;
      }

      for (int i = 0; i < n; i++)
      {
         acc0(x[i], weight = w[i]);
         acc00(x[i]);
         acc1(x[i]);
      }

      float OS1 = quantile(acc1, quantile_probability = 0.05);
      float q1 = quantile(acc1, quantile_probability = 0.25);
      float q2 = quantile(acc1, quantile_probability = 0.75);
      float OS2 = quantile(acc1, quantile_probability = 0.95);

      float p_median = median(acc00);
      float p_mean = mean(acc00);
      float p_std = sqrt(variance(acc00));

      float p_w_mean = weighted_mean(acc0);
      float p_w_std = sqrt(weighted_variance(acc0));

      float p_err = conf_factor * p_std / sqrt((double)n);

      stats_.SetNextParam(region, p_mean, p_w_mean, p_std, p_w_std, p_median, q1, q2, OS1, OS2, p_err, p_err);

   }


   void CalculateRegionStats(int region_size, const_float_iterator data, int data_stride, const_float_iterator intensity, int intensity_stride, RegionStats<float>& stats, int region)
   {
      if (buf.size() < region_size)
      {
         buf.resize(region_size);
         I_buf.resize(region_size);
      }

      int idx = 0;
      for (int j = 0; j < region_size; j++)
      {
         // Only include finite numbers
         float data_ij = data[j * data_stride];
         float intensity_ij = intensity[j*intensity_stride];
         if (boost::math::isfinite(intensity_ij) && boost::math::isfinite(data_ij * data_ij))
         {
            buf[idx] = data_ij;
            I_buf[idx] = intensity_ij;
            idx++;
         }
      }
      int K = int(0.05 * idx);
      computeStatistics(buf.begin(), I_buf.begin(), idx, K, confidence_factor, stats, region);
   }

private:

   float confidence_factor;

   std::vector<float> buf; 
   std::vector<float> I_buf;
};
