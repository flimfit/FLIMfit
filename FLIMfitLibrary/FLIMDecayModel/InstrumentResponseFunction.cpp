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

InstrumentResponseFunction::InstrumentResponseFunction() :
   spatially_varying_t0(false),
   frame_varying_t0(false),
   n_irf_rep(1),
   n_chan(1),
   type(Scatter),
   full_image_irf(false)
{
   irf = {0.0, 1.0, 0.0, 0.0};
   
   timebin_t0    = -1.0;
   timebin_width =  1.0;
}


void InstrumentResponseFunction::setGaussianIRF(const std::vector<GaussianParameters>& gaussian_params_)
{
   gaussian_params = gaussian_params_;
   type = Gaussian;

   n_chan = (int) gaussian_params.size();
   g_factor.resize(n_chan);
}

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

void InstrumentResponseFunction::setReferenceReconvolution(int ref_reconvolution, double ref_lifetime_guess)
{ 
   // TODO
//   this->ref_reconvolution = ref_reconvolution;
//   this->ref_lifetime_guess = ref_lifetime_guess;
}

bool InstrumentResponseFunction::isSpatiallyVariant()
{
   return spatially_varying_t0 || frame_varying_t0 || full_image_irf;
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

double InstrumentResponseFunction::getT0Shift(PixelIndex irf_idx)
{
   double t0_shift = 0;

   if (spatially_varying_t0)
      t0_shift += spatial_t0.at<double>(irf_idx.pixel);

   if (frame_varying_t0)
      t0_shift += frame_t0[irf_idx.image];

   return t0_shift;
}

bool InstrumentResponseFunction::arePositionsEquivalent(PixelIndex idx1, PixelIndex idx2)
{
   return (!full_image_irf) &&
          ((!frame_varying_t0) || (idx1.image == idx2.image)) &&
          ((!spatially_varying_t0) || (idx1.pixel == idx2.pixel));
}


double_iterator InstrumentResponseFunction::getIRF(PixelIndex irf_idx, double t0_shift, double_iterator storage)
{
   if (full_image_irf)
      return irf.begin() + irf_idx.pixel * n_irf * n_chan;

   t0_shift += getT0Shift(irf_idx);

   if (t0_shift == 0.0)
      return irf.begin();

   shiftIRF(t0_shift, storage);
   return storage;
}



void InstrumentResponseFunction::shiftIRF(double shift, double_iterator storage)
{
   int i;

   shift = -shift;
   shift /= timebin_width;

   int c_shift = (int) floor(shift); 
   double f_shift = shift-c_shift;

   int start = std::max(0,1-c_shift);
   int end = std::min(n_irf,n_irf-c_shift-3);

   start = std::min(start, n_irf-1);
   end = std::max(end, 1);

   for (int c = 0; c < n_chan; c++)
   {
      int offset = n_irf * c;
      for (i = 0; i<start; i++)
         storage[i + offset] = irf[offset];


      for (i = start; i<end; i++)
      {
         // will read y[0]...y[3]
         assert(i + c_shift - 1 < (n_irf - 3));
         assert(i + c_shift - 1 >= 0);
         storage[i + offset] = cubicInterpolate(irf.data() + i + c_shift - 1 + offset, f_shift);
      }

      for (i = end; i<n_irf; i++)
         storage[i + offset] = irf[n_irf - 1 + offset];
   }

}

void InstrumentResponseFunction::allocateBuffer(int n_irf_raw)
{
   n_irf = (int) ( ceil(n_irf_raw / 2.0) * 2 );
   int irf_size = n_irf * n_chan * n_irf_rep;
   
   irf.resize(irf_size);
}


/** 
 * Calculate g factor for polarisation resolved data
 *
 * g factor gives relative sensitivity of parallel and perpendicular channels, 
 * and so can be determined from the ratio of the IRF's for the two channels 
*/
/*
double InstrumentResponseFunction::calculateGFactor()
{

   if (n_chan == 2)
   {
      double perp = 0;
      double para = 0;
      for(int i=0; i<n_irf; i++)
      {
         para += irf[i];
         perp += irf[i+n_irf];
      }

      g_factor = para / perp;
   }
   else
   {
      g_factor = 1;
   }

   return g_factor;
}
*/

// http://paulbourke.net/miscellaneous/interpolation/
double InstrumentResponseFunction::cubicInterpolate(double  y[], double mu)
{
   // mu - distance between y1 and y2
   double a0,a1,a2,a3,mu2;

   mu2 = mu*mu;
   a0 = -0.5*y[0] + 1.5*y[1] - 1.5*y[2] + 0.5*y[3];
   a1 = y[0] - 2.5*y[1] + 2*y[2] - 0.5*y[3];
   a2 = -0.5*y[0] + 0.5*y[2];
   a3 = y[1];

   return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}
