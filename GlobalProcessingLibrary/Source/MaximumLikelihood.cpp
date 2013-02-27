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

#include "ModelADA.h"
#include "VariableProjection.h"

#include <string.h>

#ifndef NO_OMP   
#include <omp.h>
#endif
   
#include <emmintrin.h>

void mle_funcs(double *alf, double *fvec, int nl, int nfunc, void *pa)
{
   int i,j;

   int iflag = 1;

   varp_param* vp = (varp_param*) pa;
   int s      = (vp->s);
   int l      = (vp->l);
   int n      = (vp->n);
   int nmax   = (vp->nmax);
   int ndim   = (vp->ndim);
   int p      = (vp->p);

   int thread = (vp->thread);

   double *t = vp->t;
   float *y = vp->y;
   float *w = vp->w;
   
   double *a   = vp->a;
   double *b   = vp->b;
  
   double *kap = b + ndim * (p+2);

   int *static_store = vp->static_store;
   int* inc = static_store + 5;

   int *gc = vp->gc;
   Tada ada = vp->ada;

   (*ada)(s, NULL, nl, n, nmax, ndim, p, a, b, kap, inc, t, alf, &iflag, gc, thread);

   int gnl = nl-l;
   double* A = alf+gnl;

   memset(fvec,0,nfunc*sizeof(double));

   for (i=0; i<n; i++)
      for(j=0; j<l; j++)
      fvec[i] += A[j]*a[i+n*j];

   fvec[n] = kap[0]+1;

}

void mle_jacb(double *alf, double *fjac, int nl, int nfunc, void *pa)
{
   int i,j,k;

   int iflag = 1;

   varp_param* vp = (varp_param*) pa;
   int s      = (vp->s);
   int l      = (vp->l);
   int n      = (vp->n);
   int nmax   = (vp->nmax);
   int ndim   = (vp->ndim);
   int p      = (vp->p);

   int thread = (vp->thread);

   double *t = vp->t;
   float *y = vp->y;
   float *w = vp->w;
   
   double *a   = vp->a;
   double *b   = vp->b;
  
   double *kap = b + ndim * (p+2);

   int* gc = vp->gc;
   int* static_store = vp->static_store;
   int* inc = static_store + 5;

   Tada ada = vp->ada;

   (*ada)(s, 0, nl, n, nmax, ndim, p, a, b, kap, NULL, t, alf, &iflag, gc, thread);

   int gnl = nl-l;

   double* A = alf+gnl;

   memset(fjac,0,nfunc*nl*sizeof(double));

   int m = 0;
   for (k=0; k<gnl; k++)
   {
      for(j=0; j<l; j++)
      {
         if (inc[k + j * 12] != 0)
         {
            for (i=0; i<n; i++)
               fjac[nl*i+k] += A[j] * b[ndim*m+i];
            fjac[nl*i+k] = kap[k+1];
            m++;
         }
      }
   }
   // Set derv's for I
   for(j=0; j<l; j++)
   {
      for (i=0; i<n; i++)
         fjac[nl*i+j+gnl] = a[i+n*j];
      fjac[nl*i+j+gnl] = 0; // kappa derv. for I
   }
}



int mle(void *pa, int nfunc, int nl, double *alf, double *fvec, double *fjac, int ldfjac, int iflag)
{
   int i,j;

   iflag += 1;

   varp_param* vp = (varp_param*) pa;
   int s      = vp->s;
   int l      = vp->l;
   int n      = vp->n;
   int nmax   = vp->nmax;
   int ndim   = vp->ndim;
   int p      = vp->p;

   int thread = (vp->thread);

   double *t = vp->t;
   float *y = vp->y;
   float *w = vp->w;
   
   double *a   = vp->a;
   double *b   = vp->b;
  
   double *kap = b + ndim * (p+2);


   if (vp->terminate != NULL && *vp->terminate)
      return -9;

   int *gc = vp->gc;
   Tada ada = vp->ada;

   (*ada)(s, NULL, nl, n, nmax, ndim, p, a, b, kap, NULL, t, alf, &iflag, gc, thread);

   double I = alf[nl-1];

   if (iflag < 3)
   {
      for (i=0; i<n; i++)
      {
         if (y[i] > 0)
            fvec[i] = 2 * (I*a[i] - y[i]) - 2 * y[i] * log(I*a[i]/y[i]);
         else
            fvec[i] = 0;
      }
      fvec[n] = kap[0];
   }
   else
   {
      for (j=0; j<(nl-1); j++)
      {
         for (i=0; i<n; i++)
            fjac[nfunc*j+i] = 2 * (1-y[i]/(I*a[i])) * I * b[nfunc*j+i];
         fjac[nfunc*j+i] = kap[j+1];
      }
      // Set derv's for I
      for (i=0; i<n; i++)
         fjac[nfunc*j+i] = 2 * (1-y[i]/(I*a[i])) * a[i];
      fjac[nfunc*j+i] = 0; // kappa derv. for I
      
   }


   return 0;
}
