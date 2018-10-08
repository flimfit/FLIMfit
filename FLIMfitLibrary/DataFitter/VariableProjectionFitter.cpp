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
#include <atomic>

#include <dlib/global_optimization.h>

using std::min;
using std::max;

#include <future>
#include <iostream>
#include "omp_stub.h"

#include "ConcurrencyAnalysis.h"

#include "LinearMLModel.h"


typedef dlib::matrix<double, 0, 1> column_vector;

VariableProjectionFitter::VariableProjectionFitter(std::shared_ptr<DecayModel> model, int max_region_size, WeightingMode weighting, GlobalAlgorithm global_algorithm, int n_thread, FittingOptions options, std::shared_ptr<ProgressReporter> reporter) :
    AbstractFitter(model, 0, max_region_size, global_algorithm, n_thread, options, reporter), weighting(weighting)
{
   for(int i=0; i<n_thread; i++)
      nnls.push_back(std::make_unique<NonNegativeLeastSquares>(l, n));

   resampler = std::make_unique<DecayResampler>(n, nl+1);

   iterative_weighting = (weighting == PixelWeighting) | variable_phi;

   n_jac_group = (int) ceil(1024.0 / (nmax-l));

   w.resize(nmax);

   vp.push_back(VariableProjector(this));
   
   spvd wp = iterative_weighting ? nullptr : vp[0].wp;
   spvd a = variable_phi ? nullptr : vp[0].a;
   spvd b = variable_phi ? nullptr : vp[0].b;

   for (int i = 1; i < n_thread; i++)
      vp.push_back(VariableProjector(this, a, b, wp));

   // Set up buffers for levmar algorithm
   //---------------------------------------------------
   int buf_dim = max(16,nl);
   
   diag = new double[buf_dim];
   qtf  = new double[buf_dim * n_thread];
   wa1  = new double[buf_dim * n_thread];
   wa2  = new double[buf_dim * n_thread];
   wa3  = new double[buf_dim * nmax * n_jac_group * n_thread];
   ipvt = new int[buf_dim];

   if (options.use_numerical_derivatives)
   {
      fjac = new double[nmax * max_region_size * n];
      wa4  = new double[nmax * max_region_size]; 
      fvec = new double[nmax * max_region_size];
   }
   else
   {
      fjac = new double[buf_dim * buf_dim * n_thread];
      wa4 = new double[buf_dim];
      fvec = new double[nmax * n_jac_group *  n_thread];
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

   if (iflag <= 1)
      vp->setVariables(x);

   if (iflag == 0)
      return vp->getResidualNonNegative(x, fnorm, iflag, thread);
   else if (iflag == 1)
      return vp->prepareJacobianCalculation(x, fnorm, fjrow, thread);
   else
      return vp->getJacobianEntry(x, fnorm, fjrow, iflag - 2, thread);
}

int VariableProjectionFitterDiffCallback(void *p, int m, int n, const double* x, double *fvec, int iflag)
{
   VariableProjectionFitter *vp = (VariableProjectionFitter*) p;
   vp->setVariables(x);
   return vp->getResidualNonNegative(x, fvec, iflag, 0);
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

void VariableProjectionFitter::fitFcn(int nl, std::vector<double>& initial, int& niter, int& ierr)
{
   fit_successful = false;

   double tol = std::numeric_limits<double>::epsilon();
   double ftol = tol;
   double xtol = tol;
   double epsfcn = tol;
   double gtol = 0.;

   int nfev, info;
   double rnorm; 

   resampler = std::make_unique<DecayResampler>(n, 3);

   //resampler->determineSampling(avg_y.data()); 
   nr = resampler->resampledSize();
   
   for(auto& v : vp)
      v.setNumResampled(nr);

   resampler->resample(avg_y.begin());

   /*
   
   int i;
   for (i = 0; i < nr; i++)
   {
      assert(avg_y[i] > 0);
   }
   for (; i < n; i++)
   {
      assert(avg_y[i] == 0);
   }

   for (int i = 0; i < n; i++)
      avg_y[i] = 1;
   
   resampler->resample(avg_y.begin());
   double s = 0;
   for (int i = 0; i < nr; i++)
      s += avg_y[i]; 
   int xx = n - s;
   assert(s == n);
   


   resampler->resample(avg_y.begin());
   */

   setupWeighting();

   auto& params = model->getAllParameters();
   std::vector<std::shared_ptr<FittingParameter>> global_parameters;
   std::vector<double> scale;
   int n_search = 0;
   for (auto& p : params)
      if (p->isFittedGlobally())
      {
         global_parameters.push_back(p);
         if (p->initial_search)
            n_search++;
         scale.push_back(p->transformed_scale);
      }


   int n_grid = std::count_if(global_parameters.begin(), global_parameters.end(), [](std::shared_ptr<FittingParameter>& p) { return p->initial_search; });
   bool initial_grid_search = !options.use_numerical_derivatives && (n_grid > 0);

   bool initial_global_optimisation = false;
   if (initial_global_optimisation)
   {
      auto get_all = [&](column_vector x) -> std::vector<double>
      {
         std::vector<double> x0(nl);
         auto it = x0.begin();
         auto xit = x.begin();
         for (auto& p : global_parameters)
            *(it++) = (p->initial_search) ? *(xit++) : p->getTransformedInitialValue();
         return x0;
      };

      auto fcn = [&](column_vector x) -> double
      {
         double rnorm;
         auto x0 = get_all(x);
         setVariables(x0.begin());
         getResidualNonNegative(x0.begin(), &rnorm, 0, 0);
         return rnorm;
      };

      column_vector lb(n_grid), ub(n_grid);
      int idx = 0;
      for (auto& p : global_parameters)
      {
         if (p->initial_search)
         {
            lb(idx) = p->getTransformedInitialMin();
            ub(idx) = p->getTransformedInitialMax();
            idx++;
         }
      }

      auto ans = dlib::find_min_global(fcn, lb, ub, dlib::max_function_calls(100));

      auto x0 = get_all(ans.x);
      std::copy(x0.begin(), x0.end(), initial.begin());
   }

   if (initial_grid_search)
   {
      int n_initial = 10;

      int n_points_total = std::pow(n_initial, n_search);

      // Initial point
      setVariables(initial.begin());
      getResidualNonNegative(initial.data(), &rnorm, 0, 0);
      double best_value = rnorm;

      for (int i = 0; i < n_points_total; i++)
      {
         std::vector<double> trial(nl);
         std::copy_n(initial.begin(), nl, trial.begin());
         int var_idx = 0;
         for (int j = 0; j < global_parameters.size(); j++)
         {
            if (global_parameters[j]->initial_search)
            {
               int idx = ((int)(i / std::pow(n_initial, var_idx))) % n_initial;
               trial[j] = global_parameters[j]->initial_min + idx * (global_parameters[j]->initial_max - global_parameters[j]->initial_min) / (n_initial - 1);
               var_idx++;
            }
         }

         setVariables(trial.begin());
         getResidualNonNegative(trial.data(), &rnorm, 0, 0);
         if (rnorm <= best_value)
         {
            std::copy(trial.begin(), trial.end(), initial.begin());;
            best_value = rnorm;
         }
      }

   }

   if (iterative_weighting)
   {
      setVariables(initial.begin());
      getResidualNonNegative(initial.data(), fvec, 0, 0);
   }

   try
   {
      if (options.use_numerical_derivatives)
         info = lmdif(VariableProjectionFitterDiffCallback, (void*) this, nr-l, nl, initial.data(), fvec,
            ftol, xtol, gtol, options.max_iterations, epsfcn, scale.data(), 2, options.initial_step_size, -1,
            &nfev, fjac, nmax*max_region_size, ipvt, qtf, wa1, wa2, wa3, wa4);
      else
      {

            info = lmstx(VariableProjectionFitterCallback, (void*) this, nr-l, nl, s, n_jac_group, initial.data(), fvec, fjac, nl,
            ftol, xtol, gtol, options.max_iterations, scale.data(), 2, options.initial_step_size, -1, n_thread,
            &nfev, &niter, &rnorm, ipvt, qtf, wa1, wa2, wa3, wa4);
      }

      // Get linear parameters
      if (info <= -8)
      {
         SetNaN(initial.data(), nl);
      }
      else
      {
         if (!getting_errs)
         {
            setVariables(initial.begin());
            getResidualNonNegative(initial.data(), fvec, -1, 0);

            bool refine_linear = true;
            if (refine_linear)
            {
               auto& B = vp[0];
               getModel(B.model, irf_idx[0], *(B.a));


               LinearMLModel model(n, l, (*(B.a)).begin(), nmax);
               column_vector x(l);

               for (int i = 0; i < s; i++)
               {
                  model.setData(y + i * n);

                  for (int j = 0; j < l; j++)
                     x(j) = log(lin_params[j + i * lmax]);

                  double r =
                     dlib::find_min_trust_region(
                        dlib::objective_delta_stop_strategy(1e-7),
                        model, x, 10);

                  chi2[i] = 2 * r / chi2_norm;

                  for (int j = 0; j < l; j++)
                     lin_params[j + i * lmax] = exp(x(j));
               }

            }

         }
      }

      fit_successful = true;
   }
   catch (FittingError e)
   {
      info = e.code();
   }

   ierr = (info < 0) ? info : niter;
}

void VariableProjectionFitter::setupWeighting()
{
   // Calculate weighting
   // If required use, gamma weighting from
   // "Parameter Estimation in Astronomy with Poisson-distributed Data"
   // Reference: http://iopscience.iop.org/0004-637X/518/1/380/

   using_gamma_weighting = false;
 
   /*
   MultiExponentialDecayGroup g(1);
   std::vector<double> alf(1, 1000);
   g.setTransformedDataParameters(model->getTransformedDataParameters());
   g.init();

   g.setVariables(alf.begin());
   g.calculateModel(w.data(), w.size(), alf[0]);
   
   for (int i = 0; i < nr; i++)
      w[i] = 1.0 / sqrt(w[i] + 1);
   */

   
   if (n == nr)
   {
      if (weighting == AverageWeighting)
      {
         for (int i = 0; i<nr; i++)
            if (avg_y[i] == 0.0f)
            {
               using_gamma_weighting = true;
               break;
            }
      }
      else // PIXEL_WEIGHTING
      {

         for (int i = 0; i<s*nr; i++) // TODO: resampled
            if (y[i] == 0.0f)
            {
               using_gamma_weighting = true;
               break;
            }
      }
   }
   
   using_gamma_weighting = false;

   if (using_gamma_weighting)
   {
      for (int i=0; i<nr; i++)
         w[i] = 1.0 / sqrt(avg_y[i] + 1);
   }
   else
   {
      for (int i=0; i<nr; i++)
         w[i] = 1.0 / sqrt(avg_y[i]);
   }
   
}

void VariableProjectionFitter::getLinearParams()
{
   if (fit_successful)
      getResidualNonNegative(alf.begin(), fvec, -1, 0);
}


int VariableProjectionFitter::prepareJacobianCalculation(const double* alf, double *rnorm, double *fjrow, int thread)
{
   auto& B = vp[0];
   
   if (!variable_phi)
   {
      getDerivatives(B.model, irf_idx[0], *(B.b), *(B.a));
      resample(*(B.b), ndim, p);
   }
   if (!iterative_weighting)
      calculateWeights(0, alf, B.wp->data());

   if (!variable_phi && !iterative_weighting)
      for(auto& B : vp)
         B.transformAB(inc);

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

   auto& B = vp[thread];

   if (variable_phi)
   {
      getModel(B.model, irf_idx[row], *(B.a));
      resample(*(B.a), nmax, l + 1);
      B.weightModel();

      getDerivatives(B.model, irf_idx[row], *(B.b), *(B.a));
      resample(*(B.b), ndim, p);
   }

   if (iterative_weighting)
      calculateWeights(row, alf, B.wp->data());

   if (variable_phi | iterative_weighting)
      B.transformAB(inc);

   resampler->resample(y + row * n, B.yr.begin());

   //if (using_gamma_weighting)
   //   for (int i = 0; i < nr; ++i)
   //      B.yr[i] += min(B.yr[i], 1.0f);

   B.setData(B.yr.begin());
   B.backSolve();
   B.computeJacobian(inc, rnorm, fjrow);

   return 0;
}

template<typename it>
int VariableProjectionFitter::getResidualNonNegative(it alf, double *rnorm, int iflag, int thread)
{
   int get_lin = (iflag == -1);

   if (reporter->shouldTerminate())
      return -9;

   auto& B = vp[0];

   if (!variable_phi)
   {
      getModel(B.model, irf_idx[0], *(B.a));
      resample(*(B.a), nmax, l+1);
   }
   if (!iterative_weighting)
      calculateWeights(0, alf, B.wp->data());

   double r_sq = 0;

   std::vector<std::atomic<int>> n_active(l);

   #pragma omp parallel for reduction(+:r_sq) num_threads(n_thread)
   for (int j = 0; j < s; j++)
   {
      int omp_thread = omp_get_thread_num();
      auto& B = vp[omp_thread];
   
      if (variable_phi)
      {
         getModel(B.model, irf_idx[j], *(B.a));
         resample(*(B.a), nmax, l+1);
      }

      if (iterative_weighting)
         calculateWeights(j, alf, B.wp->data());

      B.weightModel();

      resampler->resample(y + j * n, B.yr.begin());
      B.setData(B.yr.begin());

      double rj_norm;
      nnls[omp_thread]->compute(B.aw.data(), nr, nmax, B.r.data(), B.work.data(), rj_norm);

      for (int i = 0; i<l; i++) // TODO: this needs to be outside loop!!!!
         n_active[i] += (B.work[i] > 0.);

      r_sq += (rj_norm * rj_norm);

      if (options.use_numerical_derivatives)
         memcpy(rnorm + j*(nr - l), B.r.data() + l, (nr - l) * sizeof(double));

      if (get_lin | iterative_weighting)
      {
         for (int i = 0; i < l; i++)
            lin_params[i + j*lmax] = B.work[i];

         chi2[j] = (float) rj_norm * rj_norm / chi2_norm;
      }

   } // loop over pixels

   // Determine which columns have active pixels
   std::vector<bool> active(l + 1, true);
   for (int i = 0; i < l; i++)
      active[i] = n_active[i] > (1e-4 * s);
   B.setActiveColumns(active);
     
   // Compute the norm of the residual matrix
   *cur_chi2 = r_sq / (chi2_norm * s);

   if (!options.use_numerical_derivatives)
   {
      r_sq += kap[0] * kap[0];
      *rnorm = sqrt(r_sq);
   }

   return iflag;
}

template<typename it>
void VariableProjectionFitter::calculateWeights(int px, it alf, double* wp)
{
   auto yp = this->y + px * n;
   
   for (int i = 0; i<nr; i++)
      wp[i] = 1.0;

   return;

   if (weighting == AverageWeighting)
   {
      for (int i=0; i<nr; i++)
         wp[i] = w[i];
      return;
   }
   else if (weighting == PixelWeighting)
   {
      resampler->resample(yp, wp);
      if (using_gamma_weighting)
         for (int i = 0; i < nr; i++)
            wp[i]++;     
   }

   //if (n_call != 0) // TODO : add this back
   //   models[omp_thread].GetWeights(y, a, alf, lin_params+px*lmax, wp, irf_idx[px]);

   for(int i=0; i<nr; i++)
   {
      if (wp[i] <= 0.0)
         wp[i] = 1.0;
      else
         wp[i] = 1.0 / sqrt(wp[i]);
   }
}


void VariableProjectionFitter::resample(aligned_vector<double>& a, int ndim, int ncol)
{
   double* a_ = a.data();
   for(int i = 0; i < ncol; i++)
      resampler->resample(a_ + i * ndim);
}
