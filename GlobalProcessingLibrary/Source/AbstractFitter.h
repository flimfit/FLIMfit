#ifndef _ABSTRACTFITTER_H
#define _ABSTRACTFITTER_H

#include "levmar.h"

class FitModel
{
   public: 
      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int ada(double *a, double *b, double *kap, const double *alf, int irf_idx, int isel, int thread) = 0;
};

class AbstractFitter
{
public:

   AbstractFitter(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t, int variable_phi, int* terminate);
   virtual ~AbstractFitter();

   virtual int Fit(int n, int s, float* y, float *w, int* irf_idx, double *alf, double *lin_params, double *chi2, int thread, int itmax, double chi2_factor, int& niter, int &ierr, double& c2) = 0;
   int GetFit(int irf_idx, double* alf, double* lin_params, float* adjust, double* fit);

protected:

   int Init();

   FitModel* model;

   int* terminate;

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
   double *lin_params;
   double *chi2;
   double *t;
   int    *irf_idx;

   double chi2_factor;
   double* cur_chi2;

   int variable_phi;

   int thread;

};

#endif _ABSTRACTFITTER_H