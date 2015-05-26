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

#ifndef _ABSTRACTFITTER_H
#define _ABSTRACTFITTER_H

#include "DecayModel.h"
#include "ExponentialPrecomputationBuffer.h"
#include "FitResults.h"
#include "RegionData.h"
#include "MeanLifetimeEstimator.h"
#include "ProgressReporter.h"

#include "omp_stub.h"
#include "levmar.h"

#include <cstdio>

#include <memory>
#include <boost/ptr_container/ptr_vector.hpp>

using boost::ptr_vector;

class AbstractFitter
{
public:

   AbstractFitter(shared_ptr<DecayModel> model, int n_param_extra, int max_region_size, int global_algorithm, int n_thread, std::shared_ptr<ProgressReporter> reporter);

   virtual ~AbstractFitter() {};
   //virtual AbstractFitter* clone() const = 0; // for boost ptr_vector

   virtual int FitFcn(int nl, vector<double>& alf, int itmax, int* niter, int* ierr) = 0;
   virtual int GetLinearParams() = 0;
   
   int Fit(RegionData& region_data, FitResultsRegion& results, int itmax, int& niter, int &ierr, double& c2);
   int GetFit(int irf_idx, const vector<double>& alf, float* lin_params, double* fit);
   double ErrMinFcn(double x);
   int CalculateErrors(double conf_limit);

   void GetParams(int nl, const vector<double>& alf);
   
   void SetAlf(const double* alf_);
   double* GetModel(const vector<double>& alf, int irf_idx, int isel, int thread);


   double* GetModel(const double* alf, int irf_idx, int isel, int thread);
   void ReleaseResidualMemory();

protected:

   int Init();

   shared_ptr<DecayModel> model;
   vector<DecayModel> models;
   shared_ptr<ProgressReporter> reporter;
   
   vector<double> alf;
   vector<double> err_lower;
   vector<double> err_upper;

   // Used by variable projection
   int     inc[96];
   int     inc_full[96];
   //int     ncon;
   //int     nconp1;
   int     philp1;

   vector<vector<double>> a_;
   vector<vector<double>> b_;
   vector<double> r;
   vector<double> kap;
   vector<double> params; 
   vector<double> alf_err;
   vector<double> alf_buf;

   int     n;
   int     nl;
   int     ndim;
   int     nmax;
   int     s;
   int     l;
   int     lmax;
   int     n_param;
   int     p;
   int     pmax;

   int     max_region_size;

   float*  y;
   vector<float> w;
   vector<float> avg_y;
   float *lin_params;
   float *chi2;
   int    *irf_idx;

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

   int global_algorithm;
   double conf_limit;

   int search_dir;

   FILE* f_debug;

   int a_size;
   int b_size;

   int irf_idx_0;
};

#endif