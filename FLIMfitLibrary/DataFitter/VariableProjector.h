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

class VariableProjector : public AbstractFitter
{

public:
   VariableProjector(shared_ptr<DecayModel> model, int max_region_size, int weighting, int global_algorithm, int n_thread, std::shared_ptr<ProgressReporter> reporter);
   ~VariableProjector();
   //VariableProjector* clone() const { return new VariableProjector(*this); };

   int FitFcn(int nl, vector<double>& alf, int itmax, int* niter, int* ierr);

   int GetLinearParams(); 

private:

   int varproj(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread);
   
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

   bool fit_successful = false;

   friend int VariableProjectorDiffCallback(void *p, int m, int n, const double *x, double *fnorm, int iflag);
   friend int VariableProjectorCallback(void *p, int m, int n, int s_red, const double *x, double *fnorm, double *fjrow, int iflag, int thread);
};

#endif