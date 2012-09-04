
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
   weighting = AVERAGE_WEIGHTING;

   iterative_weighting = (weighting > AVERAGE_WEIGHTING) | variable_phi;

   work = new double[nmax * n_thread];

   aw   = new double[ nmax * (l+1) * n_thread ]; //free ok
   bw   = new double[ ndim * ( p_full + 3 ) * n_thread ]; //free ok
   wp   = new double[ nmax * n_thread ];


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
   delete[] work;
   delete[] aw;
   delete[] bw;
   delete[] wp;

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

   n_call = 0;
   varproj(nsls1, nl, alf, &rnorm, fjac, 0);
   n_call = 1;

   info = lmstx(VariableProjectorCallback, (void*) this, nsls1, nl, alf, fjac, nl,
                 ftol, xtol, gtol, itmax, diag, 1, factor, -1,
                 &nfev, niter, &rnorm, ipvt, qtf, wa1, wa2, wa3, wa4 );

   // Get linear parameters
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
   int get_lin;
   int isel;

   int is, i, j, m, d_idx;
   double *rs;

   int lnls = l + nls + s;
   int lps  = l + s;
   int nml  = n - l; 

   // Matrix dimensions
   int r_dim1 = n;
   int y_dim1 = nmax;
   int a_dim1 = n;
   int b_dim1 = ndim;
   int t_dim1 = nmax;
   int u_dim1 = l;

   double r_sq, rj_norm, acum;

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
   default:
      firstca = 0;
      firstcb = 0;
   }  

   if (isel == 3)
   {
      GetModel(alf, irf_idx[0], isel, 0);

      // Set kappa derivatives
      *rnorm = kap[0];
      for(int k=0; k<nl; k++)
         fjrow[k] = kap[k+1];
      
      return 0;
   } 
   else if (isel > 3)
   {
      int omp_thread = 0;

      d_idx = isel - 4;
      i = d_idx % nml + l;
      is = d_idx / nml;

      rs = r + is * r_dim1;

      if (d_idx % nml == 0)
      {
         if (iterative_weighting)
         {
            CalculateWeights(is, alf, omp_thread); 
            transform_ab(isel, is, omp_thread, firstca, firstcb);
         }
         bacsub(is, aw, rs);
      }

      m = 0;
      for (int k = 0; k < nl; ++k)
      {
         acum = (float)0.;
         for (j = 0; j < l; ++j) 
         {
            if (inc[k + j * 12] != 0) 
            {
               acum += bw[i + m * b_dim1] * rs[j];
               ++m;
            }
         }

         if (inc[k + l * 12] != 0)
         {   
            acum += bw[i + m * b_dim1];
            ++m;
         }

         fjrow[k] = -acum;
      }

      *rnorm = rs[i];

      return 0;
   }
      

   if (!variable_phi)
      GetModel(alf, irf_idx[0], isel, 0);
   if (!iterative_weighting)
      CalculateWeights(0, alf, 0);

   if (!variable_phi && !iterative_weighting)
      transform_ab(isel, 0, 0, firstca, firstcb);


   #pragma omp parallel for reduction(+:r_sq)
   for (int j=0; j<s; j++)
   {
      int idx;
      int omp_thread = omp_get_thread_num();
      
      double* rj = r + j * r_dim1;
      int k, kp1;
      double beta, acum;
    
      double *aw, *u, *work, *wp;
      if (iterative_weighting)
         idx = omp_thread;
      else
         idx = 0;

      aw = this->aw + idx * nmax * (l+1);
      wp = this->wp + idx * nmax;
      u  = this->u + idx * l;

      work = this->work + omp_thread * nmax;

      if (variable_phi)
         GetModel(alf, irf_idx[j], isel, omp_thread);
      if (iterative_weighting)
         CalculateWeights(j, alf, omp_thread); 
      
      if (variable_phi | iterative_weighting)
         transform_ab(isel, j, omp_thread, firstca, firstcb);

      // Get the data we're about to transform
      if (!philp1)
      {
         for (int i=0; i < n; ++i)
            rj[i] = y[i + j * y_dim1] * wp[i];
      }
      else
      {
         // Store the data in rj, subtracting the column l+1 which does not
         // have a linear parameter
         for(int i=0; i < n; ++i)
            rj[i] = y[i + j * y_dim1] * wp[i] - aw[i + l * a_dim1];
      }

      // Transform Y, getting Q*Y=R 
      for (k = 0; k < l; ++k) 
      {
         kp1 = k + 1;
         beta = -aw[k + k * a_dim1] * u[k];

         acum = u[k] * rj[k];

         for (int i = kp1; i < n; ++i) 
            acum += aw[i + k * a_dim1] * rj[i];
         acum /= beta;

         rj[k] -= u[k] * acum;
         for (int i = kp1; i < n; ++i) 
            rj[i] -= aw[i + k * a_dim1] * acum;
      }

      rj_norm = enorm(n-l, rj+l);
      r_sq += rj_norm * rj_norm;

      //if (get_lin)
      if (get_lin | (weighting == MODEL_WEIGHTING))
         get_linear_params(j, aw, u, work);

   } // loop over pixels


   // Compute the norm of the residual matrix
   *cur_chi2 = r_sq * smoothing * chi2_factor / s;

   r_sq += kap[0] * kap[0];
   *rnorm = sqrt(r_sq);

   n_call++;

   if (isel < 0)
      iflag = isel;
   return iflag;
}


void VariableProjector::CalculateWeights(int px, const double* alf, int omp_thread)
{
   float*  y = this->y + px * nmax;
   double* wp = this->wp + omp_thread * nmax;

   if (weighting == AVERAGE_WEIGHTING)
   {
      for (int i=0; i<n; i++)
         wp[i] = w[i];
      return;
   }
   else if (weighting == PIXEL_WEIGHTING)
   {
      for (int i=0; i<n; i++)
         wp[i] = y[i];
   }
   else // MODEL_WEIGHTING
   {
      double *a;
      if (variable_phi)
         a  = this->a + omp_thread * nmax * lp1;
      else
         a = this->a;

      float *lin_params;
      if (n_call == 0)
         lin_params = NULL;
      else
         lin_params = this->lin_params + px*l;


      if (n_call == 0)
      {
         for (int i=0; i<n; i++)
               wp[i] = y[i];
      }
      else
      {
         double *a;
         if (variable_phi)
            a  = this->a + omp_thread * nmax * lp1;
         else
            a = this->a;
      
         for(int i=0; i<n; i++)
         {
            wp[i] = 0;
            for(int j=0; j<l; j++)
               wp[i] += a[n*j+i] * lin_params[j];
            wp[i] += a[n*l+i];
         }
      }
   }

   model->GetWeights(y, a, alf, lin_params, wp, irf_idx[px], thread);

   for(int i=0; i<n; i++)
   {
      if (wp[i] <= 0)
         wp[i] = 1e-4;
      else
         wp[i] = sqrt(1/wp[i]);
   }
}


void VariableProjector::transform_ab(int& isel, int px, int omp_thread, int firstca, int firstcb)
{
   int a_dim1 = n;
   int b_dim1 = ndim;
   int u_dim1 = l;
   
   double beta, acum;
   double alpha, d__1;

   int i, m, k, kp1;

   double *a, *b, *u, *aw, *bw, *wp;
   aw = this->aw + omp_thread * nmax * lp1;
   bw = this->bw + omp_thread * ndim * ( p_full + 3 );
   u  = this->u  + omp_thread * l;
   wp = this->wp + omp_thread * nmax;
      
   if (variable_phi)
   {
      a  = this->a + omp_thread * nmax * lp1;
      b  = this->b + omp_thread * ndim * ( p_full + 3 );
   }
   else
   {
      a = this->a;
      b = this->b;
   }
   
   if (firstca >= 0)
      for (m = firstca; m < lp1; ++m)
         for (int i = 0; i < n; ++i)
            aw[i + m * a_dim1] = a[i + m * a_dim1] * wp[i];

   if (firstcb >= 0)
      for (m = firstcb; m < p; ++m)
         for (int i = 0; i < n; ++i)
            bw[i + m * b_dim1] = b[i + m * b_dim1] * wp[i];

   // Compute orthogonal factorisations by householder reflection (phi)
   for (k = 0; k < l; ++k) 
   {
      kp1 = k + 1;

      // If *isel=1 or 2 reduce phi (first l columns of a) to upper triangular form
      if (firstca >= 0)
      {
         d__1 = enorm(n-k, &aw[k + k * a_dim1]);
         alpha = d_sign(&d__1, &aw[k + k * a_dim1]);
         u[k] = aw[k + k * a_dim1] + alpha;
         aw[k + k * a_dim1] = -alpha;
         firstca = kp1;
         if (alpha == (float)0.)
         {
            isel = -8;
            //goto L99;
         }
      }

      beta = -aw[k + k * a_dim1] * u[k];

      // Compute householder reflection of phi
      if (firstca >= 0)
      {
         for (m = firstca; m < l; ++m)
         {
            acum = u[k] * aw[k + m * a_dim1];

            for (i = kp1; i < n; ++i) 
               acum += aw[i + k * a_dim1] * aw[i + m * a_dim1];
            acum /= beta;

            aw[k + m * a_dim1] -= u[k] * acum;
            for (i = kp1; i < n; ++i) 
               aw[i + m * a_dim1] -= aw[i + k * a_dim1] * acum;
         }
      }

      // Transform J=D(phi)
      if (firstcb >= 0) 
      {
         for (m = 0; m < p; ++m)
         {
            acum = u[k] * bw[k + m * b_dim1];
            for (i = k; i < n; ++i) 
               acum += aw[i + k * a_dim1] * bw[i + m * b_dim1];
            acum /= beta;

            bw[k + m * b_dim1] -= u[k] * acum;
            for (i = k; i < n; ++i) 
               bw[i + m * b_dim1] -= aw[i + k * a_dim1] * acum;
         }
      }

   } // first k loop
}





void VariableProjector::get_linear_params(int idx, double* a, double* u, double* x)
{
   // Get linear parameters
   // Overwrite rj unless x is specified (length n)

   int i, k, kback;
   double acum;

   int a_dim1 = n;
   int r_dim1 = n;
   int u_dim1 = l;
   
   double* rj = r + idx * n;

   chi2[idx] = enorm(n-l, rj+l); 
   chi2[idx] *= chi2[idx] * chi2_factor * smoothing;

   bacsub(idx, a, x);
   
   for (kback = 0; kback < l; ++kback) 
   {
      k = l - kback - 1;
      acum = 0;

      for (i = k; i < n; ++i) 
         acum += a[i + k * a_dim1] * x[i];   

      lin_params[k + idx * u_dim1] = x[k];

      x[k] = acum / a[k + k * a_dim1];
      acum = -acum / (u[k] * a[k + k * a_dim1]);

      for (i = k+1; i < n; ++i) 
         x[i] -= a[i + k * a_dim1] * acum;
   }
}


int VariableProjector::bacsub(int idx, double *a, double *x)
{
   int a_dim1;
   int i, j, iback;
   double acum;

   double* rj = r + idx * n;

   // BACKSOLVE THE N X N UPPER TRIANGULAR SYSTEM A*RJ = B. 
   // THE SOLUTION IS STORED IN X (X MAY OVERWRITE RJ IF SPECIFIED)

   a_dim1 = n;

   x[l-1] = rj[l-1] / a[l-1 + (l-1) * a_dim1];
   if (l > 1) 
   {

      for (iback = 1; iback < l; ++iback) 
      {
         // i = N-1, N-2, ..., 2, 1
         i = l - iback - 1;
         acum = rj[i];
         for (j = i+1; j < l; ++j) 
            acum -= a[i + j * a_dim1] * x[j];
         
         x[i] = acum / a[i + i * a_dim1];
      }
   }

   return 0;
}
