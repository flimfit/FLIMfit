//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================

#ifndef _VARIABLEPROJECTOR_H
#define _VARIABLEPROJECTOR_H

#include "AbstractFitter.h"

#define ANALYTICAL_DERV 0
#define NUMERICAL_DERV  1

class VariableProjector : public AbstractFitter
{

public:
   VariableProjector(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t, int variable_phi, int weighting, int n_thread, int* terminate);
   ~VariableProjector();

   int FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr, double* c2);

   int GetFit(int irf_idx, double* alf, float* lin_params, float* adjust, double* fit);

   int GetLinearParams(int s, float* y, double* alf); 

private:

   void Cleanup();

   int varproj(int nsls1, int nls, int mskip, const double *alf, double *rnorm, double *fjrow, int iflag);   
   
   void transform_ab(int& isel, int px, int thread, int firstca, int firstcb);

   void CalculateWeights(int px, const double* alf, int thread);

   void get_linear_params(int idx, double* a, double* u, double* x = 0);
   int bacsub(int idx, double* a, volatile double* x);
   int bacsub(volatile double *r, double *a, volatile double *x);

   double d_sign(double *a, double *b);

   double *work; 
   double *aw, *bw, *wp;

   // Buffers used by levmar algorithm
   double *fjac;
   double *fvec;
   double *diag;
   double *qtf;
   double *wa1, *wa2, *wa3, *wa4;
   int    *ipvt;
   
   double* r_buf;
 
   int n_call;

   int weighting;
   int iterative_weighting;

   int use_numerical_derv;

   friend int VariableProjectorDiffCallback(void *p, int m, int n, const double *x, double *fnorm, int iflag);
   friend int VariableProjectorCallback(void *p, int m, int n, int mskip, const double *x, double *fnorm, double *fjrow, int iflag);
};


#endif