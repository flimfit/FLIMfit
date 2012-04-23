
#ifndef _VARIABLEPROJECTION_H
#define _VARIABLEPROJECTION_H

#include "f2c.h"

extern "C"
int varproj(void *pa, int nls, int nsls1, const double *alf, double *rnorm, double *fjrow, int iflag);

int lmvarp(integer *s, integer *l, integer *lmax, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer *lpps1, integer 
   *lps, integer *pp2, integer *iv, doublereal *t, doublereal *y, 
   doublereal *w, S_fp ada, doublereal *a, doublereal *b, doublereal *c, integer *
   iprint, integer *itmax, integer *gc, integer *thread, integer *static_store, 
   doublereal *alf, doublereal *beta, integer *ierr, integer *niter, doublereal *c2, integer *terminate);

extern "C"
int postpr_(integer *, integer *, integer *, 
       integer *, integer *, integer *, integer *, integer *, integer *, 
       integer *, doublereal *, doublereal *, integer *, doublereal *, 
       doublereal *, doublereal *, doublereal *, doublereal *, 
       doublereal *, integer *);

typedef struct {
   int* gc;
   int* s;
   int* l;
   int* lmax;
   int* nl;
   int* n;
   int* nmax;
   int* ndim;
   int* lpps1;
   int* lps;
   int* pp2;
   int* iv;
   double *t;
   double *y;
   double *w;
   S_fp ada;
   double *a;
   double *b;
   int* thread;
   double *alf; 
   double *beta;
   int *static_store;
   int* iprint;
   int* terminate;
} varp_param;


#endif