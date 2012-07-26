#ifndef _VARIABLEPROJECTOR_H
#define _VARIABLEPROJECTOR_H

#include "VariableProjection.h"

class VariableProjector
{

public:
   VariableProjector(Tada ada, int* gc, int smax, int l, int nl, int nmax, int ndim, int p, double *t);
   ~VariableProjector();

   int Fit(int s, int n, float* y, float *w, double *alf, double *lin_params, int thread, int itmax, int& niter, int &ierr, double& c2);


private:

   int Init();
   
   int varproj(void *pa, int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag);
   int GetLinearParams(int s, double* alf, double* beta, int thread);

   double d_sign(double *a, double *b);

   Tada ada;
   int* gc;

   // Buffers used by levmar algorithm
   double *fjac;
   double *diag;
   double *qtf;
   double *wa1, *wa2, *wa3, *wa4;
   int    *ipvt;

   // Used by variable projection
   int     inc[96];
   int     ncon;
   int     nconp1;
   int     philp1;

   double *a;
   double *b;
   double *u;
   double *kap;

   int     n;
   int     s;
   int     l;
   int     nl;
   int     p;

   int     smax;
   int     nmax;
   int     ndim;

   int     lp1;

   float  *y;
   float  *w;
   double *t;

   int thread;

};

#endif