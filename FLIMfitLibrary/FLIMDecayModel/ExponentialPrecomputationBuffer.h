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
#pragma warning(disable : 4309)

#include "InstrumentResponseFunction.h"
#include "DataTransformer.h"

#include <boost/align/aligned_allocator.hpp>
#include <vector>
#include <memory>

// Aligned allocated
template<class T, std::size_t Alignment = 16>
using aligned_vector = std::vector<T,
   boost::alignment::aligned_allocator<T, Alignment> >;

class ExponentialPrecomputationBuffer
{
public:
   ExponentialPrecomputationBuffer(std::shared_ptr<TransformedDataParameters> dp);
   void compute(double rate, int irf_idx, double t0_shift, const std::vector<double>& channel_factors, bool compute_shifted_models = false);

   void addDecay(double fact, double ref_lifetime, double a[], int bin_shift = 0) const;
   void addDerivative(double fact, double ref_lifetime, double b[]) const;

   double getRate() const { return rate; };

private:

   void calculateIRFMax();
   
   void computeIRFFactors(double rate, int irf_idx, double t0_shift);
   void computeModelFactors(double rate, const std::vector<double>& channel_factors, bool compute_shifted_models);

   void convolve(int k, int i, double pulse_fact, int bin_shift, double& c) const;
   void convolveDerivative(double t, int k, int i, double pulse_fact, double pulse_fact_der, double ref_fact_a, double ref_fact_b, double& c) const;


   std::vector<aligned_vector<double>> irf_exp_factor;
   std::vector<aligned_vector<double>> cum_irf_exp_factor;
   std::vector<aligned_vector<double>> irf_exp_t_factor;
   std::vector<aligned_vector<double>> cum_irf_exp_t_factor;
   std::vector<aligned_vector<double>> model_decay;
   std::vector<aligned_vector<double>> shifted_model_decay_high;
   std::vector<aligned_vector<double>> shifted_model_decay_low;
   aligned_vector<double> irf_working;

   std::shared_ptr<InstrumentResponseFunction> irf;
   std::shared_ptr<TransformedDataParameters> dp;
   
   double rate;

   int n_irf;
   int n_chan;
   int n_t;
   std::vector<int> irf_max;
};

/*
class DecayModelWorkingBuffers : public AcquisitionParameters
{
   friend class DecayModel;

public:
   DecayModelWorkingBuffers(std::shared_ptr<DecayModel> model);
   ~DecayModelWorkingBuffers();

   //void add_decay(int tau_idx, int theta_idx, int fret_group_idx, double fact, double ref_lifetime, double a[], int bin_shift = 0);
   //void add_derivative(int tau_idx, int theta_idx, int fret_group_idx, double fact, double ref_lifetime, double b[]);


private:

   void PrecomputeExponentials(const std::vector<double>& new_alf, int irf_idx, double t0_shift);
   int check_alf_mod(const std::vector<double>& new_alf, int irf_idx);

   //void Convolve(double rate, int row, int k, int i, double pulse_fact, int bin_shift, double& c);
   //void ConvolveDerivative(double t, double rate, int row, int k, int i, double pulse_fact, double ref_fact_a, double ref_fact_b, double& c);



   std::shared_ptr<DecayModel> model;

   std::vector<ExponentialPrecomputationBuffer> exp_buffer;

   int n_irf;
   int n_exp;

   int n_pol_group;
   int n_fret_group;

   int pulsetrain_correction;

   int* irf_max;

   std::shared_ptr<InstrumentResponseFunction> irf;

   int cur_irf_idx;

   double *tau_buf;
   double *beta_buf;
   double *theta_buf;
   double *irf_buf;
   double *cur_alf;

   bool first_eval;

};
*/