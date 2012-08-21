#ifndef _MAXIMIUMLIKELIHOODFITTER_H
#define _MAXIMIUMLIKELIHOODFITTER_H

#include "AbstractFitter.h"

class MaximumLikelihoodFitter : public AbstractFitter
{
public:

   MaximumLikelihoodFitter(FitModel* model, int l, int nl, int nmax, int ndim, int p, double *t, int* terminate);
   ~MaximumLikelihoodFitter();

   //int Fit(int s, int n, float* y, float *w, int* irf_idx, double *alf, double *lin_params, double *chi2, int thread, int itmax, double chi2_factor, int& niter, int &ierr, double& c2);
   int FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr, double* c2);

   int GetFit(int irf_idx, double* alf, double* lin_params, float* adjust, double* fit);

private:

   int Init();

   void mle_funcs(double *alf, double *fvec, int nl, int nfunc);
   void mle_jacb(double *alf, double *fjac, int nl, int nfunc);

   // Buffers used by levmar algorithm
   double info[LM_INFO_SZ];
   double* dy;
   double* work;

   int nfunc;
   int nvar;

   friend void MLEfuncsCallback(double *alf, double *fvec, int nl, int nfunc, void* pa);
   friend void MLEjacbCallback(double *alf, double *fjac, int nl, int nfunc, void* pa);
};

#endif _MAXIMIUMLIKELIHOODFITTER_H