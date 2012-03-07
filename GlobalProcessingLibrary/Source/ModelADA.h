
#ifndef _MODELADA_H
#define _MODELADA_H


//#define _CRTDBG_MAPALLOC

#ifdef _WINDOWS
#include <windows.h>
#endif

#include <stdlib.h>
#include <math.h>

#include "f2c.h"

#define APPLY_ANSCOME_TRANSFORM  0

#define FIX            0
#define FIT_LOCALLY    1
#define FIT_GLOBALLY   2

#define FIT            1

#define DATA_TYPE_TCSPC 0
#define DATA_TYPE_TIMEGATED 1

class FLIMGlobalFitController;

typedef void (* conv_func)(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double& c);
typedef void (* conv_deriv_func)(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c);

typedef int (*Tada)(int *s, int *lp1, int *nl, int *n, 
	int *nmax, int *ndim, int *lpp2, int *pp2, int *iv, 
	double *a, double *b, int *inc, double *t, double *alf, int *isel, int *gidx);

extern "C"
int dpa_(int *s, int *l, int *lmax, int *nl, 
	int *n, int *nmax, int *ndim, int *lpps1, int *
	lps, int *pp2, int *iv, double *t, double *y, double 
	*w, double *alf, S_fp ada, int *isel, int *iprint, 
	double *a, double *b, double *u, double *r__, 
	double *rnorm, int *gc, int *thread, int *static_store);
   
extern "C"
double xnorm_(int *n, double *x);

extern "C"
int varp2_(int *s, int *l, int *lmax, int *
	nl, int *n, int *nmax, int *ndim, int *lpps1, int 
	*lps, int *pp2, int *iv, double *t, double *y, 
	double *w, U_fp ada, double *a, double *b, int *
	iprint, int *itmax, int *gc, int *thread, int *static_store,
   double *alf, double *beta, int *ierr, double *r, int *gn, double *alf_best);

extern "C"
int ada(int *s, int *lp1, int *nl, int *n, 
	int *nmax, int *ndim, int *lpp2, int *pp2, int *iv, double *a, double *b, 
   int *inc, double *t, double *alf, int *isel, int *gc, int *thread);

extern "C"
int postpr_(int *s, int *l, int *lmax, int *
	nl, int *n, int *nmax, int *ndim, int *lnls1, int 
	*lps, int *pp2, double *eps, double *rnorm, int *
	iprint, double *alf, double *w, double *a, double *b, 
	double *r__, double *u, int *ierr);

extern "C"
void varp2_grid(int *s, int *l, int *lmax, int *
	nl, int *n, int *nmax, int *ndim, int *lpps1, int 
	*lps, int *pp2, int *iv, double *t, double *y, 
	double *w, U_fp ada, double *a, double *b,
	 int *iprint, int *gc, int *gidx, double *alf, double *beta, 
	int *ierr, double *r__, int *gn,
   double var_min[], double var_max[], double grid[], int grid_size, int grid_factor, double buf[], int n_iter );


double tau2alf(double tau, double tau_min, double tau_max);
double alf2tau(double alf, double tau_min, double tau_max);
double d_tau_d_alf(double tau, double tau_min, double tau_max);

double beta2alf(double beta);
double alf2beta(double alf);
double d_beta_d_alf(double beta);

double kappa(double tau2, double tau1);
double d_kappa_d_tau(double tau2, double tau1);

extern "C"
void updatestatus_(int* gc, int* thread, int* iter, double* chi2, int* terminate);


#endif
