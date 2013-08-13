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

#ifndef _IRF_H
#define _IRF_H

class InstrumentResponseFunction
{
public:
   InstrumentResponseFunction();
   ~InstrumentResponseFunction();

   void SetIRF(int n_t, int n_chan, double* t_irf, double* irf);
   void SetImageIRF(int n_t, int n_chan, int n_irf_rep, double t_irf, double* irf);
   void SetIRFShiftMap(double* t0);
   double CalculateGFactor();

   double timebin_width;

   bool variable_irf;

   int n_irf;
   int n_chan;
   int n_irf_rep;

   double g_factor;

   double* irf_buf;
   double* t_irf_buf;

   double* GetIRF(int irf_idx, double* storage);

private:
   void CopyIRF(int n_irf_raw, double* t_irf, double* irf);
   void ShiftIRF(double shift, double storage[]);

   void AllocateBuffer(int n_irf_raw);
   void FreeBuffer();

   void CalculateTimebinWidth();
   static double CubicInterpolate(double  y[], double mu);


   int     image_irf;
   double* t0_image;

};

#endif