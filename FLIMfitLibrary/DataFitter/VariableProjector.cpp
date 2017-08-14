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

   w.resize(nmax);

   norm_buf_ = new double[ nmax * n_thread ];

   for (int i = 0; i < n_thread; i++)
      vp_buffer.push_back(VpBuffer(nmax, ndim, l, pmax, model));

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
   delete[] norm_buf_;
}


int VariableProjectorCallback(void *p, int m, int n, int s, const double* x, double *fnorm, double *fjrow, int iflag, int thread)
{
   VariableProjector *vp = (VariableProjector*) p;
   vp->SetAlf(x);

   if (iflag == 0)
      return vp->getResidualNonNegative(x, fnorm, fjrow, iflag, thread);
   else if (iflag == 1)
      return vp->prepareJacobianCalculation(x, fnorm, fjrow, thread);
   else
      return vp->getJacobianEntry(x, fnorm, fjrow, iflag - 2, thread);
}

int VariableProjectorDiffCallback(void *p, int m, int n, const double* x, double *fvec, int iflag)
{
   VariableProjector *vp = (VariableProjector*) p;
   vp->SetAlf(x);
   return vp->getResidualNonNegative(x, fvec, NULL, iflag, 0);
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
   int nml = (n-l);
 
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

   n_call = 0;

   if (iterative_weighting)
   {
      getResidualNonNegative(alf.data(), fvec, fjac, 0, 0);
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
         info = lmdif(VariableProjectorDiffCallback, (void*) this, nml, nl, alf.data(), fvec,
            ftol, xtol, gtol, itmax, epsfcn, diag, 1, factor, -1,
            &nfev, fjac, nmax*max_region_size, ipvt, qtf, wa1, wa2, wa3, wa4);
      else
      {

         info = lmstx(VariableProjectorCallback, (void*) this, nml, nl, s, n_jac_group, alf.data(), fvec, fjac, nl,
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
            getResidualNonNegative(alf.data(), fvec, fjac, -1, 0);
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
      getResidualNonNegative(alf.data(), fvec, fjac, -1, 0);
   }   
}

double VariableProjector::d_sign(double *a, double *b)
{
   double x;
   x = (*a >= 0 ? *a : - *a);
   return( *b >= 0 ? x : -x);
}


int VariableProjector::prepareJacobianCalculation(const double* alf, double *rnorm, double *fjrow, int thread)
{
   auto& B = vp_buffer[thread];
   
   if (!variable_phi)
   {
      GetModel(alf, B.model, irf_idx[0], B.b);
      GetDerivatives(alf, B.model, irf_idx[0], B.b);
   }
   if (!iterative_weighting)
      calculateWeights(0, alf, B);

   if (!variable_phi && !iterative_weighting)
      transformAB(0, B);

   // Set kappa derivatives
   *rnorm = kap[0];
   for (int k = 0; k < nl; k++)
      fjrow[k] = kap[k + 1];

   return 0;
}

int VariableProjector::getJacobianEntry(const double* alf, double *rnorm, double *fjrow, int row, int thread)
{
   int nml = n - l;

   if (reporter->shouldTerminate())
      return -9;

   int idx = (iterative_weighting) ? thread : 0;
   auto& B = vp_buffer[idx];

   float* y__ = y + row * n;

   if (variable_phi)
   {
      GetModel(alf, B.model, irf_idx[row], B.a);
      GetDerivatives(alf, B.model, irf_idx[row], B.b);
   }

   if (iterative_weighting)
      calculateWeights(row, alf, B);

   if (variable_phi | iterative_weighting)
      transformAB(row, B);

   auto adjust = model->getConstantAdjustment();

   // Get the data we're about to transform
   if (!philp1)
   {
      for (int i = 0; i < n; i++)
         B.r[i] = (y__[i] - adjust[i]) * B.wp[i];
   }
   else
   {
      // Store the data in rj, subtracting the column l+1 which does not
      // have a linear parameter
      for (int i = 0; i < n; i++)
         B.r[i] = (y__[i] - adjust[i]) * B.wp[i] - B.aw[i + l * nmax];
   }

   // Transform Y, getting Q*Y=R 
   for (int k = 0; k < l; k++)
   {
      int kp1 = k + 1;
      double beta = -B.aw[k + k * nmax] * B.u[k];
      double acum = B.u[k] * B.r[k];

      for (int i = kp1; i < n; ++i)
         acum += B.aw[i + k * nmax] * B.r[i];
      acum /= beta;

      B.r[k] -= B.u[k] * acum;
      for (int i = kp1; i < n; i++)
         B.r[i] -= B.aw[i + k * nmax] * acum;
   }

   backSolve(B.r, B.aw);

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
               acum += B.bw[ipl + m * ndim] * B.r[j];
               ++m;
            }
         }

         if (inc[k + l * 12] != 0)
         {
            acum += B.bw[ipl + m * ndim];
            ++m;
         }

         fjrow[i*nl + k] = -acum;

      }
      rnorm[i] = B.r[ipl];
   }
   return 0;
}


int VariableProjector::getResidualNonNegative(const double* alf, double *rnorm, double *fjrow, int iflag, int thread)
{
   int nml = n - l;
   int get_lin = false;

   if (iflag == -1)
      get_lin = true;

   if (reporter->shouldTerminate())
      return -9;

   double r_sq = 0;

   auto& B = vp_buffer[thread];

   float* adjust = model->getConstantAdjustment();
   if (!variable_phi)
      GetModel(alf, B.model, irf_idx[0], B.a);
   if (!iterative_weighting)
      calculateWeights(0, alf, B);

   for (int i = 0; i<n_thread; i++)
      norm_buf_[i*nmax] = 0;

   //#pragma omp parallel for num_threads(n_thread)

   // We'll apply this for all pixels
   for (int j = 0; j < s; j++)
   {
      int omp_thread = 0; // omp_get_thread_num();

      float* yj = y + j * n;

      int idx = (iterative_weighting) ? omp_thread : 0;

      float* linj = lin_params + idx * lmax;

      if (variable_phi)
         GetModel(alf, B.model, irf_idx[j], B.a);
      if (iterative_weighting)
         calculateWeights(j, alf, B);
     
      // Get the data we're about to transform
      if (!philp1)
      {
         for (int i = 0; i < n; i++)
            B.r[i] = (yj[i] - adjust[i]) * B.wp[i];
      }
      else
      {
         // Store the data in rj, subtracting the column l+1 which does not
         // have a linear parameter
         for (int i = 0; i < n; i++)
            B.r[i] = (yj[i] - adjust[i]) * B.wp[i] - B.a[i + l * nmax];
      }

      for (int k = 0; k < l; k++)
      {
         for (int i = 0; i < n; i++)
            B.aw[i + k*nmax] = B.a[i + k*nmax] * B.wp[i];
      }

      double rj_norm;
      nnls->compute(B.aw.data(), nmax, B.r.data(), B.work.data(), rj_norm);

      // Calcuate the norm of the jth column and add to residual
      norm_buf_[omp_thread*nmax] += rj_norm * rj_norm;

      if (use_numerical_derv)
         memcpy(rnorm + j*(n - l), B.r.data() + l, (n - l) * sizeof(double));

      if (get_lin | iterative_weighting)
      {
         for (int i = 0; i < l; i++)
            lin_params[i + j*lmax] = B.work[i];

         chi2[j] = (float) rj_norm / chi2_norm;
      }

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

void VariableProjector::calculateWeights(int px, const double* alf, VpBuffer& B)
{
   float*  y = this->y + px * n;
   
   if (weighting == AVERAGE_WEIGHTING || n_call == 0)
   {
      for (int i=0; i<n; i++)
         B.wp[i] = w[i];
      return;
   }
   else if (weighting == PIXEL_WEIGHTING)
   {
      for (int i=0; i<n; i++)
         B.wp[i] = y[i];
   }
   else // MODEL_WEIGHTING
   {
      for(int i=0; i<n; i++)
      {
         B.wp[i] = 0;
         for(int j=0; j<l; j++)
            B.wp[i] += B.a[n*j+i] * lin_params[px*lmax+j];
         if (philp1)
            B.wp[i] += B.a[n*l+i];
      }
   }

   //if (n_call != 0) // TODO : add this back
   //   models[omp_thread].GetWeights(y, a, alf, lin_params+px*lmax, wp, irf_idx[px]);

   for(int i=0; i<n; i++)
   {
      if (B.wp[i] <= 0)
         B.wp[i] = 1.0;
      else
         B.wp[i] = sqrt(1.0/B.wp[i]);

   }
}

void VariableProjector::transformAB(int px, VpBuffer& B)
{
   int lp1 = l + 1;

   double beta, acum;
   double alpha, d__1;

   int i, m, k, kp1;

   for (m = 0; m < lp1; ++m)
      for (int i = 0; i < n; ++i)
         B.aw[i + m * nmax] = B.a[i + m * nmax] * B.wp[i];

   for (m = 0; m < p; ++m)
      for (int i = 0; i < n; ++i)
         B.bw[i + m * ndim] = B.b[i + m * ndim] * B.wp[i];

   // Compute orthogonal factorisations by householder reflection (phi)
   for (k = 0; k < l; ++k)
   {
      kp1 = k + 1;

      // If *isel=1 or 2 reduce phi (first l columns of a) to upper triangular form

      d__1 = enorm(n - k, &B.aw[k + k * nmax]);
      alpha = d_sign(&d__1, &B.aw[k + k * nmax]);
      B.u[k] = B.aw[k + k * nmax] + alpha;
      B.aw[k + k * nmax] = -alpha;

      int firstca = kp1;

      if (alpha == (float)0.)
         throw FittingError("alpha == 0", -8);

      beta = -B.aw[k + k * nmax] * B.u[k];

      // Compute householder reflection of phi
      for (m = firstca; m < l; ++m)
      {
         acum = B.u[k] * B.aw[k + m * nmax];

         for (i = kp1; i < n; ++i)
            acum += B.aw[i + k * nmax] * B.aw[i + m * nmax];
         acum /= beta;

         B.aw[k + m * nmax] -= B.u[k] * acum;
         for (i = kp1; i < n; ++i)
            B.aw[i + m * nmax] -= B.aw[i + k * nmax] * acum;
      }

      // Transform J=D(phi)
      for (m = 0; m < p; ++m)
      {
         acum = B.u[k] * B.bw[k + m * ndim];
         for (i = kp1; i < n; ++i)
            acum += B.aw[i + k * nmax] * B.bw[i + m * ndim];
         acum /= beta;

         B.bw[k + m * ndim] -= B.u[k] * acum;
         for (i = kp1; i < n; ++i)
            B.bw[i + m * ndim] -= B.aw[i + k * nmax] * acum;
      }

   } // first k loop

}

void VariableProjector::backSolve(std::vector<double>& r, std::vector<double>& a)
{
   // BACKSOLVE THE N X N UPPER TRIANGULAR SYSTEM A*RJ = B. 

   r[l-1] = r[l-1] / a[l-1 + (l-1) * nmax];
   if (l > 1) 
   {

      for (int iback = 1; iback < l; ++iback) 
      {
         // i = N-1, N-2, ..., 2, 1
         int i = l - iback - 1;
         double acum = r[i];
         for (int j = i+1; j < l; ++j) 
            acum -= a[i + j * nmax] * r[j];
         
         r[i] = acum / a[i + i * nmax];
      }
   }
}