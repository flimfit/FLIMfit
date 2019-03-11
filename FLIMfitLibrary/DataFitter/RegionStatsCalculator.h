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
#include <boost/math/special_functions/erf.hpp>

#include <limits>
#include <vector>


typedef std::vector<float>::const_iterator const_float_iterator;
typedef std::vector<float>::iterator float_iterator;

static float sqrt2 = 1.41421356237f;
static float sqrt2pi = 2.50662827463f;

class RegionStatsCalculator
{
public:

   RegionStatsCalculator(float confidence_factor) :
      confidence_factor(confidence_factor)
   {
   }

   void calculateRegionStats(int region_size, const_float_iterator x, int x_stride, const_float_iterator w, int w_stride, RegionStats<float>& stats_, int region, bool truncated = false)
   {
      truncated = false;

      using namespace boost::accumulators;
      using namespace boost::math;

      accumulator_set< float, stats< tag::mean, tag::variance, tag::median > > acc;
      accumulator_set< float, stats< tag::weighted_mean, tag::weighted_variance >, float > acc_w;
      accumulator_set< float, stats< tag::tail_quantile<left>, tag::tail_quantile<right> > > acc_q(tag::tail<left>::cache_size = region_size, tag::tail<right>::cache_size = region_size);
      accumulator_set< float, stats< tag::mean > > acc_pos, acc_pos_sq;

      if (region_size == 0)
      {
         double nan = std::numeric_limits<double>::quiet_NaN();
         stats_.SetNextParam(region, nan);
         return;
      }

      int n0 = 0, n = 0;
      for (int i = 0; i < region_size; i++)
      {
         double xi = x[i*x_stride];
         double wi = w[i*w_stride];

         if (std::isfinite(wi) && std::isfinite(xi * xi))
         {
            acc_w(xi, weight = wi);
            acc(xi);
            acc_q(xi);

            if (truncated && (xi > 0))
            {
               acc_pos(xi);
               acc_pos_sq(xi * xi);
               n0++;
            }
            
            n++;
         }
      }

      float OS1 = quantile(acc_q, quantile_probability = 0.05);
      float q1 = quantile(acc_q, quantile_probability = 0.25);
      float q2 = quantile(acc_q, quantile_probability = 0.75);
      float OS2 = quantile(acc_q, quantile_probability = 0.95);

      float p_median = median(acc);
      float p_mean = mean(acc);
      float p_std = sqrt(variance(acc));

      float p_w_mean = weighted_mean(acc_w);
      float p_w_std = sqrt(weighted_variance(acc_w));

      float p_err = confidence_factor * p_std / sqrt((double)n);

      if (truncated)
      {
         // Estimate mean and variance of a truncated distribution
         // Cohen, A. (1949).On Estimating the Mean and Standard Deviation of
         // Truncated Normal Distributions.Journal of the American Statistical
         // Association, 44(248), 518 - 525. doi:10.2307 / 2279903

         int n1 = n - n0;

         if ((n1 > 0) & (n0 > 0))
         {
            float nu1 = mean(acc_pos);
            float nu2 = mean(acc_pos_sq);

            float xi = sqrt2 * erfc_inv((2.0f * n0) / (n1 + n0));
            float Y1;

            for (int i = 0; i < 3; i++)
            {
               float phi = exp(-xi * xi*0.5) / sqrt2pi;
               float I0 = 0.5*erfc(xi / sqrt2);
               Y1 = (n1 * phi) / (n0 * (1 - I0));
               
               float g1 = xi - Y1;
               float g2 = Y1 * phi / (1 - I0) + xi * Y1 + 1;
               float sa = (g1 * g1 * nu2 / (nu1 * nu1) - xi * g1 - 1) / (2 * g2 / g1 - g1 + g2 * xi);
               xi -= sa;
            }

            p_std = nu1 / (Y1 - xi);
            p_mean = std::max(0.0f, -p_std * xi);
         }
      }

      stats_.SetNextParam(region, p_mean, p_w_mean, p_std, p_w_std, p_median, q1, q2, OS1, OS2, p_err, p_err);
   }

private:

   float confidence_factor;
};
