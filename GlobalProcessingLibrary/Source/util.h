#ifndef _UTIL_H
#define _UTIL_H

#include <stdio.h>

void ClearVariable(double*& var);
void ClearVariable(int*& var);
void ClearVariable(float*& var);

void SetNaN(double* var, int n);
void SetNaN(float* var, int n);

#ifndef max
#define min(a,b) ((a) <= (b) ? (a) : (b))
#define max(a,b) ((a) >= (b) ? (a) : (b))
#endif

#endif 