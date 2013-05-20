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

#include "omp_stub.h"
#include "levmar.h"

#include <cstdio>

class FitModel
{
   public: 
      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int CalculateModel(double *a, double *b, double *kap, const double *alf, int irf_idx, int isel, int thread) = 0;
      virtual void GetWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread) = 0;
      virtual float* GetConstantAdjustment() = 0;
};

class AbstractFitter
{
public:

   AbstractFitter(FitModel* model, int smax, int l, int nl, int gnl, int nmax, int ndim, int p, double *t, int variable_phi, int n_thread, int* terminate);
   virtual ~AbstractFitter();
   virtual int FitFcn(int nl, double *alf, int itmax, int max_jacb, int* niter, int* ierr) = 0;
   virtual int GetLinearParams(int s, float* y, double* alf) = 0;
   
   int Fit(int n, int s, int lmax, float* y, float *avg_y, int* irf_idx, double *alf, float *lin_params, float *chi2, int thread, int itmax, double smoothing, int& niter, int &ierr, double& c2);
   int GetFit(int n_meas, int irf_idx, double* alf, float* lin_params, float* adjust, double counts_per_photon, double* fit);
   double ErrMinFcn(double x);
   int CalculateErrors(double* alf, double conf_limit, double* err_lower, double* err_upper);

   void GetParams(int nl, const double* alf);
   double* GetModel(const double* alf, int irf_idx, int isel, int thread);
   void ReleaseResidualMemory();

   int err;


protected:

   int Init();

   FitModel* model;

   int* terminate;

   // Used by variable projection
   int     inc[96];
   int     inc_full[96];
   int     ncon;
   int     nconp1;
   int     philp1;

   double *a;
   double *r;
   double *b;
   double *u;
   double *kap;
   double *params; 
   double *alf_err;
   double *alf_buf;

   int     n;
   int     s;
   int     l;
   int     lmax;
   int     nl;
   int     gnl;
   int     gnl_full;
   int     p;
   int     p_full;

   int     smax;
   int     nmax;
   int     ndim;

   int     lp1;

   float  *y;
   float  *avg_y;
   float *lin_params;
   float *chi2;
   double *t;
   int    *irf_idx;

   double chi2_norm;
   double smoothing;
   double* cur_chi2;

   int n_thread;
   int variable_phi;

   int thread;

   int    fixed_param;
   double fixed_value_initial;
   double fixed_value_cur;
   double chi2_final;

   bool getting_errs;
   double conf_limit;

   int search_dir;

   FILE* f_debug;

};

#endif