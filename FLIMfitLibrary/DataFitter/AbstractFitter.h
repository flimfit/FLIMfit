//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

#pragma once

#include "DecayModel.h"
#include "MeasuredIrfConvolver.h"
#include "FitResults.h"
#include "RegionData.h"
#include "MeanLifetimeEstimator.h"
#include "ProgressReporter.h"

#include "omp_stub.h"
#include "levmar.h"

#include <cstdio>
#include <iostream>

#include <memory>


class FittingError : public std::runtime_error
{
public:
   FittingError(const std::string& description, int code) :
      std::runtime_error(description),
      code_(code)
   {
   }

   int code() { return code_; }

protected:
   int code_;
};

struct FittingOptions
{
   int max_iterations = 100;
   double initial_step_size = 0.1;
   bool use_numerical_derivatives = false;
   bool use_ml_refinement = false;
};

class AbstractFitter
{
public:

   AbstractFitter(std::shared_ptr<DecayModel> model, int n_param_extra, int max_region_size, GlobalAlgorithm global_algorithm, int n_thread, FittingOptions fit_settings, std::shared_ptr<ProgressReporter> reporter);

   virtual ~AbstractFitter() {};

   virtual void fitFcn(int nl, std::vector<double>& alf, int& niter, int& ierr) = 0;
   virtual void getLinearParams() = 0;
   
   int fit(std::shared_ptr<RegionData> region_data, FitResultsRegion& results, int itmax, int& niter, int &ierr, double& c2);
   int getFit(PixelIndex irf_idx, const std::vector<double>& alf, float_iterator lin_params, double* fit);
   double errMinFcn(double x);
   int calculateErrors(double conf_limit);

   template<typename it>
   void setVariables(it alf_);

   void getModel(std::shared_ptr<DecayModel> model, PixelIndex irf_idx, aligned_vector<double>& a);
   void getDerivatives(std::shared_ptr<DecayModel> model, PixelIndex irf_idx, aligned_vector<double>& b, const aligned_vector<double>& a);

protected:

   int init();

   std::shared_ptr<DecayModel> model; // reference
   std::shared_ptr<ProgressReporter> reporter;

   std::vector<double> alf;
   std::vector<double> err_lower;
   std::vector<double> err_upper;

   FittingOptions options;

   // Used by variable projection
   inc_matrix inc;
   inc_matrix inc_full;
   int philp1;

   aligned_vector<double> a;
   aligned_vector<double> kap;
   std::vector<double> params;
   std::vector<double> alf_err;
   std::vector<double> alf_buf;

   int n;
   int nl;
   int ndim;
   int nmax;
   int s;
   int l;
   int lmax;
   int n_param;
   int p;

   int max_region_size;

   float_iterator y;
   std::vector<float> w;
   std::vector<float> avg_y;
   float_iterator lin_params;
   float_iterator chi2;
   std::vector<PixelIndex>::iterator irf_idx;

   float chi2_norm;
   double* cur_chi2;

   int n_thread;
   int variable_phi;

   int    fixed_param;
   double fixed_value_initial;
   double fixed_value_cur;
   double chi2_final;

   bool getting_errs;

   double counts_per_photon;

private:

   MeanLifetimeEstimator lifetime_estimator;

   GlobalAlgorithm global_algorithm;
   double conf_limit;

   int search_dir;

   FILE* f_debug;

   int a_size;
   int b_size;

   std::vector<PixelIndex> irf_idx_0 = {0};
};


template<typename it>
void AbstractFitter::setVariables(it alf_)
{
   std::copy(alf_, alf_ + nl, alf.begin());

   int idx = 0;
   for (int i = 0; i<nl; i++)
   {
      if (i == fixed_param)
         params[i] = fixed_value_cur;
      else
         params[i] = alf[idx++];
   }

   model->setVariables(params);
}
