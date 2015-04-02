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

#pragma once 
#include "ImageStats.h"
#include "TrimmedMean.h"

#include <vector>
#include <boost/math/special_functions/fpclassify.hpp>

class RegionStatsCalculator
{
public:
   RegionStatsCalculator( int intensity_stride, float confidence_factor) :
      intensity_stride(intensity_stride),
      confidence_factor(confidence_factor)
   {
   }

   int CalculateRegionStats(int n_parameters, int region_size, const float* data, float intensity[], ImageStats<float>& stats, int region)
   {
      if (buf.size() < region_size)
      {
         buf.resize(region_size);
         I_buf.resize(region_size);
      }

      for (int i = 0; i<n_parameters; i++)
      {
         int idx = 0;
         for (int j = 0; j<region_size; j++)
         {
            // Only include finite numbers
            float data_ij = data[i + j*n_parameters];
            if (boost::math::isfinite(data_ij) && boost::math::isfinite(data_ij * data_ij))
            {
               buf[idx] = data_ij;
               I_buf[idx] = intensity[i + j*intensity_stride];
               idx++;
            }
         }
         int K = int(0.05 * idx);
         TrimmedMean(buf.data(), intensity, idx, K, confidence_factor, stats, region);
      }

      return n_parameters;
   }

private:

   int intensity_stride;
   float confidence_factor;

   std::vector<float> buf; 
   std::vector<float> I_buf;
};
