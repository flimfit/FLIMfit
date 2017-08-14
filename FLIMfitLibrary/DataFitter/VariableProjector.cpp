#include "VariableProjector.h"
#include "AbstractFitter.h"
#include "cminpack.h"

void VariableProjector::setData(float* y)
{
   // Get the data we're about to transform
   if (!philp1)
   {
      for (int i = 0; i < n; i++)
         r[i] = (y[i] - adjust[i]) * wp[i];
   }
   else
   {
      // Store the data in rj, subtracting the column l+1 which does not
      // have a linear parameter
      for (int i = 0; i < n; i++)
         r[i] = (y[i] - adjust[i]) * wp[i] - aw[i + l * nmax];
   }
}

void VariableProjector::weightModel()
{
   int lp1 = l+1;
   for (int k = 0; k < lp1; k++)
      for (int i = 0; i < n; i++)
         aw[i + k*nmax] = a[i + k*nmax] * wp[i];

}

void VariableProjector::computeJacobian(const std::vector<int>& inc, double residual[], double jacobian[])
{
   int nml = n - l;
   for (int i = 0; i < nml; i++)
   {
      int ipl = i + l;
      int m = 0;
      for (int k = 0; k < nl; ++k)
      {
         double acum = 0.;
         for (int j = 0; j < l; ++j)
         {
            if (inc[k + j * 12] != 0)
            {
               acum += bw[ipl + m * ndim] * r[j];
               ++m;
            }
         }

         if (inc[k + l * 12] != 0)
         {
            acum += bw[ipl + m * ndim];
            ++m;
         }

         jacobian[i*nl + k] = -acum;
      }
      residual[i] = r[ipl];
   }
}



void VariableProjector::transformAB()
{

   weightModel();

   for (int m = 0; m < p; ++m)
      for (int i = 0; i < n; ++i)
         bw[i + m * ndim] = b[i + m * ndim] * wp[i];

   // Compute orthogonal factorisations by householder reflection (phi)
   for (int k = 0; k < l; ++k)
   {
      int kp1 = k + 1;

      // If *isel=1 or 2 reduce phi (first l columns of a) to upper triangular form

      double d__1 = enorm(n - k, &aw[k + k * nmax]);
      double alpha = d_sign(&d__1, &aw[k + k * nmax]);
      u[k] = aw[k + k * nmax] + alpha;
      aw[k + k * nmax] = -alpha;

      int firstca = kp1;

      if (alpha == (float)0.)
         throw FittingError("alpha == 0", -8);

      double beta = -aw[k + k * nmax] * u[k];

      // Compute householder reflection of phi
      for (int m = firstca; m < l; ++m)
      {
         double acum = u[k] * aw[k + m * nmax];

         for (int i = kp1; i < n; ++i)
            acum += aw[i + k * nmax] * aw[i + m * nmax];
         acum /= beta;

         aw[k + m * nmax] -= u[k] * acum;
         for (int i = kp1; i < n; ++i)
            aw[i + m * nmax] -= aw[i + k * nmax] * acum;
      }

      // Transform J=D(phi)
      for (int m = 0; m < p; ++m)
      {
         double acum = u[k] * bw[k + m * ndim];
         for (int i = kp1; i < n; ++i)
            acum += aw[i + k * nmax] * bw[i + m * ndim];
         acum /= beta;

         bw[k + m * ndim] -= u[k] * acum;
         for (int i = kp1; i < n; ++i)
            bw[i + m * ndim] -= aw[i + k * nmax] * acum;
      }

   } // first k loop

}

void VariableProjector::backSolve()
{
   // Transform Y, getting Q*Y=R 
   for (int k = 0; k < l; k++)
   {
      int kp1 = k + 1;
      double beta = -aw[k + k * nmax] * u[k];
      double acum = u[k] * r[k];

      for (int i = kp1; i < n; ++i)
         acum += aw[i + k * nmax] * r[i];
      acum /= beta;

      r[k] -= u[k] * acum;
      for (int i = kp1; i < n; i++)
         r[i] -= aw[i + k * nmax] * acum;
   }

   // BACKSOLVE THE N X N UPPER TRIANGULAR SYSTEM A*RJ = B. 

   r[l-1] = r[l-1] / aw[l-1 + (l-1) * nmax];
   if (l > 1) 
   {
      for (int iback = 1; iback < l; ++iback) 
      {
         // i = N-1, N-2, ..., 2, 1
         int i = l - iback - 1;
         double acum = r[i];
         for (int j = i+1; j < l; ++j) 
            acum -= aw[i + j * nmax] * r[j];
         
         r[i] = acum / aw[i + i * nmax];
      }
   }
}


double VariableProjector::d_sign(double *a, double *b)
{
   double x;
   x = (*a >= 0 ? *a : - *a);
   return( *b >= 0 ? x : -x);
}
