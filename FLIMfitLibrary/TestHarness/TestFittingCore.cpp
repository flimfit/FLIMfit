
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

#define M_PI 3.14159265358979323846264338327950288

#include "FLIMSimulation.h"

#include <iostream>
#include <string>
#include <cmath>
#include "FitController.h"
#include "MultiExponentialDecayGroup.h"
#include "BackgroundLightDecayGroup.h"
#include "FLIMImage.h"
#include "PatternDecayGroup.h"
#include "Attenuator.h"

#include <boost/math/distributions/students_t.hpp>

bool checkResult(std::shared_ptr<FitResults> results, const std::string& param_name, float expected_value, float expected_std = 0)
{
   auto stats = results->getStats();
   int param_idx = results->getParamIndex(param_name);

   bool pass = true;

   if (param_idx == -1)
   {
      printf("FAIL: Expected parameter %s not found", param_name.c_str());
      return false;
   }
   
   for (int i = 0; i < stats.GetNumRegions(); i++)
   {
      float mean = stats.GetStat(i, param_idx, PARAM_MEAN);
      float std = stats.GetStat(i, param_idx, PARAM_STD);
      float err = stats.GetStat(i, param_idx, PARAM_ERR_LOWER);
      float n = results->getRegionSummary()[i].size;

      float diff = mean - expected_value;
      float std_use = std;

      // If global, use expected value
      if (!isfinite(std_use))
      {
         if (expected_std > 0)
            std_use = expected_std;
         else
            std_use = 1;
      }

      double t = diff * sqrt(n - 1) / (1.5 * std_use);
      boost::math::students_t dist(n - 1);
      double q = boost::math::cdf(complement(dist, fabs(t)));
      bool this_pass = q > 0.001;

      float rel = fabs(diff) / expected_value;



      if (true)
      {
         printf("Compare %s\n", param_name.c_str());
         printf("   | Expected  : %f\n", expected_value);
         printf("   | Fitted    : %f\n", mean);
         printf("   | Std D.    : %f (%f), %f\n", std, std / sqrt(n - 1), expected_std);
         printf("   | Rel Error : %f\n", rel);
         printf("   | p         : %f\n", q);
         if (this_pass)
            printf("   | PASS\n");
         else
            printf("   | FAIL\n");

      }

      pass &= this_pass;
   }

   return pass;
}

int testFittingCoreDouble()
{
   // Create simulator
   FLIMSimulationTCSPC sim;
   sim.setImageSize(10, 10);

   bool use_background = false;

   int n_image = 2;

   // Add decays to image
   int N_bg = 10;
   int N = 10000;
   std::vector<double> tau = { 1000 , 3000 };
   double beta1 = tau[1] / (tau[0] + tau[1]); // equal photons for each decay

   // Create images
   auto acq = std::make_shared<AcquisitionParameters>(sim);

   std::vector<std::shared_ptr<FLIMImage>> images;

   for (int i = 0; i < n_image; i++)
   {
      auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

      auto data_ptr = image->getDataPointer<uint16_t>();
      size_t sz = image->getImageSizeInBytes();
      std::fill_n((char*)data_ptr, sz, 0);
      for (auto taui : tau)
         sim.GenerateImage(taui, N, 0, data_ptr);
      if (use_background)
         sim.GenerateImageBackground(N_bg, data_ptr);
      image->releaseModifiedPointer<uint16_t>();

      images.push_back(image);
   }

   // Make data
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GetGaussianIRF();
   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);
   
   
   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());
    
   std::vector<double> test = { 800, 4000 };
   auto group = std::make_shared<MultiExponentialDecayGroup>((int) test.size());
   model->addDecayGroup(group);
   
   auto params = group->getParameters();
   for (int i=0; i<params.size(); i++)
   {
      params[i]->setFittingType(FittedGlobally);
      params[i]->setInitialValue(test[i]);
      params[i]->initial_search = false;
   }

   auto bg = std::make_shared<BackgroundLightDecayGroup>();
   bg->getParameter("offset")->setFittingType(FittedLocally);
   bg->getParameter("offset")->setInitialValue(N_bg);
   if (use_background)
      model->addDecayGroup(bg);



   FitController controller;   

   std::vector<FitSettings> settings {
      FitSettings(MaximumLikelihood, Pixelwise, GlobalAnalysis, AverageWeighting, 4),
      FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, AverageWeighting, 1),
      FitSettings(VariableProjection, Imagewise, GlobalAnalysis, AverageWeighting, 1),
      FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 1)
   };
   
   bool pass = true;

   for (auto s : settings)
   {
      controller.setFitSettings(s);
      controller.setModel(model);
      controller.setData(data);
      controller.init();
      controller.runWorkers();

      controller.waitForFit();

      // Get results
      auto results = controller.getResults();
      auto stats = results->getStats();

      pass &= checkResult(results, "G1_tau_1", tau[0], 100);
      pass &= checkResult(results, "G1_tau_2", tau[1], 100);
      //pass &= checkResult(results, "G1_beta_1", beta1);
      if (use_background)
         pass &= checkResult(results, "G2_offset", N_bg, 0.5);

      if (!pass)
         throw std::runtime_error("Failed test");
   }

   return 0;
}


int testFittingCoreSingle(double tau, int N, bool use_gaussian_irf)
{
   // Create simulator
   int n_t = use_gaussian_irf ? 66 : 512;
   int n_x = 5;
   int n_chan = 1;
   int n_im = 3;

   FLIMSimulationTCSPC sim(n_chan, n_t);
   sim.setImageSize(n_x, n_x);

   bool use_background = false;

   // Add decays to image
   int N_bg = 30;

   auto acq = std::make_shared<AcquisitionParameters>(sim);

   double dt = acq->t_rep / acq->n_t_full;

   double expected_I0 = N / tau * dt;


   std::vector<std::shared_ptr<FLIMImage>> images;

   for (int i = 0; i < n_im; i++)
   {
      auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

      auto data_ptr = image->getDataPointer<uint16_t>();
      size_t sz = image->getImageSizeInBytes();
      std::fill_n((char*)data_ptr, sz, 0);
      for(int c=0; c<n_chan; c++)
         sim.GenerateImage(tau, N * (1+0.5*c), c, data_ptr);
      if (use_background)
         sim.GenerateImageBackground(N_bg, data_ptr);
      image->releaseModifiedPointer<uint16_t>();

      images.push_back(image);
   }

   // Make data
   auto irf = (use_gaussian_irf) ? sim.GetGaussianIRF() : sim.GenerateIRF(1e6);

   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);


   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());

   std::vector<double> test = { 1.2 * tau };
   auto group = std::make_shared<MultiExponentialDecayGroup>((int)test.size());
   group->setFitChannelFactors(false);
   model->addDecayGroup(group);

   auto params = group->getParameters();
   for (int i = 0; i < test.size(); i++)
   {
      params[i]->setFittingType(FittedGlobally);
      params[i]->setInitialValue(test[i]);
   }

   //params[1]->setFittingType(FittedGlobally);

   auto bg = std::make_shared<BackgroundLightDecayGroup>();
   bg->getParameter("offset")->setFittingType(FittedLocally);
   bg->getParameter("offset")->setInitialValue(N_bg);
   if (use_background)
      model->addDecayGroup(bg);

   std::vector<FitSettings> settings {
      FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, AverageWeighting, 4),
      FitSettings(VariableProjection, Imagewise, GlobalAnalysis, AverageWeighting, 1),
      FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 1),
      FitSettings(MaximumLikelihood, Pixelwise, GlobalAnalysis, AverageWeighting, 4)
   };
   
   FitController controller;
   FittingOptions options;

   options.use_ml_refinement = true;

   bool pass = true;
   for (auto s : settings)
   {
      controller.setFitSettings(s);
      controller.setFittingOptions(options);
      controller.setModel(model);
      controller.setData(data);
      controller.init();
      controller.runWorkers();

      controller.waitForFit();

      // Get results
      auto results = controller.getResults();
      auto stats = results->getStats();

      double expected_std = tau / sqrt(N);
      pass &= checkResult(results, "G1_tau_1", tau, expected_std);
      pass &= checkResult(results, "G1_I_0", expected_I0);
      if (use_background)
         pass &= checkResult(results, "G2_offset", N_bg, 0.5);

      if (!pass)
         throw std::runtime_error("Failed test");
   }

   return 0;
}



int testFittingCoreMultiChannel()
{
   std::vector<double> tau = { 1000, 3000 };
   std::vector<double> test = { 700, 4000 };

   std::vector<std::vector<double>> channel_factors = { { 0.5, 0.25, 0.25 },{ 0.25, 0.5, 0.25 } };
   //std::vector<std::vector<double>> channel_factors = { { 0.75, 0.25 },{ 0.25, 0.75 } };

   int n_x = 50;
   int n_y = 50;

   // Create simulator
   FLIMSimulationTCSPC sim(channel_factors[0].size());
   sim.setImageSize(n_x, n_y);

   bool use_background = false;

   int n_image = 1;

   // Add decays to image
   int N = 5000;

   // Create images
   auto acq = std::make_shared<AcquisitionParameters>(sim);
   std::vector<std::shared_ptr<FLIMImage>> images;

   for (int i = 0; i < n_image; i++)
   {
      auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint32);

      auto data_ptr = image->getDataPointer<uint32_t>();
      size_t sz = image->getImageSizeInBytes();
      std::fill_n((char*)data_ptr, sz, 0);
      for (int j = 0; j < tau.size(); j++)
         for (int c = 0; c < channel_factors[j].size(); c++)
            sim.GenerateImage(tau[j], N * channel_factors[j][c], c, data_ptr);
      image->releaseModifiedPointer<uint32_t>();


      // Add circular segmentation mask
      cv::Mat mask(n_y, n_x, CV_16U);
      double r2 = n_x * n_y;
      for (int i = 0; i < n_x*n_y; i++)
      {
         double x = ((double)(i % n_x - n_x/2)) / n_x;
         double y = ((double)(i / n_x - n_x/2)) / n_y;
         double angle = atan2(y, x) / M_PI + 1.0;
         int idx = floor(angle * 2);
         mask.at<uint16_t>(i) = (x*x + y * y < r2) ? idx : 0;
      }
      image->setSegmentationMask(mask);

      images.push_back(image);

   }

   std::vector<std::shared_ptr<Attenuator>> attenuator{
      //std::make_shared<Attenuator>([&](int x, int y) { return (0.1 * x) / n_x + 0.4; }, 1),
      //std::make_shared<Attenuator>([&](int x, int y) { return (0.1 * y) / n_y + 0.4; }, 1),
      std::make_shared<Attenuator>([&](int x, int y) { return (0.1 * x) * (0.1 * y) / (n_y * n_x) + 0.4; }, 1),
      std::make_shared<Attenuator>([&](int x, int y) { return (0.1 * x) * (0.1 * y) / (n_y * n_x) + 0.4; }, 2),
   };

   //for(auto& im : images)
   //   for(auto& a : attenuator)
   //      a->attenuate(im);


   // Make data
   // std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GetGaussianIRF();
   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);


   auto model = std::make_shared<DecayModel>();
   //model->setZernikeOrder(2);
   //model->setUseSpectralCorrection(true);
   //model->setTransformedDataParameters(data->GetTransformedDataParameters());

   auto params = model->getParameters();
   std::for_each(params.begin(), params.end(), [](auto& p) { p->setFittingType(FittedGlobally); });

   for (int i = 0; i < test.size(); i++)
   {
      auto group = std::make_shared<MultiExponentialDecayGroup>(1);
      group->setChannelFactors(0, channel_factors[i]);
      model->addDecayGroup(group);

      auto params = group->getParameters();
      params[0]->setFittingType(FittedGlobally);
      params[0]->setInitialValue(test[i]);
      params[0]->initial_search = false;
   }

   std::vector<FitSettings> settings {
      FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 8)
   };

   FitController controller;
   FittingOptions opts;
   opts.initial_step_size = 0.01;

   bool pass = true;

   for (auto s : settings)
   {
      controller.setFitSettings(s);
      controller.setFittingOptions(opts);
      controller.setModel(model);
      controller.setData(data);
      controller.init();
      controller.runWorkers();

      controller.waitForFit();

      // Get results
      auto results = controller.getResults();
      auto stats = results->getStats();

      pass &= checkResult(results, "G1_tau_1", tau[0], 100);
      pass &= checkResult(results, "G2_tau_1", tau[1], 100);
      //checkResult(results, "G1_I_0", N / tau[0] * 1000);
      //checkResult(results, "G2_I_0", N / tau[1] * 1000);
      //pass &= checkResult(results, "G3_I_0", 0.1);
      //pass &= checkResult(results, "G1_beta_1", beta1);

      if (!pass)
         throw std::runtime_error("Failed test");
   }

   return 0;
}
