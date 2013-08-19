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

#ifndef _VARIABLEPROJECTOR_H
#define _VARIABLEPROJECTOR_H

#include "AbstractFitter.h"

#define ANALYTICAL_DERV 0
#define NUMERICAL_DERV  1

template <class T>
class VariableProjector : public AbstractFitter<T>
{

public:
   VariableProjector(T* model, int max_region_size, int global_algorithm, int n_thread, int* terminate);
   ~VariableProjector();

   int FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr);

   int GetLinearParams(); 

private:

   int varproj(int nsls1, int nls, int s_red, const double *alf, double *rnorm, double *fjrow, int iflag, int thread);   
   
   void transform_ab(int& isel, int px, int thread, int firstca, int firstcb);

   void CalculateWeights(int px, const double* alf, int thread);

   void get_linear_params(int idx, double* a, double* u, double* x = 0);
   int bacsub(int idx, double* a, volatile double* x);
   int bacsub(volatile double *r, double *a, volatile double *x);

   double d_sign(double *a, double *b);

   double *work_, *w; 
   double *aw_, *bw_, *wp_, *u_;
   
   // Buffers used by levmar algorithm
   double *fjac;
   double *fvec;
   double *diag;
   double *qtf;
   double *wa1, *wa2, *wa3, *wa4;
   int    *ipvt;
   
   double* r_buf_;
   double* norm_buf_;
 
   int n_call;

   int n_jac_group;

   int weighting;
   int iterative_weighting;

   int use_numerical_derv;
   int using_gamma_weighting;

   template <class T>
   friend int VariableProjectorDiffCallback(void *p, int m, int n, const double *x, double *fnorm, int iflag);
   
   template <class T>
   friend int VariableProjectorCallback(void *p, int m, int n, int s_red, const double *x, double *fnorm, double *fjrow, int iflag, int thread);
};


template <class T>
VariableProjector<T>::VariableProjector(T* model, int max_region_size, int global_algorithm, int n_thread, int* terminate) : 
    AbstractFitter(model, max_region_size, model->nl, global_algorithm, n_thread, terminate)
{
   this->weighting = weighting;

   use_numerical_derv = false;

   iterative_weighting = (weighting > AVERAGE_WEIGHTING) | variable_phi;

   n_jac_group = (int) ceil(1024.0 / (nmax-l));

   work_ = new double[nmax * n_thread];

   aw_   = new double[ nmax * (l+1) * n_thread ]; //free ok
   bw_   = new double[ ndim * ( pmax + 3 ) * n_thread ]; //free ok
   wp_   = new double[ nmax * n_thread ];
   u_    = new double[ nmax * n_thread ];
   w     = new double[ nmax ];

   r_buf_ = new double[ nmax * n_thread ];
   norm_buf_ = new double[ nmax * n_thread ];

   // Set up buffers for levmar algorithm
   //---------------------------------------------------
   int buf_dim = max(16,nl);
   
   diag = new double[buf_dim * n_thread];
   qtf  = new double[buf_dim * n_thread];
   wa1  = new double[buf_dim * n_thread];
   wa2  = new double[buf_dim * n_thread];
   wa3  = new double[buf_dim * n_thread * nmax * n_jac_group];
   ipvt = new int[buf_dim * n_thread];

   if (use_numerical_derv)
   {
      fjac = new double[nmax * max_region_size * n];
      wa4  = new double[nmax * max_region_size]; 
      fvec = new double[nmax * max_region_size];
   }
   else
   {
      fjac = new double[buf_dim * buf_dim * n_thread];
      wa4 = new double[buf_dim *  n_thread];
      fvec = new double[nmax * n_thread * n_jac_group];
   }

   for(int i=0; i<nl; i++)
      diag[i] = 1;

};


#endif