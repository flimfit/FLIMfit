#pragma once

#include <memory>
#include <vector>
#include "DecayModel.h"

typedef std::shared_ptr<aligned_vector<double>> spvd;
typedef std::vector<float>::const_iterator const_float_iterator;

class VariableProjectionFitter;

class VariableProjector
{
public:
   VariableProjector(VariableProjectionFitter* f, spvd a_ = nullptr, spvd b_ = nullptr, spvd wp_ = nullptr);
   VariableProjector(VariableProjector&) = delete;
   VariableProjector(VariableProjector&&) = default;

   void setActiveColumns(const std::vector<bool>& active);

protected:   
   void setData(const_float_iterator y);
   void setNumResampled(int nr_) { nr = nr_; }
   void transformAB(const std::vector<int>& inc);
   void backSolve();
   void weightModel();
   void weightActiveModel();
   void computeJacobian(const std::vector<int>& inc, double *residual, double *jacobian);

   double d_sign(double *a, double *b);

   int n, nmax, ndim, nl, l, la,  p, pmax, philp1, nr;
   
   std::vector<double> work, aw, bw, u, r;
   std::vector<float> yr;

   spvd a, b, wp;

   std::vector<bool> active;

   std::shared_ptr<DecayModel> model;

   float* adjust;

   friend class VariableProjectionFitter;
};