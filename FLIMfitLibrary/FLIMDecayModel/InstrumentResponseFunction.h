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

#include <boost/serialization/type_info_implementation.hpp>
#include <boost/serialization/shared_ptr.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/base_object.hpp>

#include "AlignedVectors.h"
#include "PixelIndex.h"
#include <vector>
#include <cmath>
#include <opencv2/core/core.hpp>

class AbstractConvolver;
class TransformedDataParameters;

class GaussianParameters
{
public:
   GaussianParameters(double mu = 1000, double sigma = 100, double offset = 0) :
      mu(mu), sigma(sigma), offset(offset)
   {}

   double mu;
   double sigma;
   double offset;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version)
   {
      ar & mu;
      ar & sigma;
      ar & offset;
   }
};

class InstrumentResponseFunction
{
public:

   virtual std::shared_ptr<AbstractConvolver> getConvolver(std::shared_ptr <TransformedDataParameters> dp) { return nullptr; };

   void setFrameT0(const std::vector<double>& frame_t0);
   void setSpatialT0(const cv::Mat& spatial_t0);

   virtual bool isSpatiallyVariant();
   virtual bool arePositionsEquivalent(PixelIndex idx1, PixelIndex idx2);
   int getNumChan();

   virtual double calculateMean() { return 0; };

   void setGFactor(const std::vector<double>& g_factor);
   std::vector<double>& getGFactor() { return g_factor; };

   double getT0Shift(PixelIndex irf_idx);

   virtual bool usingReferenceReconvolution() { return false; }

protected:

   std::vector<double> g_factor = { 1.0 };
   int n_chan = 1;

   bool spatially_varying_t0 = false;
   cv::Mat spatial_t0;

   bool frame_varying_t0 = false;
   std::vector<double> frame_t0;


   template<class Archive>
   void serialize(Archive & ar, const unsigned int version)
   {
      if (version >= 6)
      {
         ar & g_factor;
         ar & n_chan;
         ar & spatially_varying_t0;
         ar & spatial_t0;
         ar & frame_varying_t0;
         ar & frame_t0;
      }
      else
      {
         double timebin_width, timebin_t0, polarisation_angle;
         int n_irf, n_chan, n_irf_rep;
         int type;
         aligned_vector<double> irf;
         std::vector<GaussianParameters> gaussian_params;
         
         // To support loading older formats
         ar & timebin_width;
         ar & timebin_t0;
         if (version < 5)
         {
            bool variable_irf;
            ar & variable_irf;
         }
         ar & n_irf;
         ar & n_chan;
         ar & n_irf_rep;

         if (version >= 4)
         {
            ar & g_factor;
         }
         else if (Archive::is_loading::value)
         {
            double g;
            ar & g;
            g_factor.resize(n_chan, 1.0);
         }

         ar & type;
         ar & irf;

         if (version >= 2)
            ar & gaussian_params;
         if (version >= 3)
            ar & polarisation_angle;
      }

   }

   friend class boost::serialization::access;
};

BOOST_CLASS_VERSION(InstrumentResponseFunction, 6)
BOOST_CLASS_TRACKING(InstrumentResponseFunction, track_always)