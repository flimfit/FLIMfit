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

   double chi2_norm;
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

private:

   ptr_vector<typename T::Buffers> model_buffer;

   int global_algorithm;
   double conf_limit;

   int search_dir;

   FILE* f_debug;

   int a_size;
   int b_size;


};


template <class T>
AbstractFitter<T>::AbstractFitter(T* model, int n_param, int max_region_size, int global_algorithm, int n_thread, int* terminate) : 
    model(model), n_param(n_param), max_region_size(max_region_size), global_algorithm(global_algorithm), n_thread(n_thread), terminate(terminate)
{
   err = 0;

   a_   = NULL;
   r   = NULL;
   b_   = NULL;
   kap = NULL;
   alf = NULL;
   err_upper = NULL;
   err_lower = NULL;
   alf_buf = NULL;
   alf_err = NULL;

   params = NULL;
   alf_err = NULL;

   nl   = model->nl;
   l    = model->l;
   n    = model->n;
   nmax = model->n;

   pmax  = model->p;

   ndim       = max( n, 2*nl+3 );
   nmax       = n + 16; // pad to prevent false sharing  

   int lp1 = l+1;


   for (int i=0; i<n_thread; i++)
      model_buffer.push_back( new T::Buffers(model) );


   // Check for valid input
   //----------------------------------
   if  (!(             l >= 0
          &&          nl >= 0
          && (nl<<1) + 3 <= ndim
          && !(nl == 0 && l == 0)))
   {
      err = ERR_INVALID_INPUT;
      return;
   }
   

   a_size = nmax * lp1;
   b_size = ndim * ( pmax + 3 );

   a_      = new double[ a_size * n_thread ]; //free ok
   r       = new double[ nmax * max_region_size ];
   b_      = new double[ ndim * ( pmax + 3 ) * n_thread ]; //free ok
   kap     = new double[ model->nl + 1 ];
   params  = new double[ model->nl ];
   alf_err = new double[ model->nl ];
   alf_buf = new double[ model->nl ];
   alf     = new double[ n_param ];
   err_upper = new double[ n_param ];
   err_lower = new double[ n_param ];

   y            = new float[ max_region_size * nmax ]; //free ok 
   irf_idx      = new int[ max_region_size ];

   w            = new float[ nmax ]; //free ok
    
   fixed_param = -1;

   getting_errs = false;

   Init();

   if (pmax != p)
      err = ERR_INVALID_INPUT;

}

#endif