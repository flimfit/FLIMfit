
#ifndef _VARIABLEPROJECTION_H
#define _VARIABLEPROJECTION_H

#include "f2c.h"

extern "C"
int varproj(void *pa, int nls, int nsls1, const double *alf, double *rnorm, double *fjrow, int iflag);

extern "C"
int mle(void *pa, int nfunc, int nl, const double *alf, double *fvec, double *fjac, int ldfjac, int iflag);

extern "C"
void mle_funcs(double *alf, double *fvec, int nl, int nfunc, void *pa);

extern "C"
void mle_jacb(double *alf, double *fjac, int nl, int nfunc, void *pa);


int lmvarp(integer *s, integer *l, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer 
   *p, double *t, float *y, 
   float *w, double *ws, S_fp ada, double *a, double *b, double *c,
   integer *itmax, integer *gc, integer *thread, integer *static_store, 
   double *alf, double *beta, integer *ierr, integer *niter, double *c2, integer *terminate);

int lmmle(integer * nl, integer *l, integer *n, integer *nmax, integer *ndim, integer 
   *p, double *t, float *y, 
   float *w, double *ws, S_fp ada, double *a, double *b, double *c, 
   integer *itmax, integer *gc, integer *thread, integer *static_store, 
   double *alf, double *beta, integer *ierr, integer *niter, double *c2, integer *terminate);

int lmvarp_getlin(integer *s, integer *l, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer 
   *p, double *t, float *y, 
   float *w, double *ws, S_fp ada, double *a, double *b, double *c,
   integer *gc, integer *thread, integer *static_store, 
   double *alf, double *beta);


extern "C"
int postpr_(int *s, int *l, int *
   nl, int *n, int *nmax, int *ndim, int *lnls1, int 
   *p, double *eps, double *rnorm,
   double *alf, float *w, double *a, double *b, 
   double *r__, double *u, int *ierr);


extern "C"
double xnorm_(int *n, double *x);

extern "C"
int init_(integer *s, integer *l, integer *nl,
    integer *n, integer *nmax, integer *ndim, integer *
   p, double *t, float *w, 
   const double *alf, S_fp ada, integer *isel, double 
   *a, double *b, double *kap, integer *inc, integer *ncon, integer *nconp1, 
   logical *philp1, logical *nowate, integer *gc, integer *thread);

typedef struct {
   int* gc;
   int* s;
   int* l;
   int* nl;
   int* n;
   int* nmax;
   int* ndim;
   int* p;
   double *t;
   float *y;
   float *w;
   double *ws;
   S_fp ada;
   double *a;
   double *b;
   int* thread;
   double *alf; 
   double *beta;
   int *static_store;
   int* terminate;
} varp_param;


#endif