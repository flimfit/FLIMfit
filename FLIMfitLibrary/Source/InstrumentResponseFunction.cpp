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
#include "util.h"

using std::max;
using std::min;

InstrumentResponseFunction::InstrumentResponseFunction() :
   image_irf(false),
   t0_image(false),
   n_irf_rep(1),
   t_irf_buf(NULL),
   irf_buf(NULL),
   variable_irf(false)
{
   int n_irf_    = 4;

   AllocateBuffer(n_irf_);

   t_irf_buf[0] = -2.0;
   t_irf_buf[1] =  0.0;
   t_irf_buf[3] =  2.0;
   t_irf_buf[0] =  4.0;

   irf_buf[0] = 0.0; 
   irf_buf[1] = 1.0; 
   irf_buf[2] = 0.0; 
   irf_buf[3] = 0.0; 
}
   
InstrumentResponseFunction::~InstrumentResponseFunction()
{
   FreeBuffer();
}

void InstrumentResponseFunction::FreeBuffer()
{
   AlignedClearVariable(t_irf_buf);
   AlignedClearVariable(irf_buf);
}

void InstrumentResponseFunction::SetIRF(int n_t, int n_chan_, double* t_irf, double* irf)
{
   n_chan       = n_chan_;
   n_irf_rep    = 1;
   image_irf    = false;
   t0_image     = false;
   variable_irf = false;

   CopyIRF(n_t, t_irf, irf);
   CalculateTimebinWidth();
}

void InstrumentResponseFunction::CalculateTimebinWidth()
{
   if (n_irf > 2)
      timebin_width = t_irf_buf[1] - t_irf_buf[0];
   else
      timebin_width = 1;

}

double* InstrumentResponseFunction::GetIRF(int irf_idx, double* storage)
{

   if (image_irf)
      return irf_buf + irf_idx * n_irf * n_chan;
   else if (t0_image)
   {
      ShiftIRF(t0_image[irf_idx], storage);
      return storage;
   }
   else
      return irf_buf;

}



void InstrumentResponseFunction::ShiftIRF(double shift, double storage[])
{
   int i;

   shift /= timebin_width;

   int c_shift = (int) floor(shift); 
   double f_shift = shift-c_shift;

   int start = max(0,-c_shift)+1;
   int end   = min(n_irf-1,n_irf-c_shift)-1;

   for(i=0; i<start; i++)
      storage[i] = irf_buf[0];

   for(i=start; i<n_irf; i++)
      storage[i] = CubicInterpolate(irf_buf+i+c_shift-1,f_shift);

   for(i=end; i<n_irf; i++)
      storage[i] = irf_buf[n_irf-1];

}

void InstrumentResponseFunction::AllocateBuffer(int n_irf_raw)
{
   FreeBuffer();

   int n_irf = (int) ( ceil(n_irf_raw / 2.0) * 2 );
   int irf_size = n_irf * n_chan * n_irf_rep;
   
   AlignedAllocate(irf_size, irf_buf);
   AlignedAllocate(n_irf,    t_irf_buf);
/*
#ifdef _WINDOWS
      irf_buf   = (double*) _aligned_malloc(irf_size*sizeof(double), 16);
      t_irf_buf = (double*) _aligned_malloc(n_irf*sizeof(double), 16);
   #else
      irf_buf  = new double[irf_size]; 
      t_irf_buf  = new double[a_n_irf]; 
   #endif
   */
}

void InstrumentResponseFunction::CopyIRF(int n_irf_raw, double* t_irf, double* irf)
{
   // Copy IRF, padding to ensure we have an even number of points so we can 
   // use SSE primatives in convolution
   //------------------------------


   AllocateBuffer(n_irf_raw);
      
   double dt = t_irf[1]-t_irf[0];

   for(int j=0; j<n_irf_rep; j++)
   {
      int i;
      for(i=0; i<n_irf_raw; i++)
      {
         t_irf_buf[i] = t_irf[i];
         for(int k=0; k<n_chan; k++)
             irf_buf[(j*n_chan+k)*n_irf+i] = irf[(j*n_chan+k)*n_irf_raw+i];
      }
      for(; i<n_irf; i++)
      {
         t_irf_buf[i] = t_irf_buf[i-1] + dt;
         for(int k=0; k<n_chan; k++)
            irf_buf[(j*n_chan+k)*n_irf+i] = irf_buf[(j*n_chan+k)*n_irf+i-1];
      }
   }

}

/** 
 * Calculate g factor for polarisation resolved data
 *
 * g factor gives relative sensitivity of parallel and perpendicular channels, 
 * and so can be determined from the ratio of the IRF's for the two channels 
*/
double InstrumentResponseFunction::CalculateGFactor()
{
   int g_factor; 

   if (n_chan == 2)
   {
      double perp = 0;
      double para = 0;
      for(int i=0; i<n_irf; i++)
      {
         para += irf_buf[i];
         perp += irf_buf[i+n_irf];
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
double InstrumentResponseFunction::CubicInterpolate(double  y[], double mu)
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
