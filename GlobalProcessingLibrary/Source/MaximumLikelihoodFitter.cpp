#include "MaximumLikelihoodFitter.h"

#include <cfloat>
#include <math.h>
#include <string.h>

#include "levmar.h"
#include "util.h"


void MLEfuncsCallback(double *alf, double *fvec, int nl, int nfunc, void* pa)
{
   MaximumLikelihoodFitter* f = (MaximumLikelihoodFitter*) pa;
   f->mle_funcs(alf,fvec,nl,nfunc);
}

void MLEjacbCallback(double *alf, double *fjac, int nl, int nfunc, void* pa)
{
   MaximumLikelihoodFitter* f = (MaximumLikelihoodFitter*) pa;
   f->mle_jacb(alf,fjac,nl,nfunc);
}


MaximumLikelihoodFitter::MaximumLikelihoodFitter(FitModel* model, int l, int nl, int nmax, int ndim, int p, double *t, int* terminate) : 
    AbstractFitter(model, 1, l, nl, nmax, ndim, p, t, false, 1, terminate)
{
   nfunc = nmax + 1; // +1 for kappa
   nvar = nl;

   dy = new double[nfunc];
   work = new double[ LM_DER_WORKSZ(nvar, nfunc) ];
}



//int MaximumLikelihoodFitter::Fit(int s, int n, float* y, float *w, int* irf_idx, double *alf, float *lin_params, float *chi2, int thread, int itmax, double chi2_factor, int& niter, int &ierr, double& c2)
int MaximumLikelihoodFitter::FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr, double* c2)
{

   //chi2_factor = chi2_factor/(n-nl);

   for(int i=0; i<n; i++)
      dy[i] = y[i] * smoothing;
   dy[n] = 1;
   
    
    double* err = new double[nfunc];
    dlevmar_chkjac(MLEfuncsCallback, MLEjacbCallback, alf, nvar, nfunc, this, err);
    err[0] = err[0];
    delete[] err;
    
/*    
   double opt[4];
   opt[0] = DBL_EPSILON;
   opt[1] = DBL_EPSILON;
   opt[2] = DBL_EPSILON;
   opt[3] = DBL_EPSILON;
   */
   int ret = dlevmar_der(MLEfuncsCallback, MLEjacbCallback, alf, dy, nvar, n+1, itmax, NULL, info, work, NULL, this);

   					           /* O: information regarding the minimization. Set to NULL if don't care
                      * info[0]= ||e||_2 at initial p.
                      * info[1-4]=[ ||e||_2, ||J^T e||_inf,  ||Dp||_2, mu/max[J^T J]_ii ], all computed at estimated p.
                      * info[5]= # iterations,
                      * info[6]=reason for terminating: 1 - stopped by small gradient J^T e
                      *                                 2 - stopped by small Dp
                      *                                 3 - stopped by itmax
                      *                                 4 - singular matrix. Restart from current p with increased mu 
                      *                                 5 - no further error reduction is possible. Restart with increased mu
                      *                                 6 - stopped by small ||e||_2
                      *                                 7 - stopped by invalid (i.e. NaN or Inf) "func" values. This is a user error
                      * info[7]= # function evaluations
                      * info[8]= # Jacobian evaluations
                      * info[9]= # linear systems solved, i.e. # attempts for reducing error
*/
   for(int i=0; i<l; i++)
      lin_params[i] = (float) (exp(alf[nl-l+i]) / smoothing);

   chi2[0] = (float) (info[1] * chi2_factor);



   if (ret < 0)
      *ierr = (int) info[6]; // reason for terminating
   else
      *ierr = (int) info[5]; // number of interations
   return 0;

}




void MaximumLikelihoodFitter::mle_funcs(double *alf, double *fvec, int nl, int nfunc)
{
   int i,j;

   GetModel(alf, 0, 1, 0);
   
   int gnl = nl-l;
   double* A = alf+gnl;

   memset(fvec,0,nfunc*sizeof(double));

   for (i=0; i<n; i++)
      for(j=0; j<l; j++)
      fvec[i] += exp(A[j])*a[i+n*j];

   if (philp1)
      for (i=0; i<n; i++)
         fvec[i] += a[i+n*l];
      

   fvec[n] = kap[0]+1;
}


void MaximumLikelihoodFitter::mle_jacb(double *alf, double *fjac, int nl, int nfunc)
{
   int i,j,k;

   int iflag = 1;

   GetModel(alf, 0, 1, 0);

   int gnl = nl-l;
   double* A = alf+gnl;

   memset(fjac,0,nfunc*nl*sizeof(double));

   int m = 0;
   for (k=0; k<gnl; k++)
   {
      for(j=0; j<l; j++)
      {
         if (inc[k + j * 12] != 0)
         {
            for (i=0; i<n; i++)
               fjac[nl*i+k] += exp(A[j]) * b[ndim*m+i];
            fjac[nl*i+k] = kap[k+1];
            m++;
         }
      }
      if (inc[k + l * 12] != 0)
      {
         for (i=0; i<n; i++)
            fjac[nl*i+k] += b[ndim*m+i];
         fjac[nl*i+k] = kap[k+1];
         m++;
      }
   }
   // Set derv's for I
   for(j=0; j<l; j++)
   {
         for (i=0; i<n; i++)
            fjac[nl*i+j+gnl] = exp(A[j]) * a[i+n*j];
         fjac[nl*i+j+gnl] = 0; // kappa derv. for I
   }
}


MaximumLikelihoodFitter::~MaximumLikelihoodFitter()
{
   delete[] dy;
   delete[] work;
}