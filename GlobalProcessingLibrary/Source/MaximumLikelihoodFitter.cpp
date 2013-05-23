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

#include <cfloat>
#include <cmath>
#include <cstring>

#include "omp_stub.h"
#include "levmar.h"
#include "util.h"


void MLEfuncsCallback(double *alf, double *fvec, int nl, int nfunc, void* pa)
{
   MaximumLikelihoodFitter* f = (MaximumLikelihoodFitter*) pa;
   f->mle_funcs(alf,fvec,nl,nfunc);
}

void MLEjacbCallback(double *alf, double *fjac, int nl, int nfunc, void* pa)
{
   MaximumLikelihoodFitter* f = (MaximumLikelihoodFitter*) pa;
   f->mle_jacb(alf,fjac,nl,nfunc);
}


MaximumLikelihoodFitter::MaximumLikelihoodFitter(FitModel* model, int l, int nl, int nmax, int ndim, int p, double *t, int* terminate) : 
    AbstractFitter(model, 1, l, nl, nl-l, nmax, ndim, p, t, false, 1, terminate)
{
   nfunc = nmax + 1; // +1 for kappa
   nvar = nl;

   dy = new double[nfunc];
   work = new double[ LM_DER_WORKSZ(nvar, nfunc) ];
   expA = new double[nfunc];
}



int MaximumLikelihoodFitter::FitFcn(int nl, double *alf, int itmax, int max_jacb, int* niter, int* ierr)
{

   for(int i=0; i<n; i++)
      dy[i] = y[i] * smoothing;
   dy[n] = 1;
   
   // For maximum likihood set initial guesses for contributions 
   // to sum to maximum intensity, evenly distributed
   if (!getting_errs)
   {
      double mx = 0;
      for(int j=0; j<n; j++)
      {
         if (dy[j]>mx)
            mx = dy[j]; 
      }
#if CONSTRAIN_FRACTIONS
      for(int j=0; j<l; j++)
         alf[nl-l+j] = log(mx/l);
#else
      for(int j=0; j<l; j++)
         alf[nl-l+j] = mx/l;
#endif
   }

    /*
    double* err = new double[nfunc];
    dlevmar_chkjac(MLEfuncsCallback, MLEjacbCallback, alf, nvar, nfunc, this, err);
    err[0] = err[0];
    delete[] err;
    */
/*    
   double opt[4];
   opt[0] = DBL_EPSILON;
   opt[1] = DBL_EPSILON;
   opt[2] = DBL_EPSILON;
   opt[3] = DBL_EPSILON;
   */

   int ret = dlevmar_der(MLEfuncsCallback, MLEjacbCallback, alf, dy, nl, n+1, itmax, NULL, info, work, NULL, this);
   
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
   *cur_chi2 = (info[1] / chi2_norm);

   if(!getting_errs)
   {
#if CONSTRAIN_FRACTIONS
      for(int i=0; i<l; i++)
         lin_params[i] = (float) (exp(alf[nvar-l+i]) / smoothing);
#else
      for(int i=0; i<l; i++)
         lin_params[i] = (float) (alf[nvar-l+i] / smoothing);
#endif
      chi2[0] = (float) *cur_chi2;
   }
   

   if (ret < 0)
      *ierr = (int) info[6]; // reason for terminating
   else
      *ierr = (int) info[5]; // number of interations
   return 0;

}



int MaximumLikelihoodFitter::GetLinearParams(int s, float* y, double* alf) 
{
   return 0;
}


void MaximumLikelihoodFitter::mle_funcs(double *alf, double *fvec, int nl, int nfunc)
{
   int i,j;
   float* adjust;

   GetModel(alf, irf_idx[0], 1, 0);
   adjust = model->GetConstantAdjustment();
   
   double* A = alf+gnl;

#if CONSTRAIN_FRACTIONS
   for(i=0; i<l; i++)
      expA[i] = exp(A[i]);
#else
   for(i=0; i<l; i++)
      expA[i] = A[i];
#endif

   for (i=0; i<n; i++)
   {
      fvec[i] = adjust[i] * smoothing;
      for(j=0; j<l; j++)
         fvec[i] += expA[j]*a_[i+n*j];
   }

   if (philp1)
      for (i=0; i<n; i++)
         fvec[i] += a_[i+n*l];
      

   fvec[n] = kap[0]+1;
}


void MaximumLikelihoodFitter::mle_jacb(double *alf, double *fjac, int nl, int nfunc)
{
   int i,j,k;
   float* adjust;
   int iflag = 1;

   GetModel(alf, irf_idx[0], 1, 0);
   adjust = model->GetConstantAdjustment();

   double* A = alf+gnl;

   memset(fjac,0,nfunc*nl*sizeof(double));

   int m = 0;
   int k_sub = 0;
   for (k=0; k<gnl; k++)
   {
         for(j=0; j<l; j++)
         {
            if (inc[k + j * 12] != 0)
            {
               for (i=0; i<n; i++)
                  fjac[nl*i+k] += expA[j] * b_[ndim*m+i];
               fjac[nl*i+k] = kap[k+1];
               m++;
            }
         }
         if (inc[k + l * 12] != 0)
         {
            for (i=0; i<n; i++)
               fjac[nl*i+k] += b_[ndim*m+i];
            fjac[nl*i+k] = kap[k+1];
            m++;
         }
         k_sub++;      
   }
   // Set derv's for I
   for(j=0; j<l; j++)
   {
#if CONSTRAIN_FRACTIONS
         for (i=0; i<n; i++)
            fjac[nl*i+j+k_sub] = expA[j] * a_[i+n*j];
#else
         for (i=0; i<n; i++)
            fjac[nl*i+j+k_sub] = a_[i+n*j];
#endif
         fjac[nl*i+j+k_sub] = 0; // kappa derv. for I
   }
}


MaximumLikelihoodFitter::~MaximumLikelihoodFitter()
{
   delete[] dy;
   delete[] work;
   delete[] expA;
}