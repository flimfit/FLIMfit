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

#ifndef _FITMODEL_H
#define _FITMODEL_H

class FitModel
{
   public: 

      int l; 
      int nl;
      
      int n; 
      int nmax; 
      int ndim; 
      
      int p; 
      
      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int CalculateModel(double *a, double *b, double *kap, const double *alf, int irf_idx, int isel, int thread) = 0;
      virtual void GetWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread) = 0;
      virtual float* GetConstantAdjustment() = 0;
      virtual void SetInitialParameters(double param[], double mean_arrival_time) = 0;

};

#endif