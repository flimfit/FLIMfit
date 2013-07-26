
#define CMINPACK_NO_DLL

#include "VariableProjection.h"
#include "cminpack.h"
#include <math.h>
#include "util.h"

int lmvarp_getlin(int s, int l, int nl, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c,
   integer *gc, int thread, integer *static_store, 
   double *alf, double *beta)
{
   varp_param vp;

   vp.gc = gc;
   vp.s = s;
   vp.l = l;
   vp.nl = nl;
   vp.n = n;
   vp.nmax = nmax;
   vp.ndim = ndim;
   vp.p = p;
   vp.t = t;
   vp.y = y;
   vp.w = w;
   vp.ws = ws;
   vp.ada = ada;
   vp.a = a;
   vp.b = b;
   vp.thread = thread;
   vp.alf = alf; 
   vp.beta = beta;
   vp.static_store = static_store;
   vp.terminate = 0;

   void *vvp = (void*) &vp;

   int lnls1 = l + s + nl + 1;
   int lp1 = l + 1;
   int nsls1 = n * s - l * (s - 1);
   static double eps1 = 1e-6;
   int* inc = static_store + 5;
   int cdim = max(1,nl);
   
   double *dspace = c;
   int dspace_idx = 0;

   double *wa1 = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa2 = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa3 = dspace + dspace_idx;
   dspace_idx += cdim;

   double *wa4 = dspace + dspace_idx;
   dspace_idx += cdim;


   varproj(vvp, nsls1, nl, alf, wa1, wa2, 0);
   varproj(vvp, nsls1, nl, alf, wa1, wa2, 2);
       
   int ierr = 0;
   postpr_(s, l, nl, n, nmax, ndim, lnls1, p, 
      alf, w, a, b, &a[l * n], beta, &ierr);

   int c__2 = 1;
   (*ada)(s, lp1, nl, n, nmax, ndim, p, a, b, 0, inc, t, alf, &c__2, gc, thread);

   return 0;
}

int lmvarp(int s, int l, int nl, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c,
   int itmax, int *gc, int thread, int *static_store, 
   double *alf, double *beta, int *ierr, int *niter, double *c2, int *terminate)
{
   varp_param vp;

   vp.gc = gc;
   vp.s = s;
   vp.l = l;
   vp.nl = nl;
   vp.n = n;
   vp.nmax = nmax;
   vp.ndim = ndim;
   vp.p = p;
   vp.t = t;
   vp.y = y;
   vp.w = w;
   vp.ws = ws;
   vp.ada = ada;
   vp.a = a;
   vp.b = b;
   vp.thread = thread;
   vp.alf = alf; 
   vp.beta = beta;
   vp.static_store = static_store;
   vp.terminate = terminate;

   int lnls1 = l + s + nl + 1;
   int lp1 = l + 1;
   int nsls1 = n * s - l * (s - 1);
   static double eps1 = 1e-6;
   int* inc = static_store + 5;
   int cdim = max(1,nl);


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

   for(int i=0; i<nl; i++)
      diag[i] = 1;


   double ftol, xtol, gtol, factor;

   ftol = sqrt(dpmpar(1));
   xtol = sqrt(dpmpar(1));
   gtol = 0.;
   factor = 1;

   int    maxfev = 100;

   int nfev, info;

   void *vvp = (void*) &vp;


   info = lmstx( varproj, vvp, nsls1, nl, alf, fjac, nl,
   ftol, xtol, gtol, itmax, diag, 1, factor, -1,
   &nfev, niter, c2, ipvt, qtf, wa1, wa2, wa3, wa4 );

   if (alf[0]==3000)
      alf[0] = alf[0];


   if (info < 0)
      *ierr = info;
   else
      *ierr = *niter;
   return 0;

}