#pragma once

#include <memory>
#include <vector>
#include "DecayModel.h"

class VariableProjectionFitter;

class VariableProjector
{
   VariableProjector(int n, int nmax, int ndim, int nl, int l, int p, int pmax, int philp1, std::shared_ptr<DecayModel> model_) :
      n(n), nmax(nmax), ndim(ndim), nl(nl), l(l), p(p), pmax(pmax), philp1(philp1)
   {
      r.resize(nmax);
      work.resize(nmax);
      aw.resize(nmax * (l + 1));
      bw.resize(ndim * (pmax + 3));
      wp.resize(nmax);
      u.resize(nmax);

      a.resize(nmax * (l + 1));
      b.resize(ndim * (pmax + 3));

      model = std::make_shared<DecayModel>(*model_); // deep copy
      adjust = model->getConstantAdjustment();
   }

   void setData(float* y);
   void transformAB();
   void backSolve();
   void weightModel();
   void computeJacobian(const std::vector<int>& inc, double *residual, double *jacobian);

   double d_sign(double *a, double *b);

   int n, nmax, ndim, nl, l, p, pmax, philp1;
   
   std::vector<double> a, b;
   std::vector<double> work, aw, bw, wp, u, r;

   std::shared_ptr<DecayModel> model;

   float* adjust;

   friend class VariableProjectionFitter;
};