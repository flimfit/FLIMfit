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

#include "VariableProjectionFitter.h"
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


VariableProjectionFitter::VariableProjectionFitter(std::shared_ptr<DecayModel> model, int max_region_size, int weighting, int global_algorithm, int n_thread, std::shared_ptr<ProgressReporter> reporter) :
    AbstractFitter(model, 0, max_region_size, global_algorithm, n_thread, reporter), weighting(weighting)
{

   nnls = std::make_unique<NonNegativeLeastSquares>(l, n);

   use_numerical_derv = false;

   iterative_weighting = (weighting > AVERAGE_WEIGHTING) | variable_phi;

   n_jac_group = (int) ceil(1024.0 / (nmax-l));

   w.resize(nmax);

   for (int i = 0; i < n_thread; i++)
      vp.push_back(VariableProjector(n, nmax, ndim, nl, l, p, pmax, philp1, model));

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


VariableProjectionFitter::~VariableProjectionFitter()
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
}


int VariableProjectionFitterCallback(void *p, int m, int n, int s, const double* x, double *fnorm, double *fjrow, int iflag, int thread)
{
   VariableProjectionFitter *vp = (VariableProjectionFitter*) p;
   vp->SetAlf(x);

   if (iflag == 0)
      return vp->getResidualNonNegative(x, fnorm, fjrow, iflag, thread);
   else if (iflag == 1)
      return vp->prepareJacobianCalculation(x, fnorm, fjrow, thread);
   else
      return vp->getJacobianEntry(x, fnorm, fjrow, iflag - 2, thread);
}

int VariableProjectionFitterDiffCallback(void *p, int m, int n, const double* x, double *fvec, int iflag)
{
   VariableProjectionFitter *vp = (VariableProjectionFitter*) p;
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

void VariableProjectionFitter::FitFcn(int nl, std::vector<double>& alf, int itmax, int* niter, int* ierr)
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
         info = lmdif(VariableProjectionFitterDiffCallback, (void*) this, nml, nl, alf.data(), fvec,
            ftol, xtol, gtol, itmax, epsfcn, diag, 1, factor, -1,
            &nfev, fjac, nmax*max_region_size, ipvt, qtf, wa1, wa2, wa3, wa4);
      else
      {

         info = lmstx(VariableProjectionFitterCallback, (void*) this, nml, nl, s, n_jac_group, alf.data(), fvec, fjac, nl,
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

void VariableProjectionFitter::GetLinearParams() 
{
   if (fit_successful)
   {
      int nsls1 = (n - l) * s;
      getResidualNonNegative(alf.data(), fvec, fjac, -1, 0);
   }   
}


int VariableProjectionFitter::prepareJacobianCalculation(const double* alf, double *rnorm, double *fjrow, int thread)
{
   auto& B = vp[thread];
   
   if (!variable_phi)
   {
      GetModel(alf, B.model, irf_idx[0], B.b);
      GetDerivatives(alf, B.model, irf_idx[0], B.b);
   }
   if (!iterative_weighting)
      calculateWeights(0, alf, B.wp);

   if (!variable_phi && !iterative_weighting)
      B.transformAB();

   // Set kappa derivatives
   *rnorm = kap[0];
   for (int k = 0; k < nl; k++)
      fjrow[k] = kap[k + 1];

   return 0;
}


int VariableProjectionFitter::getJacobianEntry(const double* alf, double *rnorm, double *fjrow, int row, int thread)
{
   if (reporter->shouldTerminate())
      return -9;

   int idx = (iterative_weighting) ? thread : 0;
   auto& B = vp[idx];

   if (variable_phi)
   {
      GetModel(alf, B.model, irf_idx[row], B.a);
      GetDerivatives(alf, B.model, irf_idx[row], B.b);
   }

   if (iterative_weighting)
      calculateWeights(row, alf, B.wp);

   if (variable_phi | iterative_weighting)
      B.transformAB();

   B.setData(y + row * n);
   B.backSolve();
   B.computeJacobian(inc, rnorm, fjrow);
   
   return 0;
}


int VariableProjectionFitter::getResidualNonNegative(const double* alf, double *rnorm, double *fjrow, int iflag, int thread)
{
   int nml = n - l;
   int get_lin = false;

   if (iflag == -1)
      get_lin = true;

   if (reporter->shouldTerminate())
      return -9;

   double r_sq = 0;

   auto& B = vp[thread];

   if (!variable_phi)
      GetModel(alf, B.model, irf_idx[0], B.a);
   if (!iterative_weighting)
      calculateWeights(0, alf, B.wp);

   //#pragma omp parallel for num_threads(n_thread)

   // We'll apply this for all pixels
   //#pragma omp parallel reduction(+:r_sq) num_threads(n_thread)
   for (int j = 0; j < s; j++)
   {
      int omp_thread = 0; //omp_get_thread_num();
      auto& B = vp[omp_thread];
   
      int idx = (iterative_weighting) ? omp_thread : 0;

      if (variable_phi)
         GetModel(alf, B.model, irf_idx[j], B.a);
      if (iterative_weighting)
         calculateWeights(j, alf, B.wp);
     
      B.weightModel();      
      B.setData(y + j * n);

      double rj_norm;
      nnls->compute(B.aw, nmax, B.r, B.work, rj_norm);

      // Calcuate the norm of the jth column and add to residual
      r_sq += rj_norm * rj_norm;

      if (use_numerical_derv)
         memcpy(rnorm + j*(n - l), B.r.data() + l, (n - l) * sizeof(double));

      if (get_lin | iterative_weighting)
      {
         for (int i = 0; i < l; i++)
            lin_params[i + j*lmax] = B.work[i];

         chi2[j] = (float) rj_norm / chi2_norm;
      }

   } // loop over pixels

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

void VariableProjectionFitter::calculateWeights(int px, const double* alf, std::vector<double>& wp)
{
   float* y = this->y + px * n;
   
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
