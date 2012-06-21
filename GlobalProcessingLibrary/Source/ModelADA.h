
#ifndef _MODELADA_H
#define _MODELADA_H


//#define _CRTDBG_MAPALLOC

#ifdef _WINDOWS
#include <windows.h>
#endif

#include <stdlib.h>
#include <math.h>

#include "f2c.h"

#include "FlagDefinitions.h"

#define T_FACTOR  1

class FLIMGlobalFitController;

typedef void (* conv_func)(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c);
typedef void (* conv_deriv_func)(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);

typedef int (*Tada)(int *s, int *lp1, int *nl, int *n, 
   int *nmax, int *ndim, int *pp2,
   double *a, double *b, double *kap, int *inc, double *t, double *alf, int *isel, int *gc, int *thread);


extern "C"
int ada(int *s, int *lp1, int *nl, int *n, 
   int *nmax, int *ndim, int *p, double *a, double *b, 
   double *kap, int *inc, double *t, double *alf, int *isel, int *gc, int *thread);


double TransformRange(double v, double v_min, double v_max);
double InverseTransformRange(double t, double v_min, double v_max);
double TransformRangeDerivative(double v, double v_min, double v_max);

/*
double beta2alf(double beta);
double alf2beta(double alf);
double d_beta_d_alf(double beta);
*/

double kappa(double tau2, double tau1);
double d_kappa_d_tau(double tau2, double tau1);

extern "C"
void updatestatus_(int* gc, int* thread, int* iter, double* chi2, int* terminate);


#endif
