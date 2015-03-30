
#define CMINPACK_NO_DLL

#include "VariableProjection.h"
#include "levmar.h"
#include <math.h>
#include "util.h"

int lmmle(int nl, int l, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c, 
   int itmax, int *gc, int thread, int *static_store, 
   double *alf, double *beta, int *ierr, int *niter, double *c2, int *terminate)
{
   varp_param vp;

   int i1 = 1;
   int i0 = 0;

   vp.gc = gc;
   vp.s = i1;
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

//   int lnls1 = *l + *s + *nl + 1;
//   int lp1 = *l + 1;
//   int nsls1 = *n * *s - *l * (*s - 1);
   static double eps1 = 1e-6;
   int* inc = static_store + 5;
   

   int nfunc = n + 1; // +1 for kappa
   int nvar = nl;
  
   int csize = nl * (6 + nfunc) + nfunc;
      //fvec -> [nl]
   //fjac -> [nl * nfunc]
   //ipvt -> [nl]
   //qtf  -> [nl]
   //wa1  -> [nl]
   //wa2  -> [nl]
   //wa3  -> [nl]
   //wa4  -> [nfunc]




   double *dspace = c;
   int dspace_idx = 0;

   double *fjac = dspace + dspace_idx;
   dspace_idx += nfunc * nvar;

   double *fvec = dspace + dspace_idx;
   dspace_idx += nfunc;

   double *diag = dspace + dspace_idx;
   dspace_idx += nvar;

   double *qtf = dspace + dspace_idx;
   dspace_idx += nvar;

   double *wa1 = dspace + dspace_idx;
   dspace_idx += nvar;

   double *wa2 = dspace + dspace_idx;
   dspace_idx += nvar;

   double *wa3 = dspace + dspace_idx;
   dspace_idx += nvar;

   double *wa4 = dspace + dspace_idx;
   dspace_idx += nfunc;

   int *ipvt = (int*) (dspace + dspace_idx);

   for(int i=0; i<nl; i++)
      diag[i] = 1;


   double ftol, xtol, gtol, factor;

   //ftol = sqrt(dpmpar(1));
   //xtol = sqrt(dpmpar(1));
   gtol = 0.;
   factor = 1;

   int    maxfev = 100;

   int nfev;

   void *vvp = (void*) &vp;

   double info[LM_INFO_SZ];

   double* dy = new double[nfunc];
   
   for(int i=0; i<n; i++)
   {
      dy[i] = y[i];
   }
   dy[n] = 1;
   
   
    double* err = new double[nfunc];
    dlevmar_chkjac(mle_funcs, mle_jacb, alf, nvar, nfunc, vvp, err);
    err[0] = err[0];
    delete[] err;
   
    
   dlevmar_der(mle_funcs, mle_jacb, alf, dy, nvar, nfunc, itmax, NULL, info, NULL, NULL, vvp);

   delete[] dy;



   if (info < 0)
      *ierr = info[5];
   else
      *ierr = *niter;
   return 0;

}