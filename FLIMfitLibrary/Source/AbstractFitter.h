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

#ifndef _ABSTRACTFITTER_H
#define _ABSTRACTFITTER_H

#include "FitModel.h"
#include "FitResults.h"
#include "RegionData.h"
#include "FlagDefinitions.h"

#include "omp_stub.h"
#include "levmar.h"

#include <boost/ptr_container/ptr_vector.hpp>

#include <cstdio>

using namespace boost;

template <class T>
class AbstractFitter
{
public:


   AbstractFitter(T* model, int n_param, int max_region_size, int global_algorithm, int n_thread, int* terminate);

   virtual ~AbstractFitter();

   virtual int FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr) = 0;
   virtual int GetLinearParams() = 0;
   
   int Fit(RegionData& region_data, FitResultsRegion& results, int itmax, int& niter, int &ierr, double& c2);
   int GetFit(int irf_idx, double* alf, float* lin_params, double* fit);
   double ErrMinFcn(double x);
   int CalculateErrors(double conf_limit);

   void GetParams(int nl, const double* alf);
   double* GetModel(const double* alf, int irf_idx, int isel, int thread);
   void ReleaseResidualMemory();

   int err;


protected:

   typedef typename T::Buffers Buffers;

   int Init();

   T* model;

   int* terminate;

   double*  alf;
   double*  err_lower;
   double*  err_upper;

   // Used by variable projection
   int     inc[96];
   int     inc_full[96];
   int     ncon;
   int     nconp1;
   int     philp1;

   double *a_;
   double *r;
   double *b_;
   double *kap;
   double *params; 
   double *alf_err;
   double *alf_buf;

   int     n;
   int     nl;
   int     ndim;
   int     nmax;
   int     s;
   int     l;
   int     lmax;
   int     n_param;
   int     p;
   int     pmax;

   int     max_region_size;

   float  *y;
   float  *w;
   float  *avg_y;
   float *lin_params;
   float *chi2;
   int    *irf_idx;

   float chi2_norm;
   double photons_per_count;
   double* cur_chi2;

   int n_thread;
   int variable_phi;

   //int thread;

   int    fixed_param;
   double fixed_value_initial;
   double fixed_value_cur;
   double chi2_final;

   bool getting_errs;

   ptr_vector<Buffers> model_buffer;


private:

   int global_algorithm;
   double conf_limit;

   int search_dir;

   FILE* f_debug;

   int a_size;
   int b_size;


};

#endif