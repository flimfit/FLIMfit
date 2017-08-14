//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//  Includes code derived from VARP2 package by Prof. Randall LeVeque
//  http://www.netlib.org/opt/varp2
//
//=========================================================================

#define INVALID_INPUT -1

#include "VariableProjector.h"
#include "FlagDefinitions.h"
#include "DecayModel.h"
#include "util.h"

#define CMINPACK_NO_DLL

#include "cminpack.h"
#include <cmath>
#include <algorithm>
//#include "util.h"

using std::min;
using std::max;

#include <future>
#include <iostream>
#include "omp_stub.h"

#include "ConcurrencyAnalysis.h"

VariableProjector::VariableProjector(std::shared_ptr<DecayModel> model, int max_region_size, int weighting, int global_algorithm, int n_thread, std::shared_ptr<ProgressReporter> reporter) :
    AbstractFitter(model, 0, max_region_size, global_algorithm, n_thread, reporter), weighting(weighting)
{

   nnls = std::make_unique<NonNegativeLeastSquares>(l, n);

   use_numerical_derv = false;

   iterative_weighting = (weighting > AVERAGE_WEIGHTING) | variable_phi;

   n_jac_group = (int) ceil(1024.0 / (nmax-l));

   work_.resize(n_thread, std::vector<double>(nmax)); 
   aw_.resize(n_thread, std::vector<double>(nmax * (l + 1)));
   bw_.resize(n_thread, std::vector<double>(ndim * ( pmax + 3 )));
   wp_.resize(n_thread, std::vector<double>(nmax));
   u_.resize(n_thread, std::vector<double>(nmax));
   w.resize(nmax);

   r_buf_ = new double[ nmax * n_thread ];
   norm_buf_ = new double[ nmax * n_thread ];

   // Set up buffers for levmar algorithm
   //---------------------------------------------------
   int buf_dim = max(16,nl);
   
   diag = new double[buf_dim];
   qtf  = new double[buf_dim];
   wa1  = new double[buf_dim];
   wa2  = new double[buf_dim];
   wa3  = new double[buf_dim * nmax * n_jac_group];
   ipvt = new int[buf_dim];

   if (use_numerical_derv)
   {
      fjac = new double[nmax * max_region_size * n];
      wa4  = new double[nmax * max_region_size]; 
      fvec = new double[nmax * max_region_size];
   }
   else
   {
      fjac = new double[buf_dim * buf_dim];
      wa4 = new double[buf_dim];
      fvec = new double[nmax * n_jac_group];
   }

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
   delete[] fvec;
   delete[] r_buf_;
   delete[] norm_buf_;
}


int VariableProjectorCallback(void *p, int m, int n, int s_red, const double* x, double *fnorm, double *fjrow, int iflag, int thread)
{
   VariableProjector *vp = (VariableProjector*) p;
   vp->SetAlf(x);

   if (iflag == 0)
   {
      //return vp->getResidual(m, n, s_red, x, fnorm, fjrow, iflag, thread);
      return vp->getResidualNonNegative(m, n, s_red, x, fnorm, fjrow, iflag, thread);
   }
   else if (iflag == 1)
   {
      double fn;
      vp->getResidual(m, n, s_red, x, &fn, fjrow, iflag, thread);
      return vp->prepareJacobianCalculation(m, n, s_red, x, fnorm, fjrow, iflag, thread);
   }
   else
      return vp->getJacobianEntry(m, n, s_red, x, fnorm, fjrow, iflag - 2, thread);
}

int VariableProjectorDiffCallback(void *p, int m, int n, const double* x, double *fvec, int iflag)
{
   VariableProjector *vp = (VariableProjector*) p;
   vp->SetAlf(x);
   return vp->getResidual(m, n, 1, x, fvec, NULL, iflag, 0);
}



/*         info = 0  improper input parameters. */

/*         info = 1  both actual and predicted relative reductions */
/*                   in the sum of squares are at most ftol. */

/*         info = 2  relative error between two consecutive iterates */
/*                   is at most xtol. */

/*         info = 3  conditions for info = 1 and info = 2 both hold. */

/*         info = 4  the cosine of the angle between fvec and any */
/*                   column of the jacobian is at most gtol in */
/*                   absolute value. */

/*         info = 5  number of calls to fcn with iflag = 1 has */
/*                   reached maxfev. */

/*         info = 6  ftol is too small. no further reduction in */
/*                   the sum of squares is possible. */

/*         info = 7  xtol is too small. no further improvement in */
/*                   the approximate solution x is possible. */


/*         info = 8  gtol is too small. fvec is orthogonal to the */
/*                   columns of the jacobian to machine precision. */

void VariableProjector::FitFcn(int nl, std::vector<double>& alf, int itmax, int* niter, int* ierr)
{
   int nsls1 = (n-l); //(n-l) * s;
 
   double ftol = (double)sqrt(dpmpar(1));
   double xtol = (double)sqrt(dpmpar(1));
   double epsfcn = (double)sqrt(dpmpar(1));
   double gtol = 0.;
   double factor = 0.01;

   int nfev, info;
   double rnorm; 

   // Calculate weighting
   // If required use, gamma weighting from
   // "Parameter Estimation in Astronomy with Poisson-distributed Data"
   // Reference: http://iopscience.iop.org/0004-637X/518/1/380/

   using_gamma_weighting = false;
   fit_successful = false;

   if (weighting == AVERAGE_WEIGHTING)
   {
      for(int i=0; i<n; i++)
         if (avg_y[i] == 0.0f)
         {
            using_gamma_weighting = true;
            break;
         }
   }
   else if (weighting == PIXEL_WEIGHTING)
   {
      for(int i=0; i<s*n; i++)
         if (y[i] == 0.0f)
         {
            using_gamma_weighting = true;
            break;
         }
   }

   if (using_gamma_weighting)
   {
      for (int i=0; i<n; i++)
         w[i] = 1/sqrt(avg_y[i]+1.0f);
      
      for(int j=0; j<s; j++)
         for (int i=0; i < n; ++i)
               y[i + j * n] += min(y[i + j * n], 1.0f);
   }
   else if (weighting == MODEL_WEIGHTING)
   {
      // Fit the first time with Neymann weighting 
      // After first iteration will use model weighting
      for (int i=0; i<n; i++)
      {
         
         if (avg_y[i] == 0.0f)
            w[i] = 1.0;
         else
            w[i] = 1.0/sqrt(avg_y[i]);
      }
   }
   else
   {
      for (int i=0; i<n; i++)
         w[i] = 1/sqrt(avg_y[i]);
   }


   // Specifiy fraction of s to reduce jacobian
   int s_red = s;

   n_call = 0;

   if (iterative_weighting)
   {
      getResidual(nsls1, nl, s_red, alf.data(), fvec, fjac, 0, 0);
      n_call = 1;
   }

   if (false && weighting == AVERAGE_WEIGHTING && !getting_errs)
   {
      float* adjust = model->getConstantAdjustment();
      for(int j=0; j<s; j++)
         for (int i=0; i < n; ++i)
               y[i + j * n] = (y[i + j * n]-adjust[i]) * (float) w[i];
   }

   try
   {
      if (use_numerical_derv)
         info = lmdif(VariableProjectorDiffCallback, (void*) this, nsls1, nl, alf.data(), fvec,
            ftol, xtol, gtol, itmax, epsfcn, diag, 1, factor, -1,
            &nfev, fjac, nmax*max_region_size, ipvt, qtf, wa1, wa2, wa3, wa4);
      else
      {

         info = lmstx(VariableProjectorCallback, (void*) this, nsls1, nl, s_red, n_jac_group, alf.data(), fvec, fjac, nl,
            ftol, xtol, gtol, itmax, diag, 1, factor, -1, n_thread,
            &nfev, niter, &rnorm, ipvt, qtf, wa1, wa2, wa3, wa4);
      }

//      std::cout << "info: " << std::to_string(info) << "\n";

      // Get linear parameters
      if (info <= -8)
      {
         SetNaN(alf.data(), nl);
      }
      else
      {
         if (!getting_errs)
            getResidualNonNegative(nsls1, nl, s_red, alf.data(), fvec, fjac, -1, 0);
      }

      fit_successful = true;
   }
   catch (FittingError e)
   {
      info = e.code();
   }

   if (info < 0)
      *ierr = info;
   else
      *ierr = *niter;
}

void VariableProjector::GetLinearParams() 
{
   if (fit_successful)
   {
      int nsls1 = (n - l) * s;
      getResidual(nsls1, nl, 1, alf.data(), fvec, fjac, -1, 0);
   }   
}

double VariableProjector::d_sign(double *a, double *b)
{
   double x;
   x = (*a >= 0 ? *a : - *a);
   return( *b >= 0 ? x : -x);
}


int VariableProjector::prepareJacobianCalculation(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int isel, int thread)
{
   if (!variable_phi)
      GetModel(alf, irf_idx[0], 1, 0);
   if (!iterative_weighting)
      CalculateWeights(0, alf, 0);

   if (!variable_phi && !iterative_weighting)
      transformAB(0, 0);

   // Set kappa derivatives
   *rnorm = kap[0];
   for (int k = 0; k < nl; k++)
      fjrow[k] = kap[k + 1];

   return 0;
}

int VariableProjector::getJacobianEntry(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int isel, int thread)
{
   int nml = n - l;

   if (reporter->shouldTerminate())
      return -9;

   double* r_buf = r_buf_ + nmax*thread;

   int idx = (iterative_weighting) ? thread : 0;
   std::vector<double>& aw = aw_[idx];
   std::vector<double>& bw = bw_[idx];

   int mskip = s / s_red;
   int is = isel;

   for (int j = 0; j < n; j++)
      r_buf[j] = 0;

   int j_max = min(mskip, s - is*mskip);
   for (int j = 0; j < j_max; j++)
      for (int k = 0; k < n; k++)
         r_buf[k] +=  r[(is*mskip + j) * nmax + k];

   for (int j = 0; j < n; j++)
      r_buf[j] /= j_max;

   if (variable_phi)
      GetModel(alf, irf_idx[is], 1, thread);

   if (iterative_weighting)
      CalculateWeights(is, alf, thread);

   if (variable_phi | iterative_weighting)
      transformAB(is, thread);

   bacsub(r_buf, aw.data(), r_buf);

   for (int i = 0; i < nml; i++)
   {
      int ipl = i + l;
      int m = 0;
      for (int k = 0; k < nl; ++k)
      {
         double acum = (float)0.;
         for (int j = 0; j < l; ++j)
         {
            if (inc[k + j * 12] != 0)
            {
               acum += bw[ipl + m * ndim] * r_buf[j];
               ++m;
            }
         }

         if (inc[k + l * 12] != 0)
         {
            acum += bw[ipl + m * ndim];
            ++m;
         }

         fjrow[i*nl + k] = -acum;

      }
      rnorm[i] = r_buf[ipl];
   }
   return 0;
}


int VariableProjector::getResidualNonNegative(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread)
{
   int nml = n - l;
   int get_lin = false;

   if (iflag == -1)
      get_lin = true;

   if (reporter->shouldTerminate())
      return -9;

   double r_sq = 0;

   float* adjust = model->getConstantAdjustment();
   if (!variable_phi)
      GetModel(alf, irf_idx[0], 0, 0);
   if (!iterative_weighting)
      CalculateWeights(0, alf, 0);

   for (int i = 0; i<n_thread; i++)
      norm_buf_[i*nmax] = 0;

   //#pragma omp parallel for num_threads(n_thread)

   // We'll apply this for all pixels
   for (int j = 0; j < s; j++)
   {
      int omp_thread = 0; // omp_get_thread_num();

      double* rj = r.data() + j * nmax;
      float* yj = y + j * n;

      int idx = (iterative_weighting) ? omp_thread : 0;
      std::vector<double>& a = variable_phi ? a_[omp_thread] : a_[0];
      std::vector<double>& aw = aw_[idx];
      std::vector<double>& wp = wp_[idx];
      std::vector<double>& work = work_[omp_thread];

      float* linj = lin_params + idx * lmax;

      if (variable_phi)
         GetModel(alf, irf_idx[j], 0, omp_thread);
      if (iterative_weighting)
         CalculateWeights(j, alf, omp_thread);
     
      // Get the data we're about to transform
      if (!philp1)
      {
         for (int i = 0; i < n; i++)
            rj[i] = (yj[i] - adjust[i]) * wp[i];
      }
      else
      {
         // Store the data in rj, subtracting the column l+1 which does not
         // have a linear parameter
         for (int i = 0; i < n; i++)
            rj[i] = (yj[i] - adjust[i]) * wp[i] - a[i + l * nmax];
      }

      for (int k = 0; k < l; k++)
      {
         for (int i = 0; i < n; i++)
            aw[i + k*nmax] = a[i + k*nmax] * wp[i];
      }

      double rj_norm;
      nnls->compute(aw.data(), nmax, rj, work.data(), rj_norm);

      // Calcuate the norm of the jth column and add to residual
      norm_buf_[omp_thread*nmax] += rj_norm * rj_norm;

      if (use_numerical_derv)
         memcpy(rnorm + j*(n - l), rj + l, (n - l) * sizeof(double));

      if (get_lin | iterative_weighting)
         for (int i = 0; i < l; i++)
            lin_params[i+j*lmax] = work[i];

   } // loop over pixels

   for (int i = 0; i<n_thread; i++)
      r_sq += norm_buf_[i*nmax];

   // Compute the norm of the residual matrix
   *cur_chi2 = r_sq / (chi2_norm * s);

   if (!use_numerical_derv)
   {
      r_sq += kap[0] * kap[0];
      *rnorm = (double)sqrt(r_sq);
   }

   n_call++;

   return iflag;

}

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
int VariableProjector::getResidual(int nsls1, int nls, int s_red, const double* alf, double *rnorm, double *fjrow, int iflag, int thread)
{
   int nml  = n - l;
   int get_lin = false;

   if (iflag == -1)
      get_lin = true;

   if (reporter->shouldTerminate())
      return -9;

   double r_sq = 0;
      
   float* adjust = model->getConstantAdjustment();
   if (!variable_phi)
      GetModel(alf, irf_idx[0], 0, 0);
   if (!iterative_weighting)
      CalculateWeights(0, alf, 0);

   bool transformB = false;
   if (!variable_phi && !iterative_weighting)
      transformAB(0, 0, transformB);

   for(int i=0; i<n_thread; i++)
      norm_buf_[i*nmax] = 0;

   //#pragma omp parallel for num_threads(n_thread)
   
   // We'll apply this for all pixels
   for (int j = 0; j < s; j++)
   {
      int omp_thread = 0; // omp_get_thread_num();

      double* rj = r.data() + j * nmax;
      float* yj = y + j * n;
      double beta, acum;

      int idx = (iterative_weighting) ? omp_thread : 0;
      std::vector<double>& aw = aw_[idx];
      std::vector<double>& wp = wp_[idx];
      std::vector<double>& u = u_[idx];
      std::vector<double>& work = work_[omp_thread];

      if (variable_phi)
         GetModel(alf, irf_idx[j], 0, omp_thread);
      if (iterative_weighting)
         CalculateWeights(j, alf, omp_thread);

      if (variable_phi | iterative_weighting)
         transformAB(j, omp_thread, transformB);

      // Get the data we're about to transform
      if (!philp1)
      {
         for (int i = 0; i < n; i++)
            rj[i] = (yj[i] - adjust[i]) * wp[i];
      }
      else
      {
         // Store the data in rj, subtracting the column l+1 which does not
         // have a linear parameter
         for (int i = 0; i < n; i++)
            rj[i] = (yj[i] - adjust[i]) * wp[i] - aw[i + l * nmax];
      }

      // Transform Y, getting Q*Y=R 
      for (int k = 0; k < l; k++)
      {
         int kp1 = k + 1;
         beta = -aw[k + k * nmax] * u[k];
         acum = u[k] * rj[k];

         for (int i = kp1; i < n; ++i)
            acum += aw[i + k * nmax] * rj[i];
         acum /= beta;

         rj[k] -= u[k] * acum;
         for (int i = kp1; i < n; i++)
            rj[i] -= aw[i + k * nmax] * acum;
      }

      // Calcuate the norm of the jth column and add to residual
      double rj_norm = enorm(n - l, rj + l);
      norm_buf_[omp_thread*nmax] += rj_norm * rj_norm;

      if (use_numerical_derv)
         memcpy(rnorm + j*(n - l), rj + l, (n - l) * sizeof(double));

      // If we're model weighting we need the linear parameters
      // every time so we can calculate the model function, otherwise
      // just calculate them at the end when requested
      if (get_lin | iterative_weighting)
         get_linear_params(j, aw, u, work);

   } // loop over pixels
   
   for(int i=0; i<n_thread; i++)
      r_sq += norm_buf_[i*nmax];

   // Compute the norm of the residual matrix
   *cur_chi2 = r_sq / (chi2_norm * s);

   if (!use_numerical_derv)
   {
      r_sq += kap[0] * kap[0];
      *rnorm = (double)sqrt(r_sq);
   }

   n_call++;

   return iflag;
}

void VariableProjector::CalculateWeights(int px, const double* alf, int omp_thread)
{
   float*  y = this->y + px * n;
   std::vector<double>& wp = wp_[omp_thread];
   
   std::vector<double>& a = variable_phi ? a_[omp_thread] : a_[0];

   if (weighting == AVERAGE_WEIGHTING || n_call == 0)
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
      for(int i=0; i<n; i++)
      {
         wp[i] = 0;
         for(int j=0; j<l; j++)
            wp[i] += a[n*j+i] * lin_params[px*lmax+j];
         if (philp1)
            wp[i] += a[n*l+i];
      }
   }

   //if (n_call != 0) // TODO : add this back
   //   models[omp_thread].GetWeights(y, a, alf, lin_params+px*lmax, wp, irf_idx[px]);

   for(int i=0; i<n; i++)
   {
      if (wp[i] <= 0)
         wp[i] = 1.0;
      else
         wp[i] = sqrt(1.0/wp[i]);

   }
}

void VariableProjector::transformAB(int px, int omp_thread, bool transform_b)
{
   int lp1 = l + 1;

   double beta, acum;
   double alpha, d__1;

   int i, m, k, kp1;

   std::vector<double>& aw = aw_[omp_thread];
   std::vector<double>& bw = bw_[omp_thread];
   std::vector<double>& u = u_[omp_thread];
   std::vector<double>& wp = wp_[omp_thread];

   std::vector<double>& a = variable_phi ? a_[omp_thread] : a_[0];
   std::vector<double>& b = variable_phi ? b_[omp_thread] : b_[0];

   for (m = 0; m < lp1; ++m)
      for (int i = 0; i < n; ++i)
         aw[i + m * nmax] = a[i + m * nmax] * wp[i];

   if (transform_b)
      for (m = 0; m < p; ++m)
         for (int i = 0; i < n; ++i)
            bw[i + m * ndim] = b[i + m * ndim] * wp[i];

   // Compute orthogonal factorisations by householder reflection (phi)
   for (k = 0; k < l; ++k)
   {
      kp1 = k + 1;

      // If *isel=1 or 2 reduce phi (first l columns of a) to upper triangular form

      d__1 = enorm(n - k, &aw[k + k * nmax]);
      alpha = d_sign(&d__1, &aw[k + k * nmax]);
      u[k] = aw[k + k * nmax] + alpha;
      aw[k + k * nmax] = -alpha;

      int firstca = kp1;

      if (alpha == (float)0.)
         throw FittingError("alpha == 0",-8);

      beta = -aw[k + k * nmax] * u[k];

      // Compute householder reflection of phi
      for (m = firstca; m < l; ++m)
      {
         acum = u[k] * aw[k + m * nmax];

         for (i = kp1; i < n; ++i)
            acum += aw[i + k * nmax] * aw[i + m * nmax];
         acum /= beta;

         aw[k + m * nmax] -= u[k] * acum;
         for (i = kp1; i < n; ++i)
            aw[i + m * nmax] -= aw[i + k * nmax] * acum;
      }

      // Transform J=D(phi)
      if (transform_b)
      {
         for (m = 0; m < p; ++m)
         {
            acum = u[k] * bw[k + m * ndim];
            for (i = kp1; i < n; ++i)
               acum += aw[i + k * nmax] * bw[i + m * ndim];
            acum /= beta;

            bw[k + m * ndim] -= u[k] * acum;
            for (i = kp1; i < n; ++i)
               bw[i + m * ndim] -= aw[i + k * nmax] * acum;
         }
      }

   } // first k loop

}




void VariableProjector::get_linear_params(int idx, std::vector<double>& a, std::vector<double>& u, std::vector<double>& x)
{
   // Get linear parameters
   // Overwrite rj unless x is specified (length n)

   double* rj = r.data() + idx * nmax;

   chi2[idx] = (float) enorm(n-l, rj+l); 
   chi2[idx] *= chi2[idx] / chi2_norm;

   bacsub(rj, a.data(), x.data());
   
   for (int kback = 0; kback < l; ++kback) 
   {
      int k = l - kback - 1;
      double acum = 0;

      for (int i = k; i < n; ++i) 
         acum += a[i + k * nmax] * x[i];   

      lin_params[k + idx * lmax] = (float) x[k];

      x[k] = acum / a[k + k * nmax];
      acum = -acum / (u[k] * a[k + k * nmax]);

      for (int i = k+1; i < n; ++i) 
         x[i] -= a[i + k * nmax] * acum;
   }
}

void VariableProjector::bacsub(int idx, double *a, volatile double *x)
{
   double* rj = r.data() + idx * n;
   bacsub(rj, a, x);
}

void VariableProjector::bacsub(volatile double *rj, double *a, volatile double *x)
{
   // BACKSOLVE THE N X N UPPER TRIANGULAR SYSTEM A*RJ = B. 
   // THE SOLUTION IS STORED IN X (X MAY OVERWRITE RJ IF SPECIFIED)

   x[l-1] = rj[l-1] / a[l-1 + (l-1) * nmax];
   if (l > 1) 
   {

      for (int iback = 1; iback < l; ++iback) 
      {
         // i = N-1, N-2, ..., 2, 1
         int i = l - iback - 1;
         double acum = rj[i];
         for (int j = i+1; j < l; ++j) 
            acum -= a[i + j * nmax] * x[j];
         
         x[i] = acum / a[i + i * nmax];
      }
   }
}