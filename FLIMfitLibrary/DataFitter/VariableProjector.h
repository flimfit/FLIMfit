#pragma once

#include <memory>
#include <vector>
#include "DecayModel.h"

class VariableProjectionFitter;

class VariableProjector
{
public:
   VariableProjector(VariableProjectionFitter* f, std::shared_ptr<std::vector<double>> a_ = nullptr, std::shared_ptr<std::vector<double>> wp_ = nullptr);
   VariableProjector(VariableProjector&) = delete;
   VariableProjector(VariableProjector&&) = default;
protected:   
   void setData(float* y);
   void transformAB();
   void backSolve();
   void weightModel();
   void computeJacobian(const std::vector<int>& inc, double *residual, double *jacobian);

   double d_sign(double *a, double *b);

   int n, nmax, ndim, nl, l, p, pmax, philp1;
   
   std::vector<double> b;
   std::vector<double> work, aw, bw, u, r;

   std::shared_ptr<std::vector<double>> a, wp;

   std::shared_ptr<DecayModel> model;

   float* adjust;

   friend class VariableProjectionFitter;
};