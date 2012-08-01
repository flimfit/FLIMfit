#include "AbstractFitter.h"
#include "FlagDefinitions.h"

AbstractFitter::AbstractFitter(FitModel* model, int smax, int l, int nl, int nmax, int ndim, int p, double *t, int variable_phi, int* terminate) : 
    model(model), smax(smax), l(l), nl(nl), nmax(nmax), ndim(ndim), p(p), t(t), variable_phi(variable_phi), terminate(terminate)
{
   a   = new double[ nmax * ( l + smax ) ]; //free ok
   b   = new double[ ndim * ( p + 3 ) ]; //free ok
   u   = new double[ l ];
   kap = new double[ nl + 1 ];

   lp1 = l+1;

   Init();
}

int AbstractFitter::Init()
{
   int j, k, inckj, p_inc;

   // Check for valid input
   //----------------------------------

   if  (!(             l >= 0
          &&          nl >= 0
          && (nl<<1) + 3 <= ndim
          &&           n <  nmax
          &&           n <  ndim
          && !(nl == 0 && l == 0)))
   {
      return ERR_INVALID_INPUT;
   }


   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   nconp1 = l+1;
   philp1 = l == 0;
   p_inc = 0;

   if ( l > 0 && nl > 0 )
   {
      model->SetupIncMatrix(inc);

      p_inc = 0;
      for (j = 0; j < lp1; ++j) 
      {
         if (p_inc == 0) 
            nconp1 = j + 1;
         for (k = 0; k < nl; ++k) 
         {
            inckj = inc[k + j * 12];
            if (inckj != 0 && inckj != 1)
               break;
            if (inckj == 1)
               p_inc++;
         }
      }

      // Determine if column L+1 is in the model
      //---------------------------------------------
      philp1 = false;
      for (k = 0; k < nl; ++k) 
         philp1 = philp1 | (inc[k + lp1 * 12] == 1); 
   }

   if (p_inc != p)
      return ERR_INVALID_INPUT;

   ncon = nconp1 - 1;

   return 0;
}

int AbstractFitter::GetFit(int irf_idx, double* alf, double* lin_params, float* adjust, double* fit)
{
   model->ada(a, b, kap, alf, 0, 1, 0);

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

AbstractFitter::~AbstractFitter()
{
   delete[] a;
   delete[] b;
   delete[] u;
   delete[] kap;
}
