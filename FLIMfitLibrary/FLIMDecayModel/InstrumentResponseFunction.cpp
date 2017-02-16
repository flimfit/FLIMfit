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

using std::max;
using std::min;

InstrumentResponseFunction::InstrumentResponseFunction() :
   image_irf(false),
   t0_image(nullptr),
   n_irf_rep(1),
   n_chan(1),
   variable_irf(false),
   type(Scatter),
   t0(0)
{
   irf = {0.0, 1.0, 0.0, 0.0};
   
   timebin_t0    = -1.0;
   timebin_width =  1.0;
}


void InstrumentResponseFunction::setIRF(int n_t, int n_chan_, double timebin_t0_, double timebin_width_, double* irf)
{
   n_chan       = n_chan_;
   n_irf_rep    = 1;
   image_irf    = false;
   t0_image     = NULL;
   variable_irf = false;

   timebin_t0    = timebin_t0_;
   timebin_width = timebin_width_; 

   copyIRF(n_t, irf);

   // Check normalisation of IRF
   for (int i = 0; i < n_chan; i++)
   {
      double sum = 0;
      for (int j = 0; j < n_t; j++)
         sum += irf[n_t * i + j];
      if(fabs(sum - 1.0) > 0.1)
         throw std::runtime_error("IRF is not correctly normalised");
   }

   calculateGFactor();
}

void InstrumentResponseFunction::setReferenceReconvolution(int ref_reconvolution, double ref_lifetime_guess)
{
   // TODO
//   this->ref_reconvolution = ref_reconvolution;
//   this->ref_lifetime_guess = ref_lifetime_guess;
}

double InstrumentResponseFunction::getT0()
{
   return timebin_t0 + t0;
}

double* InstrumentResponseFunction::getIRF(int irf_idx, double t0_shift, double* storage)
{
   if (image_irf)
      return irf.data() + irf_idx * n_irf * n_chan;

   if (t0_image)
      t0_shift = t0_image[irf_idx];

   if (t0_shift == 0.0)
      return irf.data();

   shiftIRF(t0_shift, storage);
   return storage;
}



void InstrumentResponseFunction::shiftIRF(double shift, double storage[])
{
   int i;

   shift = -shift;
   shift /= timebin_width;

   int c_shift = (int) floor(shift); 
   double f_shift = shift-c_shift;

   int start = max(0,1-c_shift);
   int end   = min(n_irf,n_irf-c_shift-3);

   start = min(start, n_irf-1);
   end   = max(end, 1);


   for(i=0; i<start; i++)
       storage[i] = irf[0];


   for(i=start; i<end; i++)
   {
      // will read y[0]...y[3]
      assert(i+c_shift-1 < (n_irf-3));
      assert(i+c_shift-1 >= 0);
      storage[i] = cubicInterpolate(irf.data()+i+c_shift-1,f_shift);
   }

   for(i=end; i<n_irf; i++)
      storage[i] = irf[n_irf-1];

}

void InstrumentResponseFunction::allocateBuffer(int n_irf_raw)
{
   n_irf = (int) ( ceil(n_irf_raw / 2.0) * 2 );
   int irf_size = n_irf * n_chan * n_irf_rep;
   
   irf.resize(irf_size);
}

void InstrumentResponseFunction::copyIRF(int n_irf_raw, double* irf_)
{
   // Copy IRF, padding to ensure we have an even number of points so we can 
   // use SSE primatives in convolution
   //------------------------------
   allocateBuffer(n_irf_raw);
      
   for(int j=0; j<n_irf_rep; j++)
   {
      int i;
      for(i=0; i<n_irf_raw; i++)
         for(int k=0; k<n_chan; k++)
             irf[(j*n_chan+k)*n_irf+i] = irf_[(j*n_chan+k)*n_irf_raw+i];
      for(; i<n_irf; i++)
         for(int k=0; k<n_chan; k++)
            irf[(j*n_chan+k)*n_irf+i] = irf_[(j*n_chan+k)*n_irf+i-1];
   }

}

/** 
 * Calculate g factor for polarisation resolved data
 *
 * g factor gives relative sensitivity of parallel and perpendicular channels, 
 * and so can be determined from the ratio of the IRF's for the two channels 
*/
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
