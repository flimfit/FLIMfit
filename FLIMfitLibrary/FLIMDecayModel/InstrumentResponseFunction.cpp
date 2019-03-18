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

#include "InstrumentResponseFunction.h"

#include <algorithm>
#include <cmath>
#include <cassert>

void InstrumentResponseFunction::setGFactor(const std::vector<double>& g_factor_)
{
   if (g_factor_.size() != n_chan)
      throw std::runtime_error("Unexpected number of g_factor channels");

   g_factor = g_factor_;
}

int InstrumentResponseFunction::getNumChan()
{
   return n_chan;
}

bool InstrumentResponseFunction::isSpatiallyVariant()
{
   return spatially_varying_t0 || frame_varying_t0;
}

void InstrumentResponseFunction::setFrameT0(const std::vector<double>& frame_t0_)
{
   frame_varying_t0 = true;
   frame_t0 = frame_t0_;
}

void InstrumentResponseFunction::setSpatialT0(const cv::Mat& spatial_t0_)
{
   spatially_varying_t0 = true;
   spatial_t0 = spatial_t0_;
}

bool InstrumentResponseFunction::arePositionsEquivalent(PixelIndex idx1, PixelIndex idx2)
{
   return ((!frame_varying_t0) || (idx1.image == idx2.image)) &&
          ((!spatially_varying_t0) || (idx1.pixel == idx2.pixel));
}

double InstrumentResponseFunction::getT0Shift(PixelIndex irf_idx)
{
   double t0_shift = 0;

   if (spatially_varying_t0)
      t0_shift += spatial_t0.at<double>(irf_idx.pixel);

   if (frame_varying_t0)
      t0_shift += frame_t0[irf_idx.image];

   return t0_shift;
}