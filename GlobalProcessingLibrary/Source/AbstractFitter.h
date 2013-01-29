//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================

#ifndef _ABSTRACTFITTER_H
#define _ABSTRACTFITTER_H

#include "levmar.h"

class FitModel
{
   public: 
      virtual void SetupIncMatrix(int* inc) = 0;
      virtual int CalculateModel(double *a, double *b, double *kap, const double *alf, int irf_idx, int isel, int thread) = 0;
      virtual void GetWeights(float* y, double* a, const double* alf, float* lin_params, double* w, int irf_idx, int thread) = 0;
};

class AbstractFitter
{
public:

   AbstractFitter(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t, int variable_phi, int n_thread, int* terminate);
   virtual ~AbstractFitter();
   virtual int FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr, double* c2) = 0;
   virtual int GetLinearParams(int s, float* y, double* alf) = 0;
   
   int Fit(int n, int s, int lmax, float* y, float *w, int* irf_idx, double *alf, float *lin_params, float *chi2, int thread, int itmax, double chi2_factor, int& niter, int &ierr, double& c2);
   int GetFit(int n_meas, int irf_idx, double* alf, float* lin_params, float* adjust, double counts_per_photon, double* fit);
   double ErrMinFcn(double x);
   int CalculateErrors(double* alf, double* err);

   void GetParams(int nl, const double* alf);
   void GetModel(const double* alf, int irf_idx, int isel, int thread);
   void ReleaseResidualMemory();

   int err;


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
   double *r;
   double *b;
   double *u;
   double *kap;
   double *params;
   double *alf_err;

   int     n;
   int     s;
   int     l;
   int     lmax;
   int     nl;
   int     p;
   int     p_full;

   int     smax;
   int     nmax;
   int     ndim;

   int     lp1;

   float  *y;
   float  *w;
   float *lin_params;
   float *chi2;
   double *t;
   int    *irf_idx;

   double chi2_factor;
   double smoothing;
   double* cur_chi2;

   int n_thread;
   int variable_phi;

   int thread;

   int    fixed_param;
   double fixed_value_initial;
   double fixed_value_cur;
   double chi2_final;

   bool getting_errs;

};

#endif _ABSTRACTFITTER_H