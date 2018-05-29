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

#include "AbstractConvolver.h"

#include <vector>
#include <memory>


class MeasuredIrfConvolver : public AbstractConvolver
{

public:
   MeasuredIrfConvolver(std::shared_ptr<TransformedDataParameters> dp);

   void compute(double rate, int irf_idx, double t0_shift);

   void addDecay(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double a[]) const;
   void addDerivative(double fact, const std::vector<double>& channel_factors, double ref_lifetime, double b[]) const;

private:

   void calculateIRFMax();
   
   void computeIRFFactors(double rate, int irf_idx, double t0_shift);
   void computeModelFactors(double rate);

   void convolve(int k, int i, double pulse_fact, double& c) const;
   void convolveDerivative(double t, int k, int i, double pulse_fact, double pulse_fact_der, double ref_fact_a, double ref_fact_b, double& c) const;


   std::vector<aligned_vector<double>> irf_exp_factor;
   std::vector<aligned_vector<double>> cum_irf_exp_factor;
   std::vector<aligned_vector<double>> irf_exp_t_factor;
   std::vector<aligned_vector<double>> cum_irf_exp_t_factor;
   aligned_vector<double> model_decay;
   aligned_vector<double> irf_working;

   int n_irf;
   std::vector<int> irf_max;
};