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

#ifndef _MAXIMIUMLIKELIHOODFITTER_H
#define _MAXIMIUMLIKELIHOODFITTER_H

#include "AbstractFitter.h"

class MaximumLikelihoodFitter : public AbstractFitter
{
public:

   MaximumLikelihoodFitter(FitModel* model, int l, int nl, int nmax, int ndim, int p, double *t, int* terminate);
   ~MaximumLikelihoodFitter();

   int FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr, double* c2);

   int GetFit(int irf_idx, double* alf, float* lin_params, float* adjust, double* fit);
   int GetLinearParams(int s, float* y, double* alf) ;
private:

   int Init();

   void mle_funcs(double *alf, double *fvec, int nl, int nfunc);
   void mle_jacb(double *alf, double *fjac, int nl, int nfunc);

   // Buffers used by levmar algorithm
   double info[LM_INFO_SZ];
   double* dy;
   double* work;
   double* expA;

   int nfunc;
   int nvar;

   friend void MLEfuncsCallback(double *alf, double *fvec, int nl, int nfunc, void* pa);
   friend void MLEjacbCallback(double *alf, double *fjac, int nl, int nfunc, void* pa);
};

#endif