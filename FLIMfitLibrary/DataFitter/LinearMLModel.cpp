#include "LinearMLModel.h"

LinearMLModel::LinearMLModel(int n, int nl, double_iterator a, int adim) :
   n(n), nl(nl), a(a), adim(adim)
{
   beta.set_size(nl);
   mu.set_size(n);
}

void LinearMLModel::setData(float_iterator y_)
{
   y = y_;
   const_chi = 0;

   for (int i = 0; i < n; i++)
   {
      const_chi -= y[i];
      if (y[i] > 0)
         const_chi += y[i] * log(y[i]);
   }
}

double LinearMLModel::operator()(const column_vector& x) const
{
   for (int j = 0; j < nl; j++)
   {
      beta(j) = exp(x(j));
      for (int i = 0; i < n; i++)
         mu(i) += a[i + adim * j] * beta(j);
   }

   double chi = const_chi;
   for (int i = 0; i < n; i++)
      chi += mu(i) - y[i] * log(mu(i));

   return chi;
}

void LinearMLModel::get_derivative_and_hessian(const column_vector& x, column_vector& J, general_matrix& H) const
{
   J.set_size(nl);
   J = 0;

   H.set_size(nl,nl);
   H = 0;

   for (int i = 0; i < n; i++)
   {
      double inv_mu2 = 1.0 / (mu(i) * mu(i));
      double ymu = y[i] / mu(i);

      for (int j = 0; j < nl; j++)
      {
         J(j) += a[i + adim * j] * (1 - ymu);
         H(j, j) += y[i] * a[i + adim * j] * a[i + adim * j] * inv_mu2;

         for (int k = j + 1; k < nl; k++)
         {
            double h = y[i] * a[i + adim * j] * a[i + adim * k] * inv_mu2;
            H(j, k) += h;
            H(k, j) += h;
         }
      }
   }

   // multiply by d(beta)/d(x) = beta
   for (int j = 0; j < nl; j++)
   {
      J(j) *= beta(j);
      for (int k = 0; k < nl; k++)
         H(j, k) *= beta(j) * beta(k);
   }
}