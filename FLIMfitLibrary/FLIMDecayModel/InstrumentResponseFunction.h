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


#include <boost/align/aligned_allocator.hpp>
#include <boost/serialization/base_object.hpp>
#include <boost/serialization/version.hpp>
#include <vector>
 
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

enum IRFType
{
   Scatter,
   Reference,
   Gaussian
};

class InstrumentResponseFunction
{
public:
   InstrumentResponseFunction();

   void setIRF(int n_t, int n_chan, double timebin_t0, double timebin_width, double* irf);
   void setImageIRF(int n_t, int n_chan, int n_irf_rep, double timebin_t0, double timebin_width, double* irf);
   void setGaussianIRF(std::vector<GaussianParameters> gaussian_params);

   void setIRFShiftMap(double* t0);
   void setReferenceReconvolution(int ref_reconvolution, double ref_lifetime_guess);

   double* getIRF(int irf_idx, double t0_shift, double* storage);
   double getT0();

   bool isGaussian() { return type == Gaussian; }

   int getNumChan();

   double timebin_width;
   double timebin_t0;

   bool variable_irf;

   int n_irf;
   int n_irf_rep;

   double g_factor;

   std::vector<GaussianParameters> gaussian_params;
   
   IRFType type; 

private:
   void copyIRF(int n_irf_raw, double* irf);
   void shiftIRF(double shift, double storage[]);
   double calculateGFactor();

   void allocateBuffer(int n_irf_raw);

   static double cubicInterpolate(double  y[], double mu);

   std::vector<double, boost::alignment::aligned_allocator<double, 16> > irf;
   
   int     image_irf;
   double* t0_image;

   double t0;
   int n_chan;

   
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version)
   {
      ar & timebin_width;
      ar & timebin_t0;
      ar & variable_irf;
      ar & n_irf;
      ar & n_chan;
      ar & n_irf_rep;
      ar & g_factor;
      ar & type;
      ar & irf;

      if (version >= 2)
         ar & gaussian_params;
   }
   
   friend class boost::serialization::access;
   
};

BOOST_CLASS_VERSION(InstrumentResponseFunction, 2)