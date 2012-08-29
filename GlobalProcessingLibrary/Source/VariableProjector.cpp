
#define INVALID_INPUT -1

#include "VariableProjector.h"

#define CMINPACK_NO_DLL

#include "cminpack.h"
#include <math.h>
#include "util.h"

#include <boost/bind.hpp>
#include <boost/function.hpp>

#ifndef NO_OMP   
#include <omp.h>
#endif


VariableProjector::VariableProjector(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t, int variable_phi, int n_thread, int* terminate) : 
    AbstractFitter(model, smax, l, nl, nmax, ndim, p, t, variable_phi, n_thread, terminate)
{

   // Set up buffers for levmar algorithm
   //---------------------------------------------------
   int buf_dim = max(1,nl);
   
   fjac = new double[buf_dim * buf_dim];
   diag = new double[buf_dim];
   qtf  = new double[buf_dim];
   wa1  = new double[buf_dim];
   wa2  = new double[buf_dim];
   wa3  = new double[buf_dim];
   wa4  = new double[buf_dim];
   ipvt = new int[buf_dim];

   for(int i=0; i<nl; i++)
      diag[i] = 1;

}

VariableProjector::~VariableProjector()
{

   delete[] fjac;
   delete[] diag;
   delete[] qtf;
   delete[] wa1;
   delete[] wa2;
   delete[] wa3;
   delete[] wa4;
   delete[] ipvt;
   
}


int VariableProjectorCallback(void *p, int m, int n, const double *x, double *fnorm, double *fjrow, int iflag)
{
   VariableProjector *vp = (VariableProjector*) p;
   return vp->varproj(m, n, x, fnorm, fjrow, iflag);
}


int VariableProjector::FitFcn(int nl, double *alf, int itmax, int* niter, int* ierr, double* c2)
{
   int nsls1 = (n-l) * s;
 
   double ftol = sqrt(dpmpar(1));
   double xtol = sqrt(dpmpar(1));
   double gtol = 0.;
   double factor = 1;

   int    maxfev = itmax;

   int nfev, info;
   double rnorm; 

   info = lmstx(VariableProjectorCallback, (void*) this, nsls1, nl, alf, fjac, nl,
                 ftol, xtol, gtol, itmax, diag, 1, factor, -1,
                 &nfev, niter, &rnorm, ipvt, qtf, wa1, wa2, wa3, wa4 );

   if (!getting_errs)
      varproj(nsls1, nl, alf, &rnorm, fjac, -1);

   if (info < 0)
      *ierr = info;
   else
      *ierr = *niter;
   return 0;

}


double VariableProjector::d_sign(double *a, double *b)
{
   double x;
   x = (*a >= 0 ? *a : - *a);
   return( *b >= 0 ? x : -x);
}




int VariableProjector::varproj(int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag)
{
   int firstca, firstcb;

   int process_phi;

   int get_lin;

   int isel;

   int     lnls = l + nls + s;
   int     lps  = l + s;

   // Matrix dimensions
   int r_dim1 = n;
   int y_dim1 = nmax;
   int a_dim1 = n;
   int b_dim1 = ndim;
   int t_dim1 = nmax;
   int u_dim1 = l;

   double r_sq, rj_norm;

/*     ============================================================== */

/*        COMPUTE THE NORM OF THE RESIDUAL (IF ISEL = 1 OR 2), OR THE */
/*        (N-L) X NL X S DERIVATIVE OF THE MODIFIED RESIDUAL (N-L) BY S */
/*        MATRIX Q2*Y (IF ISEL = 1 OR 3).  HERE Q * PHI = TRI, I.E., */

/*         L     ( Q1 ) (     .   .        )   (TRI . R1 .  F1  ) */
/*               (----) ( PHI . Y . D(PHI) ) = (--- . -- . ---- ) */
/*         N-L   ( Q2 ) (     .   .        )   ( 0  . R2 .  F2  ) */

/*                 N       L    S      P         L     S     P */

/*        WHERE Q IS N X N ORTHOGONAL, AND TRI IS L X L UPPER TRIANGULAR. */
/*        THE NORM OF THE RESIDUAL = FROBENIUS NORM(R2), AND THE DESIRED */
/*        DERIVATIVE ACCORDING TO REF. (5), IS */
/*                                                 -1 */
/*                    D(Q2 * Y) = -Q2 * D(PHI)* TRI  * Q1* Y. */

/*        THE THREE-TENSOR DERIVATIVE IS STORED IN COLUMNS L+S+1 THROUGH */
/*        L+S+NL AND ROWS L+1 THROUGH S*N - (S-1)*L OF THE MATRIX A. */
/*        THE MATRIX SLAB OF THE DERIVATIVE CORRESPONDING TO THE K'TH */
/*        RIGHT HAND SIDE (FOR K=1,2,...,S) IS IN ROWS L+(K-1)*(N-L)+1 */
/*        THROUGH L+K*(N-L). */

/*     .................................................................. */

   get_lin = false;

   if (iflag == -1)
   {
      isel = 2;
      get_lin = true;
   }
   else
   {
      isel = iflag + 1;

      if (*terminate)
         return -9;
   }

   // If isel > 3 then get the derivate for the isel-4 dataset
   if (isel > 3)
   {
      jacb_row(s, nls, kap, r, isel - 4, rnorm, fjrow);
      return iflag;
   }

   process_phi = true;
   r_sq = 0;

   switch (isel)
   {
   case 1:
      firstca = 0;
      firstcb = 0;
      break;
   case 2:
      firstca = 0;
      firstcb = -1;
      break;
   case 3:
      firstca = -1;
      firstcb = 0;
   }  

   if (!variable_phi)
      transform_ab(alf, irf_idx[0], isel, 0, firstca, firstcb, a, b, u);


   #pragma omp parallel for reduction(+:r_sq)
   for (int j=0; j<s; j++)
   {
      int thread = omp_get_thread_num();
      
      double* rj = r + j * r_dim1;
      int k, kp1;
      double beta, acum;
    
      double *a, *b, *u;
      if (variable_phi)
      {
         a = this->a + thread * nmax * (l+1);
         b = this->b + thread * ndim * ( p_full + 3 );
         u = this->u + thread * l;
      }
      else
      {
         a = this->a;
         b = this->b;
         u = this->u;         
      }

      if (variable_phi)
         transform_ab(alf, irf_idx[j], isel, thread, firstca, firstcb, a, b, u);

      // Get the data we're about to transform
      if (isel < 3) 
      {
         if (!philp1)
         {
            for (int i = 0; i < n; ++i)
               rj[i] = y[i + j * y_dim1];
         }
         else
         {
            // Store the data in r__, subtracting the column l+1 which does not
            // have a linear parameter
            for(int i=0; i < n; ++i)
               rj[i] = y[i + j * y_dim1] - a[i + l * a_dim1];
         }

         for (int i = 0; i < n; ++i)
            rj[i] *= w[i];
      }

      if (l > 0)
      {
         // Transform Y, getting Q*Y=R 
         if (firstca >= 0)
         {
            for (k = 0; k < l; ++k) 
            {
               kp1 = k + 1;
               beta = -a[k + k * a_dim1] * u[k];

               acum = u[k] * rj[k];

               for (int i = kp1; i < n; ++i) 
                  acum += a[i + k * a_dim1] * rj[i];
               acum /= beta;

               rj[k] -= u[k] * acum;
               for (int i = kp1; i < n; ++i) 
                  rj[i] -= a[i + k * a_dim1] * acum;
            }

            rj_norm = enorm(n-l, rj+l);
            r_sq += rj_norm * rj_norm;

         }

         if (get_lin)
            get_linear_params(j, a, u);
         
         if (isel == 3)
            bacsub(j, a);

      }

   } // loop over pixels


   // Compute the norm of the residual matrix
   if (isel < 3)
   {
      *cur_chi2 = r_sq * smoothing * chi2_factor / s;

      r_sq += kap[0] * kap[0];
      *rnorm = sqrt(r_sq);
   }

   // Set kappa derivatives
   if (isel == 3)
   {
      *rnorm = kap[0];
      for(int k=0; k<nls; k++)
         fjrow[k] = kap[k+1];
   }

   if (isel < 0)
      iflag = isel;
   return iflag;
}



void VariableProjector::transform_ab(const double *alf, int irf_idx, int& isel, int thread, int firstca, int firstcb, double* a, double* b, double *u)
{
   int a_dim1 = n;
   int b_dim1 = ndim;
   int u_dim1 = l;
   
   double beta, acum;
   double alpha, d__1;

   int i, m, k, kp1;

   CallADA(alf, irf_idx, isel, thread);

   if (firstca >= 0)
      for (m = firstca; m < l; ++m)
         for (int i = 0; i < n; ++i)
            a[i + m * a_dim1] *= w[i];

   if (firstcb >= 0)
      for (m = firstcb; m < p; ++m)
         for (int i = 0; i < n; ++i)
            b[i + m * b_dim1] *= w[i];

   if (l > 0)
   {
   // Compute orthogonal factorisations by householder reflection (phi)
      for (k = 0; k < l; ++k) 
      {
         kp1 = k + 1;

         // If *isel=1 or 2 reduce phi (first l columns of a) to upper triangular form
         if (isel <= 2) // && !(isel == 2 && k<ncon))
         {
            d__1 = enorm(n-k, &a[k + k * a_dim1]);
            alpha = d_sign(&d__1, &a[k + k * a_dim1]);
            u[k] = a[k + k * a_dim1] + alpha;
            a[k + k * a_dim1] = -alpha;
            firstca = kp1;
            if (alpha == (float)0.)
            {
               isel = -8;
               //goto L99;
            }
         }

         beta = -a[k + k * a_dim1] * u[k];

         // Compute householder reflection of phi
         if (firstca >= 0)
         {
            for (m = firstca; m < l; ++m)
            {
               acum = u[k] * a[k + m * a_dim1];

               for (i = kp1; i < n; ++i) 
                  acum += a[i + k * a_dim1] * a[i + m * a_dim1];
               acum /= beta;

               a[k + m * a_dim1] -= u[k] * acum;
               for (i = kp1; i < n; ++i) 
                  a[i + m * a_dim1] -= a[i + k * a_dim1] * acum;
            }
         }

         // Transform J=D(phi)
         if (firstcb >= 0) 
         {
            for (m = 0; m < p; ++m)
            {
               acum = u[k] * b[k + m * b_dim1];
               for (i = k; i < n; ++i) 
                  acum += a[i + k * a_dim1] * b[i + m * b_dim1];
               acum /= beta;

               b[k + m * b_dim1] -= u[k] * acum;
               for (i = k; i < n; ++i) 
                  b[i + m * b_dim1] -= a[i + k * a_dim1] * acum;
            }
         }

      } // first k loop
   }
}





void VariableProjector::get_linear_params(int idx, double* a, double* u)
{
   int i, k, kback;
   double acum;

   int a_dim1 = n;
   int r_dim1 = n;
   int u_dim1 = l;
   
   double* r__ = r + idx * n;

   chi2[idx] = enorm(n-l, r__+l); 
   chi2[idx] *= chi2[idx] * chi2_factor * smoothing;

   bacsub(idx, a);
   for (kback = 0; kback < l; ++kback) 
   {
      k = l - kback - 1;
      acum = 0.;

      for (i = k; i < n; ++i) 
      {
         acum += a[i + k * a_dim1] * r__[i];   
      }
      lin_params[k + idx * u_dim1] = r__[k];
      r__[k] = acum / a[k + k * a_dim1];
      acum = -acum / (u[k] * a[k + k * a_dim1]);

      for (i = k+1; i < n; ++i) 
      {
         r__[i] -= a[i + k * a_dim1] * acum;
      }
   }
}






void VariableProjector::jacb_row(int s, int nls, double *kap, double* r__, int d_idx, double* res, double* derv)
{
   int m, k, j, b_dim1, r_dim1;
   double acum;

      /*           MAJOR PART OF KAUFMAN'S SIMPLIFICATION OCCURS HERE.  COMPUTE */
      /*           THE DERIVATIVE OF ETA WITH RESPECT TO THE NONLINEAR */
      /*           PARAMETERS */

      /*   T   D ETA        T    L          D PHI(J)    D PHI(L+1) */
      /*  Q * --------  =  Q * (SUM BETA(J) --------  + ----------)  =  F2*BETA */
      /*      D ALF(K)          J=1         D ALF(K)     D ALF(K) */

      /*           AND STORE THE RESULT IN COLUMNS L+S+1 TO L+NL+S.  THE */
      /*           FIRST L ROWS ARE OMITTED.  THIS IS -D(Q2)*Y.  THE RESIDUAL */
      /*           R2 = Q2*Y (IN COLUMNS L+1 TO L+S) IS COPIED TO COLUMN */
      /*           L+NL+S+1. */

   b_dim1 = ndim;
   r_dim1 = n;

   int lps = l+s;
   int nml = n-l;
      
   int i = d_idx % nml + l;
   int isback = d_idx / nml; 
   int is = s - isback - 1;
   
   m = 0;
   for (k = 0; k < nls; ++k)
   {
      acum = (float)0.;
      for (j = 0; j < l; ++j) 
      {
         if (inc[k + j * 12] != 0) 
         {
            acum += b[i + m * b_dim1] * r__[j + is * r_dim1];
            ++m;
         }
      }

      if (inc[k + l * 12] != 0)
      {   
         acum += b[i + m * b_dim1];
         ++m;
      }

      derv[k] = -acum;
   }

   *res = r__[i+is*r_dim1];
}


int VariableProjector::bacsub(int idx, double *a)
{
   int a_dim1;
   int i, j, iback;
   double acum;

   double* x = r + idx * n;

/*        BACKSOLVE THE N X N UPPER TRIANGULAR SYSTEM A*X = B. */
/*        THE SOLUTION X OVERWRITES THE RIGHT SIDE B. */

   a_dim1 = n;

   x[l-1] /= a[l-1 + (l-1) * a_dim1];
   if (l > 1) 
   {

      for (iback = 1; iback < l; ++iback) 
      {
      /*           I = N-1, N-2, ..., 2, 1 */
         i = l - iback - 1;
         acum = x[i];
         for (j = i+1; j < l; ++j) 
            acum -= a[i + j * a_dim1] * x[j];
         
         x[i] = acum / a[i + i * a_dim1];
      }
   }

   return 0;
}


int VariableProjector::GetFit(int irf_idx, double* alf, double* lin_params, float* adjust, double* fit)
{
   //model->ada(a, b, kap, alf, 0, 1, 0);

   int idx = 0;
   model->ada(a, b, kap, alf, irf_idx, 1, 0);

   for(int i=0; i<n; i++)
   {
      fit[idx] = adjust[i];
      for(int j=0; j<l; j++)
         fit[idx] += a[n*j+i] * lin_params[j];

      fit[idx++] += a[n*l+i];
   }

   return 0;

}

