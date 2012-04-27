
#define CMINPACK_NO_DLL

#include "VariableProjection.h"
#include "cminpack.h"
#include <math.h>


int lmvarp(integer *s, integer *l, integer *lmax, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer *lpps1, integer 
   *lps, integer *pp2, integer *iv, doublereal *t, doublereal *y, 
   doublereal *w, S_fp ada, doublereal *a, doublereal *b, doublereal *c, integer *
   iprint, integer *itmax, integer *gc, integer *thread, integer *static_store, 
   doublereal *alf, doublereal *beta, integer *ierr, integer *niter, doublereal *c2, integer *terminate)
{
   varp_param vp;

   vp.gc = gc;
   vp.s = s;
   vp.l = l;
   vp.lmax = lmax;
   vp.nl = nl;
   vp.n = n;
   vp.nmax = nmax;
   vp.ndim = ndim;
   vp.lpps1 = lpps1;
   vp.lps = lps;
   vp.pp2 = pp2;
   vp.iv = iv;
   vp.t = t;
   vp.y = y;
   vp.w = w;
   vp.ada = ada;
   vp.a = a;
   vp.b = b;
   vp.thread = thread;
   vp.alf = alf; 
   vp.beta = beta;
   vp.static_store = static_store;
   vp.iprint = iprint;
   vp.terminate = terminate;

   int lnls1 = *l + *s + *nl + 1;
   int lp1 = *l + 1;
   static doublereal eps1 = 1e-6;
   int* inc = static_store + 5;
   int cdim = max(1,*nl);


   double *dspace = c;
   int dspace_idx = 0;

   double *fjac = dspace + dspace_idx;
   dspace_idx += cdim * cdim;

   double *diag = dspace + dspace_idx;
   dspace_idx += cdim;

   double *qtf = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa1 = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa2 = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa3 = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa4 = dspace + dspace_idx;
   dspace_idx += cdim;

   int *ipvt = (int*) (dspace + dspace_idx);
   dspace_idx += cdim;

   for(int i=0; i<*nl; i++)
      diag[i] = 1;


   double ftol, xtol, gtol;

   ftol = sqrt(dpmpar(1));
   xtol = sqrt(dpmpar(1));
   gtol = 0.;

   int    maxfev = 100;

   int nfev, info;

   void *p = (void*) &vp;

   int nsls1 = *n * *s - *l * (*s - 1);

   info = lmstx( varproj, p, nsls1, *nl, alf, fjac, *nl,
   ftol, xtol, gtol, *itmax, diag, 1, 0.1, -1,
   &nfev, niter, c2, ipvt, qtf, wa1, wa2, wa3, wa4 );

  
   int c__2;

   if (*nl == 0)
   {
      c__2 = 0;
      varproj(p, nsls1, *nl, alf, wa1, wa2, c__2);
   }

   c__2 = 2;
   varproj(p, nsls1, *nl, alf, wa1, wa2, c__2);
       
   double r__;
   postpr_(s, l, lmax, nl, n, nmax, ndim, &lnls1, lps, pp2, &eps1, &r__, 
      iprint, alf, w, a, b, &a[*l * *n], beta, ierr);

    c__2 = 1;
    (*ada)(s, &lp1, nl, n, nmax, ndim, lpps1, pp2, iv, a, b, 0, inc, t, alf, &c__2, gc, thread);

  
   if (info < 0)
      *ierr = info;
   else
      *ierr = *niter;
   return 0;

}