#include "AbstractFitter.h"
#include "FlagDefinitions.h"
#include "util.h"

#include "boost/math/distributions/fisher_f.hpp"
#include "boost/math/tools/minima.hpp"
#include "boost/bind.hpp"
#include <limits>
#include <exception>

using namespace std;

AbstractFitter::AbstractFitter(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p_full, double *t, int variable_phi, int n_thread, int* terminate) : 
    model(model), smax(smax), l(l), nl(nl), nmax(nmax), ndim(ndim), p_full(p_full), t(t), variable_phi(variable_phi), n_thread(n_thread), terminate(terminate)
{
   err = 0;

   a   = NULL;
   r   = NULL;
   b   = NULL;
   u   = NULL;
   kap = NULL;

   params = NULL;
   alf_err = NULL;
   
   // Check for valid input
   //----------------------------------
   if  (!(             l >= 0
          &&          nl >= 0
          && (nl<<1) + 3 <= ndim
          && !(nl == 0 && l == 0)))
   {
      err = ERR_INVALID_INPUT;
      return;
   }

   a   = new double[ nmax * (l+1) * n_thread ]; //free ok
   r   = new double[ nmax * smax ];
   b   = new double[ ndim * ( p_full + 3 ) * n_thread ]; //free ok
   u   = new double[ l * n_thread ];
   kap = new double[ nl + 1 ];

   params = new double[ nl ];
   alf_err = new double[ nl ];

   fixed_param = -1;

   getting_errs = false;

   lp1 = l+1;

   Init();

   if (p_full != p)
      err = ERR_INVALID_INPUT;

}

int AbstractFitter::Init()
{
   int j, k, inckj;

   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   nconp1 = l+1;
   philp1 = l == 0;
   p = 0;

   if ( l > 0 && nl > 0 )
   {
      model->SetupIncMatrix(inc);

      if (fixed_param >= 0)
      {
         int idx = 0;
         for (k = 0; k < nl; k++)
         {
            if (k != fixed_param)
            {
               for (j = 0; j < lp1; ++j) 
                  inc[idx + j * 12] = inc[k + j * 12];
               idx++;
            }
         }
         for (j = 0; j < lp1; ++j) 
            inc[idx + j * 12] = 0;
      }

      p = 0;
      for (j = 0; j < lp1; ++j) 
      {
         if (p == 0) 
            nconp1 = j + 1;
         for (k = 0; k < nl; ++k) 
         {
            inckj = inc[k + j * 12];
            if (inckj != 0 && inckj != 1)
               break;
            if (inckj == 1)
               p++;
         }
      }

      // Determine if column L+1 is in the model
      //---------------------------------------------
      philp1 = false;
      for (k = 0; k < nl; ++k) 
         philp1 = philp1 | (inc[k + l * 12] == 1); 
   }

   ncon = nconp1 - 1;
   

   //ncon = 0;
   //nconp1 = 1;


   return 0;
}

int AbstractFitter::Fit(int s, int n, int lmax, float* y, float *w, int* irf_idx, double *alf, float *lin_params, float *chi2, int thread, int itmax, double smoothing, int& niter, int &ierr, double& c2)
{

   if (err != 0)
      return err;

   fixed_param = -1;
   getting_errs = false;

   Init();

   this->n          = n;
   this->s          = s;
   this->lmax       = lmax;
   this->y          = y;
   this->w          = w;
   this->lin_params = lin_params;
   this->irf_idx    = irf_idx;
   this->chi2       = chi2;
   this->cur_chi2   = &c2;
   this->smoothing  = smoothing;
   this->thread     = thread;

   chi2_factor = 1 / (n - ((double)nl)/s - l);

   
   int ret = FitFcn(nl, alf, itmax, &niter, &ierr, &c2);

   chi2_final = c2;

   return ret;
}


int AbstractFitter::CalculateErrors(double* alf, double* conf_lim)
{
   using namespace boost::math;
   using namespace boost::math::tools;

   pair<double , double> ans;

   if (err != 0)
      return err;

   getting_errs = true;

   for(int i=0; i<nl; i++)
   {
      fixed_param = i;
      fixed_value_initial = alf[i];
   
      Init();

      int idx = 0;
      for(int j=0; j<nl; j++)
         if (j!=fixed_param)
            alf_err[idx++] = alf[j];

      double f[3] = {0.1, 0.5, 1.0};


      for(int k=0; k<3; k++)
      {
         ans = brent_find_minima(boost::bind(&AbstractFitter::ErrMinFcn,this,_1), 
                                 0.0, f[k]*fixed_value_initial, 9);
               
         if (ans.second < 1)
            break;   
      }

      if (ans.second > 1)
         ans.first = 0;
            
      conf_lim[i] = fixed_value_initial + ans.first;
   }

   return 0;
}


double AbstractFitter::ErrMinFcn(double x)
{
   using namespace boost::math;
   
   double alpha,c2,F,F_crit;
   int itmax = 10;

   int niter, ierr;

   alpha = 0.05;
   fisher_f dist(1, n * s - nl - s * l);
   F_crit = quantile(complement(dist, alpha));
   
   fixed_value_cur = fixed_value_initial + x; 

   FitFcn(nl-1,alf_err,itmax,&niter,&ierr,&c2);
            
   //c2 = CalculateChi2(params.thread, params.region, params.s_thresh, y, w, a, lin_params_err, adjust_buf, fit_buf, mask, NULL);

   F = (*cur_chi2-chi2_final)/chi2_final / chi2_factor * s ;
   

   return (F-F_crit)*(F-F_crit)/F_crit;

}


void AbstractFitter::GetParams(int nl, const double* alf)
{
   int idx = 0;
   for(int i=0; i<nl; i++)
   {
      if (i==fixed_param)
         params[i] = fixed_value_cur; 
      else
         params[i] = alf[idx++];
   }
}

void AbstractFitter::GetModel(const double* alf, int irf_idx, int isel, int omp_thread)
{
   int valid_cols  = 0;
   int ignore_cols = 0;

   int idx = 0;
   for(int i=0; i<nl; i++)
   {
      if (i==fixed_param)
         params[i] = fixed_value_cur; 
      else
         params[i] = alf[idx++];
   }

   double* a = this->a + omp_thread * nmax * (l+1);
   double* b = this->b + omp_thread * ndim * ( p_full + 3 );

   model->CalculateModel(a, b, kap, params, irf_idx, isel, thread * n_thread + omp_thread);

   // If required remove derivatives associated with fixed columns
   if (fixed_param >= 0)
   {
   
      for (int k = 0; k < fixed_param; ++k)
         for (int j = 0; j < l; ++j) 
            valid_cols += inc[k + j * 12];

      for (int j = 0; j < l; ++j)
         ignore_cols += inc[fixed_param + j * 12];

      double* src = b + ndim * (valid_cols + ignore_cols);
      double* dest = b + ndim * valid_cols;
      int size = ndim * (p_full - (valid_cols + ignore_cols)) * sizeof(double);

      memmove(dest, src, size);
      
   }

}


int AbstractFitter::GetFit(int irf_idx, double* alf, float* lin_params, float* adjust, double counts_per_photon, double* fit)
{
   if (err != 0)
      return err;

   model->CalculateModel(a, b, kap, alf, irf_idx, 1, 0);

   int idx = 0;
   for(int i=0; i<n; i++)
   {
      fit[idx] = adjust[i];
      for(int j=0; j<l; j++)
         fit[idx] += a[n*j+i] * lin_params[j];

      fit[idx] += a[n*l+i];
      fit[idx++] *= counts_per_photon;
   }

   return 0;
}

void AbstractFitter::ReleaseResidualMemory()
{
   ClearVariable(r);
}

AbstractFitter::~AbstractFitter()
{
   ClearVariable(r);
   ClearVariable(a);
   ClearVariable(b);
   ClearVariable(u);
   ClearVariable(kap);

   ClearVariable(params);
   ClearVariable(alf_err);
}
