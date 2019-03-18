
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

#include <chrono>

#define USE_SIMD
#include "FastErf.h"
typedef double ty;

__declspec(noinline)
void erf_vec_real(const aligned_vector<ty>& x, aligned_vector<ty>& y)
{
   for (int i = 0; i < x.size(); i++)
      y[i] = erf(x[i]);
}

__declspec(noinline)
void erf_vec_fast(const aligned_vector<ty>& x, aligned_vector<ty>& y)
{
   __m256d* xd = (__m256d*) x.data();
   __m256d* yd = (__m256d*) y.data();

   int N4 = x.size() / 4;
   for (int i = 0; i < N4; i++)
      yd[i] = verf_pd(xd[i]);
}

TEST_CASE("Gaussian IRF", "[irf]")
{
   using namespace std;
   using namespace std::chrono;
   
   int N = 1000;
   aligned_vector<ty> x(N);
   aligned_vector<ty> erf_real(N);
   aligned_vector<ty> erf_fast(N);

   for (int i = 0; i < N; i++)
      x[i] = ((ty)i) / (N - 1) * 20;

   auto start = steady_clock::now(); 
   for (int i = 0; i<100; i++)
      erf_vec_real(x, erf_real);
   auto real_t = steady_clock::now() - start;

   auto start2 = steady_clock::now();
   for (int i = 0; i<100; i++)
      erf_vec_fast(x, erf_fast);
   auto fast_t = steady_clock::now() - start2;

   double max_diff = 0;
   for (int i = 0; i < N; i++)
   {
      double diffx = std::abs(erf_real[i] - erf_fast[i]);
      max_diff = std::max(max_diff, diffx);
   }

   std::cout << "Max diff: " << max_diff << std::endl;
   std::cout << "T real:" << duration <double, milli>(real_t).count() << " ms" << std::endl;
   std::cout << "T fast:" << duration <double, milli>(fast_t).count() << " ms" << std::endl;
   


   int n_chan = 2;
   std::vector<double> channel_factors{ 1.0, 2.0 };

   FLIMSimulationTCSPC sim(n_chan, 512);

   std::vector<std::shared_ptr<InstrumentResponseFunction>> irfs{
         sim.GetGaussianIRF(),
         sim.GenerateIRF(1e7)
   };

   auto acq = std::make_shared<AcquisitionParameters>(sim);
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

   std::vector<aligned_vector<double>> decays;
   std::vector<double> diff(acq->n_meas_full);

   for (int i = 0; i < irfs.size(); i++)
   {
      DataTransformationSettings transform(irfs[i]);
      auto data = std::make_shared<FLIMData>(image, transform);
      auto dp = data->GetTransformedDataParameters();

      aligned_vector<double> a(acq->n_meas_full, 0.0);;

      auto conv = AbstractConvolver::make(dp);

      auto start = steady_clock::now();
      for (int k = 0; k < 1; k++)
      {
         std::fill(a.begin(), a.end(), 0);
         for (int j = 0; j < 100; j++)
         {
            double tau = 4000 + j;
            conv->compute(1.0 / tau);
            conv->addDecay(2, channel_factors, a.begin());

            tau = 600 + j;
            conv->compute(1.0 / tau);
            conv->addDecay(0.5, channel_factors, a.begin());
         }
      }
      auto fast_t = steady_clock::now() - start;
      std::cout << "T :" << duration <double, milli>(fast_t).count() << " ms" << std::endl;


      decays.push_back(a);
   }


   for (int i = 0; i < diff.size(); i++)
      diff[i] = (decays[1][i] - decays[0][i]) / decays[0][i];

   for (int i = 0; i < diff.size(); i++)
      if (fabs(diff[i]) > 0.05)
         throw std::runtime_error("Difference too large");

}

#include "RegionStatsCalculator.h"

TEST_CASE("Truncated mean", "[stats]")
{
   RegionStats<float> stats(2, 1);

   int n = 200000;
   std::vector<float> x(n), w(n, 1.0);

   float mu = 0.2, sigma = 4;

   auto norm_dist = boost::random::normal_distribution<double>(mu, sigma);

   boost::lagged_fibonacci44497 gen;
   gen.seed(100);

   for (int i = 0; i < n; i++)
      x[i] = norm_dist(gen);


   RegionStatsCalculator calc(0.05);
   calc.calculateRegionStats(n, x.begin(), 1, w.begin(), 1, stats, 1);

   float est_mu = stats.GetStat(1, 0, PARAM_MEAN);
   float est_sigma = stats.GetStat(1, 0, PARAM_STD);

   std::cout << "mu: " << est_mu << " (" << mu << ")" << ", " << "sigma: " << est_sigma << " (" << sigma << ")" << std::endl;

   if (abs(mu - est_mu) > 0.05) throw std::runtime_error("Error in estimated truncated mean");
   if (abs(sigma - est_sigma) > 0.5) throw std::runtime_error("Error in estimated truncated mean");

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

   aligned_vector<double> a(acq->n_meas_full);
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
