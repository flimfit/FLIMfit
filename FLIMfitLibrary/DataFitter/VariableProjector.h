#pragma once

#include <memory>
#include <vector>
#include "DecayModel.h"

typedef std::shared_ptr<aligned_vector<double>> spvd;

class VariableProjectionFitter;

class VariableProjector
{
public:
   VariableProjector(VariableProjectionFitter* f, spvd a_ = nullptr, spvd b_ = nullptr, spvd wp_ = nullptr);
   VariableProjector(VariableProjector&) = delete;
   VariableProjector(VariableProjector&&) = default;

   void setActiveColumns(const std::vector<bool>& active);

protected:   
   void setData(float* y);
   void setNumResampled(int nr_) { nr = nr_; }
   void transformAB(const std::vector<int>& inc);
   void backSolve();
   void weightModel();
   void weightActiveModel();
   void computeJacobian(const std::vector<int>& inc, double *residual, double *jacobian);

   double d_sign(double *a, double *b);

   int n, nmax, ndim, nl, l, la,  p, pmax, philp1, nr;
   
   std::vector<double> work, aw, bw, u, r;

   spvd a, b, wp;

   std::vector<bool> active;

   std::shared_ptr<DecayModel> model;

   float* adjust;

   friend class VariableProjectionFitter;
};