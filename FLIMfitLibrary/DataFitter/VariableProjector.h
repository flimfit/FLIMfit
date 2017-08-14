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

#pragma once

#include "AbstractFitter.h"
#include "nnls.h"

#define ANALYTICAL_DERV 0
#define NUMERICAL_DERV  1

class VariableProjector : public AbstractFitter
{

public:
   VariableProjector(std::shared_ptr<DecayModel> model, int max_region_size, int weighting, int global_algorithm, int n_thread, std::shared_ptr<ProgressReporter> reporter);
   ~VariableProjector();

   void FitFcn(int nl, std::vector<double>& alf, int itmax, int* niter, int* ierr);

   void GetLinearParams(); 

private:
   
   int getResidual(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread);
   int getResidualNonNegative(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread);

   int prepareJacobianCalculation(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread);
   int getJacobianEntry(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread);

   void transformAB(int px, int thread, bool transformB = true);

   void CalculateWeights(int px, const double* alf, int thread);

   void get_linear_params(int idx, std::vector<double>& a, std::vector<double>& u, std::vector<double>& x);
   void bacsub(int idx, double* a, volatile double* x);
   void bacsub(volatile double *r, double *a, volatile double *x);

   double d_sign(double *a, double *b);

   std::vector<std::vector<double>> work_; 
   std::vector<std::vector<double>> aw_, bw_, wp_, u_;
   
   std::vector<double> w;

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

   std::unique_ptr<NonNegativeLeastSquares> nnls;


   friend int VariableProjectorDiffCallback(void *p, int m, int n, const double *x, double *fnorm, int iflag);
   friend int VariableProjectorCallback(void *p, int m, int n, int s_red, const double *x, double *fnorm, double *fjrow, int iflag, int thread);
};