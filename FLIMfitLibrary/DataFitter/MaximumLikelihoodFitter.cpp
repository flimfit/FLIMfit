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


#include "MaximumLikelihoodFitter.h"
#include "DecayModel.h"
#include "FlagDefinitions.h"

#include <cfloat>
#include <cmath>
#include <cstring>
#include <iostream>

#include "omp_stub.h"
#include "levmar.h"
#include "util.h"



void MLEfuncsCallback(double *alf, double *fvec, int nl, int nfunc, void* pa)
{
   MaximumLikelihoodFitter* f = (MaximumLikelihoodFitter*)pa;

   f->setScaledVariables(alf);
   f->mle_funcs(alf, fvec, nl, nfunc);
}

void MLEjacbCallback(double *alf, double *fjac, int nl, int nfunc, void* pa)
{
   MaximumLikelihoodFitter* f = (MaximumLikelihoodFitter*) pa;
   f->setScaledVariables(alf);
   f->mle_jacb(alf, fjac, nl, nfunc);
}

MaximumLikelihoodFitter::MaximumLikelihoodFitter(std::shared_ptr<DecayModel> model, FittingOptions options, std::shared_ptr<ProgressReporter> reporter) :
    AbstractFitter(model, model->getNumColumns(), 1, GlobalBinning, 1, options, reporter)
{
   nfunc = n + 1; // +1 for kappa

   dy.resize(nfunc);
   work.resize(LM_DER_WORKSZ(n_param, nfunc));
   expA.resize(n_param);
   alf_unscaled.resize(n_param);

   int b_size = ndim * (p + 3);
   b.resize(b_size);

   nnls = std::make_unique<NonNegativeLeastSquares>(l, n);
}

void MaximumLikelihoodFitter::fitFcn(int nl, std::vector<double>& alf, int& niter, int& ierr)
{

   for(int i=0; i<n; i++)
      dy[i] = y[i];
   dy[n] = 1;
   
   setVariables(alf.begin());
   getModel(model, irf_idx[0], a);

   for (int i = 0; i < n; i++)
      b[i] = y[i];

   double rnorm;

   // For maximum likihood set intensity initial guesses to nnls estimate
   nnls->compute(a.data(), n, nmax, b.data(), work.data(), rnorm);

   scaling = 1;
   for (int i = 0; i < l; i++)
      scaling += work[i];
   scaling = scaling / 10000.0;

   if (!getting_errs)
   {
#if CONSTRAIN_FRACTIONS
      for(int j=0; j<l; j++)
         alf[nl+j] = log(work[j]);
#else
      for(int j=0; j<l; j++)
         alf[nl+j] = x[j] / scaling;
#endif
   }

   scale.clear();
   scale.reserve(nl + l);
   auto& params = model->getAllParameters();
   for (auto& p : params)
      if (p->isFittedGlobally())
         scale.push_back(p->transformed_scale);

   for (int i = 0; i < l; i++)
      scale.push_back(1);
    
   for (int i = 0; i < n_param; i++)
      alf[i] /= scale[i];


   double opt[4];
   opt[0] = options.initial_step_size;
   opt[1] = DBL_EPSILON;
   opt[2] = DBL_EPSILON;
   opt[3] = DBL_EPSILON;
   

   int ret = dlevmar_der(MLEfuncsCallback, MLEjacbCallback, alf.data(), dy.data(), n_param, n+1,
                         options.max_iterations, opt, info, work.data(), NULL, this);
   
   					           /* O: information regarding the minimization. Set to NULL if don't care
                      * info[0]= ||e||_2 at initial p.
                      * info[1-4]=[ ||e||_2, ||J^T e||_inf,  ||Dp||_2, mu/max[J^T J]_ii ], all computed at estimated p.
                      * info[5]= # iterations,
                      * info[6]=reason for terminating: 1 - stopped by small gradient J^T e
                      *                                 2 - stopped by small Dp
                      *                                 3 - stopped by itmax
                      *                                 4 - singular matrix. Restart from current p with increased mu 
                      *                                 5 - no further error reduction is possible. Restart with increased mu
                      *                                 6 - stopped by small ||e||_2
                      *                                 7 - stopped by invalid (i.e. NaN or Inf) "func" values. This is a user error
                      * info[7]= # function evaluations
                      * info[8]= # Jacobian evaluations
                      * info[9]= # linear systems solved, i.e. # attempts for reducing error
*/

   //if (info[6] == 7)
   //   throw std::runtime_error("Non-finite entry in model");

   for (int i = 0; i < 5; i++)
      if (!std::isfinite(info[i]))
         ret = -1; //TODO: //throw std::runtime_error("Non-finite entry in returned minimisation parameters");

   *cur_chi2 = (info[1] / chi2_norm);

   for (int i = 0; i < n_param; i++)
      alf[i] *= scale[i];

   if(!getting_errs)
   {
#if CONSTRAIN_FRACTIONS
      for(int i=0; i<l; i++)
         lin_params[i] = (float) exp(alf[nl+i]);
#else
      for(int i=0; i<l; i++)
         lin_params[i] = (float) (alf[n_param-l+i] * scaling); 
#endif
      chi2[0] = (float) *cur_chi2;
   }
   
   if (ret < 0)
      ierr = (int) info[6]; // reason for terminating
   else
      ierr = (int) info[5]; // number of interations
}



void MaximumLikelihoodFitter::getLinearParams() 
{}

void MaximumLikelihoodFitter::setLinearFactors(double* alf)
{
   double* A = alf + nl;

#if CONSTRAIN_FRACTIONS
   for (int i = 0; i<l; i++)
      expA[i] = exp(A[i]);
#else
   for (int i = 0; i<l; i++)
      expA[i] = A[i] * scaling;
#endif
}


void MaximumLikelihoodFitter::mle_funcs(double *alf, double *fvec, int n_param, int nfunc)
{
   setLinearFactors(alf);
   getModel(model, irf_idx[0], a);
   float_iterator adjust = model->getConstantAdjustment();

   for (int i=0; i<n; i++)
   {
      fvec[i] = adjust[i];
      for(int j=0; j<l; j++)
         fvec[i] += expA[j]*a[i+nmax*j];
   }

   if (philp1)
      for (int i=0; i<n; i++)
         fvec[i] += a[i+nmax*l];

    fvec[n] = kap[0]+1;
}

void MaximumLikelihoodFitter::mle_jacb(double* alf, double *fjac, int n_param, int nfunc)
{
   setLinearFactors(alf);
   getModel(model, irf_idx[0], a);
   getDerivatives(model, irf_idx[0], b, a);
   float_iterator adjust = model->getConstantAdjustment();

   memset(fjac,0,nfunc*n_param*sizeof(double));

   int m = 0;
   int k_sub = 0;
   for (int k = 0; k < nl; k++)
   {
      for (int j = 0; j < l; j++)
      {
         if (inc[k + j * MAX_VARIABLES] != 0)
         {
            for (int i = 0; i < n; i++)
               fjac[n_param*i + k] += expA[j] * b[ndim*m + i] * scale[k];
            fjac[n_param*n + k] = kap[k + 1];
            m++;
         }
      }
      if (inc[k + l * MAX_VARIABLES] != 0)
      {
         for (int i = 0; i < n; i++)
            fjac[n_param*i + k] += b[ndim*m + i] * scale[k];
         fjac[n_param*n + k] = kap[k + 1];
         m++;
      }
      k_sub++;
   }
   // Set derv's for I
   for(int j=0; j<l; j++)
   {
#if CONSTRAIN_FRACTIONS
         for (int i=0; i<n; i++)
            fjac[n_param*i+j+k_sub] = expA[j] * a[nmax*j + i];
#else
         for (int i=0; i<n; i++)
            fjac[n_param*i+j+k_sub] = a[nmax*j + i] * scaling;
#endif
         fjac[n_param*n+j+k_sub] = 0; // kappa derv. for I
   }
}
