
#ifndef _VARIABLEPROJECTION_H
#define _VARIABLEPROJECTION_H

#include "f2c.h"

typedef int (*Tada)(int s, int lp1, int nl, int n, int nmax, int ndim, 
        int pp2, double *a, double *b, double *kap, int *inc, 
        double *t, const double *alf, int *isel, int *gc_int, int thread);

extern "C"
int mle(void *pa, int nfunc, int nl, const double *alf, double *fvec, double *fjac, int ldfjac, int iflag);

extern "C"
void mle_funcs(double *alf, double *fvec, int nl, int nfunc, void *pa);

extern "C"
void mle_jacb(double *alf, double *fjac, int nl, int nfunc, void *pa);


int lmmle(int nl, int l, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c, 
   int itmax, int *gc, int thread, int *static_store, 
   double *alf, double *beta, int *ierr, int *niter, double *c2, int *terminate);

typedef struct {
   int* gc;
   int s;
   int l;
   int nl;
   int n;
   int nmax;
   int ndim;
   int p;
   double *t;
   float *y;
   float *w;
   double *ws;
   Tada ada;
   double *a;
   double *b;
   int thread;
   double *alf; 
   double *beta;
   int *static_store;
   int* terminate;
} varp_param;


/*
extern "C"
int varproj(void *pa, int nls, int nsls1, const double *alf, double *rnorm, double *fjrow, int iflag);

extern "C"
void jacb_row(int s, int l, int n, int ndim, int nl, int lp1, int ncon, 
              int nconp1, int* inc, double* b, double *kap, double *ws, double* r__, int d_idx, double* res, double* derv);


int lmvarp(int s, int l, int nl, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c,
   int itmax, int *gc, int thread, int *static_store, 
   double *alf, double *beta, int *ierr, int *niter, double *c2, int *terminate);

int lmvarp_getlin(int s, int l, int nl, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c,
   int *gc, int thread, int *static_store, double *alf, double *beta);


extern "C"
int postpr_(int s, int l, int nl, int n, int nmax, int ndim, int lnls1, int p,
   const double *alf, float *w, double *a, double *b, double *r__, double *u, int *ierr);



extern "C"
int init_(int s, int l, int nl,
    int n, int nmax, int ndim, int p, double *t, float *w, 
   const double *alf, Tada ada, int *isel, double 
   *a, double *b, double *kap, int *inc, int *ncon, int *nconp1, 
   logical *philp1, logical *nowate, int *gc, int thread);

extern "C"
int bacsub_(int ndim, int n, double *a, double *x);



*/

#endif