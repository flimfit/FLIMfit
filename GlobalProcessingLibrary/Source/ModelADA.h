//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================

#ifndef _MODELADA_H
#define _MODELADA_H

#include "FlagDefinitions.h"

#define T_FACTOR  1


double TransformRange(double v, double v_min, double v_max);
double InverseTransformRange(double t, double v_min, double v_max);
double TransformRangeDerivative(double v, double v_min, double v_max);

double kappa_spacer(double tau2, double tau1);
double kappa_lim(double tau);

extern "C"
void updatestatus_(int* gc, int* thread, int* iter, float* chi2, int* terminate);


#endif
