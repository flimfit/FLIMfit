#ifndef _VARIABLEPROJECTOR_H
#define _VARIABLEPROJECTOR_H

#include "VariableProjection.h"

class FitModel
{
   public: 
      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int ada(double *a, double *b, double *kap, const double *alf, int isel, int thread) = 0;
};


class VariableProjector
{

public:
   VariableProjector(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t);
   ~VariableProjector();

   int Fit(int s, int n, float* y, float *w, double *alf, double *lin_params, int thread, int itmax, double chi2_factor, int& niter, int &ierr, double& c2);
   
   int varproj(int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag);
   int GetLinearParams(int s, float* y, double* alf, double* beta, double* chi2);
   int GetFit(int s, float* y, double* alf, float* adjust, double* fit);

private:

   int Init();
   
   void jacb_row(int s, double *kap, double* r__, int d_idx, double* res, double* derv);

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
   double *r__;

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

   int thread;
   double chi2_factor;

};

#endif