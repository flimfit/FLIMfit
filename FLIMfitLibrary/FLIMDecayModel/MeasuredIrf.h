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


#include "InstrumentResponseFunction.h"

class AbstractConvolver;
class TransformedDataParameters;

class MeasuredIrf : public InstrumentResponseFunction
{
public:

   MeasuredIrf();

   double calculateMean();

   std::shared_ptr<AbstractConvolver> getConvolver(std::shared_ptr<TransformedDataParameters> dp);

   template<typename it>
   void setIrf(int n_t, int n_chan, double timebin_t0, double timebin_width, it irf);

   bool isSpatiallyVariant();
   bool arePositionsEquivalent(PixelIndex idx1, PixelIndex idx2);

   void setImageIRF(int n_t, int n_chan, int n_irf_rep, double timebin_t0, double timebin_width, double_iterator irf); //TODO

   void setReferenceReconvolution(bool ref_reconvolution, double ref_lifetime_guess);

   virtual bool usingReferenceReconvolution() { return reference_reconvolution; }


   double_iterator getIrf(PixelIndex irf_idx, double t0_shift, double_iterator storage);

   double getT0() { return timebin_t0; }


   double timebin_width;
   double timebin_t0;
   bool reference_reconvolution = false;

   int n_irf;
   int n_irf_rep;

private:
   template<typename it>
   void copyIrf(int n_irf_raw, it irf);

   void shiftIrf(double shift, double_iterator storage);
   //double calculateGFactor();

   void allocateBuffer(int n_irf_raw);

   static double cubicInterpolate(double  y[], double mu);

   aligned_vector<double> irf;

   bool full_image_irf;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version)
   {
      // TODO
   }

};

template<typename it>
void MeasuredIrf::setIrf(int n_t, int n_chan_, double timebin_t0_, double timebin_width_, it irf)
{
   n_chan = n_chan_;
   n_irf_rep = 1;
   full_image_irf = false;
   spatially_varying_t0 = false;
   frame_varying_t0 = false;

   timebin_t0 = timebin_t0_;
   timebin_width = timebin_width_;

   copyIrf(n_t, irf);

   // Check normalisation of IRF
   for (int i = 0; i < n_chan; i++)
   {
      double sum = 0;
      for (int j = 0; j < n_t; j++)
         sum += irf[n_t * i + j];
      if (std::fabs(sum - 1.0) > 0.1)
         throw std::runtime_error("IRF is not correctly normalised");
   }

   g_factor.assign(n_chan, 1.0);

   //calculateGFactor();
}

template<typename it>
void MeasuredIrf::copyIrf(int n_irf_raw, it irf_)
{
   // Copy IRF, padding to ensure we have an even number of points so we can 
   // use SSE primatives in convolution
   //------------------------------
   allocateBuffer(n_irf_raw);

   for (int j = 0; j < n_irf_rep; j++)
   {
      int i;
      for (i = 0; i < n_irf_raw; i++)
         for (int k = 0; k < n_chan; k++)
            irf[(j*n_chan + k)*n_irf + i] = irf_[(j*n_chan + k)*n_irf_raw + i];
      for (; i < n_irf; i++)
         for (int k = 0; k < n_chan; k++)
            irf[(j*n_chan + k)*n_irf + i] = 0;
   }

}

BOOST_CLASS_VERSION(MeasuredIrf, 1)
