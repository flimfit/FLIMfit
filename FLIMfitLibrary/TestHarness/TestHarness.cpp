
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

#include "FLIMSimulation.h"
#include <iostream>
#include <string>
#include <cmath>
#include "FitController.h"
#include "MultiExponentialDecayGroup.h"
#include "BackgroundLightDecayGroup.h"
#include "FLIMImage.h"
#include "PatternDecayGroup.h"
#include "GaussianIrfConvolver.h"

extern int testFittingCoreDouble();
extern void testDecayResampler();
extern int testFittingCoreSingle(double tau, int N, bool use_gaussian_irf);
extern int testModelDerivatives(bool use_gaussian_irf);
extern int testFittingCoreMultiChannel();

#define CATCH_CONFIG_MAIN
#include "catch.hpp"


TEST_CASE("Gaussian IRF", "[irf]")
{
   int n_chan = 2;
   std::vector<double> channel_factors{ 1.0, 2.0 };

   FLIMSimulationTCSPC sim(n_chan, 512);

   std::vector<std::shared_ptr<InstrumentResponseFunction>> irfs{
         sim.GetGaussianIRF(),
         sim.GenerateIRF(1e7)
   };

   auto acq = std::make_shared<AcquisitionParameters>(sim);
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

   std::vector<std::vector<double>> decays;
   std::vector<double> diff(acq->n_meas_full);

   for (int i = 0; i < irfs.size(); i++)
   {
      DataTransformationSettings transform(irfs[i]);
      auto data = std::make_shared<FLIMData>(image, transform);
      auto dp = data->GetTransformedDataParameters();

      std::vector<double> a(acq->n_meas_full, 0.0);;

      auto conv = AbstractConvolver::make(dp);

      double tau = 4000;
      conv->compute(1.0 / tau);
      conv->addDecay(2, channel_factors, a.begin());

      tau = 600;
      conv->compute(1.0 / tau);
      conv->addDecay(0.5, channel_factors, a.begin());

      decays.push_back(a);
   }


   for (int i = 0; i < diff.size(); i++)
      diff[i] = (decays[1][i] - decays[0][i]) / decays[0][i];

   for (int i = 0; i < diff.size(); i++)
      if (fabs(diff[i]) > 0.05)
         throw std::runtime_error("Difference too large");

}

TEST_CASE("Convolution", "[model]")
{
   FLIMSimulationTCSPC sim;
   auto acq = std::make_shared<AcquisitionParameters>(sim);

   auto params = sim.getIrfParameters();
   auto irf_gaussian = std::make_shared<InstrumentResponseFunction>();
   irf_gaussian->setGaussianIRF({ params });

   auto transform = DataTransformationSettings(irf_gaussian);
   auto dp = std::make_shared<TransformedDataParameters>(acq, transform);

   GaussianIrfConvolver conv(dp);

   double tau = 2;
   double rate = 1 / tau;

   conv.compute(tau, 0, 0, 0);

   std::vector<double> a(acq->n_meas_full);
   conv.addDecay(1, { 1 }, a.begin());

   for (int i = 0; i < a.size(); i++)
      if (!std::isfinite(a[i]))
         throw std::runtime_error("Non-finite entry");
}

TEST_CASE("Model", "[model]") 
{
   for (bool gaussian_irf : {false, true})
      testModelDerivatives(gaussian_irf);
}

TEST_CASE("Single fit", "[fitting]") 
{
   for (bool gaussian_irf : {false, true})
      for (int tau : {1000, 4000})
         for (int N : {100, 200, 2000, 5000, 10000})
            testFittingCoreSingle(tau, N, gaussian_irf);
}

TEST_CASE("Double fit", "[fitting]")
{
   testFittingCoreDouble();
}

TEST_CASE("Multichannel fit", "[fitting]")
{
   testFittingCoreMultiChannel();
}