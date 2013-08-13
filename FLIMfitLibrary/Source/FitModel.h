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

#include <vector>
#include <string>

using namespace std;

class FitModel
{
   public: 

      int l; 
      int lmax;
      int nl;
      
      int n; 
      
      int p; 
      
      int n_output_params;
      int n_nl_output_params;
      const char** param_names_ptr;
      vector<string> param_names;

      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int CalculateModel(double *a, int adim, double *b, int bdim, double *kap, const double *alf, int irf_idx, int isel, int thread) = 0;
      virtual void GetWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread) = 0;
      virtual float* GetConstantAdjustment() = 0;
      virtual void SetInitialParameters(double param[], double mean_arrival_time) = 0;

      virtual void NormaliseLinearParams(volatile float lin_params[], volatile float norm_params[]) = 0;
      virtual void DenormaliseLinearParams(volatile float norm_params[], volatile float lin_params[]) = 0;

      virtual int ProcessNonLinearParams(float alf[], float alf_err_lower[], float alf_err_upper[], float param[], float err_lower[], float err_upper[]) = 0;
      virtual float GetNonLinearParam(int param, float alf[]) = 0;


};

#endif