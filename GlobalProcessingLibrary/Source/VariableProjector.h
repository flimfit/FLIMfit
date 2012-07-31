#ifndef _VARIABLEPROJECTOR_H
#define _VARIABLEPROJECTOR_H

#include "VariableProjection.h"

class FitModel
{
   public: 
      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int ada(double *a, double *b, double *kap, const double *alf, int irf_idx, int isel, int thread) = 0;
};


class VariableProjector
{

public:
   VariableProjector(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t);
   ~VariableProjector();

   int Fit(int s, int n, float* y, float *w, int* irf_idx, double *alf, double *lin_params, int thread, int itmax, double chi2_factor, int& niter, int &ierr, double& c2);

   int GetLinearParams(int s, float* y, int* irf_idx, double* alf, double* beta, double* chi2);
   int GetFit(int s, float* y, int* irf_idx, double* alf, float* adjust, double* fit);

private:

   int Init();

   int varproj(int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag);   
   int varproj_local(int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag);   
   void jacb_row(int s, double *kap, double* r__, int d_idx, double* res, double* derv);
   
   int postpr(int s, double *beta);
   int bacsub(double *x);

   double d_sign(double *a, double *b);

   FitModel* model;

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
   int    *irf_idx;
   int thread;
   double chi2_factor;
   double* cur_chi2;

   friend int VariableProjectorCallback(void *p, int m, int n, const double *x, double *fnorm, double *fjrow, int iflag);
};


#endif