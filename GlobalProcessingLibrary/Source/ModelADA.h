
#ifndef _MODELADA_H
#define _MODELADA_H


//#define _CRTDBG_MAPALLOC

#ifdef _WINDOWS
#include <windows.h>
#endif

#include <stdlib.h>
#include <math.h>

//#include "f2c.h"

#include "FlagDefinitions.h"

#define T_FACTOR  1

class FLIMGlobalFitController;

typedef void (* conv_func)(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double pulse_fact, double& c);
typedef void (* conv_deriv_func)(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double pulse_fact, double ref_fact, double& c);


double TransformRange(double v, double v_min, double v_max);
double InverseTransformRange(double t, double v_min, double v_max);
double TransformRangeDerivative(double v, double v_min, double v_max);

double kappa_spacer(double tau2, double tau1);
double kappa_lim(double tau);

double kappa(double tau2, double tau1);
double d_kappa_d_tau(double tau2, double tau1);

extern "C"
void updatestatus_(int* gc, int* thread, int* iter, float* chi2, int* terminate);


#endif
