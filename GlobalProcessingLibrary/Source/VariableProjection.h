
#ifndef _VARIABLEPROJECTION_H
#define _VARIABLEPROJECTION_H

#include "f2c.h"

extern "C"
int varproj(void *pa, int nls, int nsls1, const double *alf, double *rnorm, double *fjrow, int iflag);

int lmvarp(integer *s, integer *l, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer 
   *p, doublereal *t, doublereal *y, 
   doublereal *w, doublereal *ws, S_fp ada, doublereal *a, doublereal *b, doublereal *c,
   integer *itmax, integer *gc, integer *thread, integer *static_store, 
   doublereal *alf, doublereal *beta, integer *ierr, integer *niter, doublereal *c2, integer *terminate);

int lmvarp_getlin(integer *s, integer *l, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer 
   *p, doublereal *t, doublereal *y, 
   doublereal *w, doublereal *ws, S_fp ada, doublereal *a, doublereal *b, doublereal *c,
   integer *gc, integer *thread, integer *static_store, 
   doublereal *alf, doublereal *beta);


extern "C"
int postpr_(int *s, int *l, int *
   nl, int *n, int *nmax, int *ndim, int *lnls1, int 
   *p, double *eps, double *rnorm,
   double *alf, double *w, double *a, double *b, 
   double *r__, double *u, int *ierr);


extern "C"
double xnorm_(int *n, double *x);

extern "C"
int init_(integer *s, integer *l, integer *nl,
    integer *n, integer *nmax, integer *ndim, integer *
   p, doublereal *t, doublereal *w, 
   const doublereal *alf, S_fp ada, integer *isel, doublereal 
   *a, doublereal *b, doublereal *kap, integer *inc, integer *ncon, integer *nconp1, 
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
   double *y;
   double *w;
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