
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
#include "Attenuator.h"

#include <boost/math/distributions/students_t.hpp>

bool checkResult(std::shared_ptr<FitResults> results, const std::string& param_name, float expected_value, float expected_std = 0)
{
   auto stats = results->getStats();
   int param_idx = results->getParamIndex(param_name);

   if (param_idx >= 0)
   {
      float mean = stats.GetStat(0, param_idx, PARAM_MEAN);
      float std = stats.GetStat(0, param_idx, PARAM_STD);
      float err = stats.GetStat(0, param_idx, PARAM_ERR_LOWER);
      float n = results->getRegionSummary()[0].size;

      float diff = mean - expected_value;
      float std_use = std;
      // If global, use expected value
      //if (expected_std > 0)
      //   std_use = expected_std;
      if (!isfinite(std_use))
         std_use = 1;

      double t = diff * sqrt(n) / std_use;
      boost::math::students_t dist(n-1);
      double q = boost::math::cdf(complement(dist, fabs(t)));

      bool pass = q > 0.001;

      float rel = fabs(diff) / expected_value;
      //bool pass = (rel <= rel_tol) && std::isfinite(mean);

      //if (expected_std > 0)
      // pass &= (std <= 2 * expected_std);

      printf("Compare %s\n", param_name.c_str());
      printf("   | Expected  : %f\n", expected_value);
      printf("   | Fitted    : %f\n", mean);
      printf("   | Std D.    : %f (%f), %f\n", std, std / sqrt(n-1), expected_std);
      printf("   | Rel Error : %f\n", rel);
      printf("   | p         : %f\n", q);

      if (pass)
         printf("   | PASS\n");
      else
         printf("   | FAIL\n");

      return (pass);
   }

   printf("FAIL: Expected parameter %s not found", param_name.c_str());
   return false;
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
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GetGaussianIRF(); //sim.GenerateIRF(1e5);
   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);
   
   
   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());
    
   std::vector<double> test = { 1000, 3000 };
   auto group = std::make_shared<MultiExponentialDecayGroup>((int) test.size());
   model->addDecayGroup(group);
   
   auto params = group->getParameters();
   for (int i=0; i<params.size(); i++)
   {
      params[i]->setFittingType(Fixed);
      params[i]->setInitialValue(test[i]);
      params[i]->initial_search = false;
//      std::cout << params[i]->name << " " << params[i]->fitting_type << "\n";
   }

   auto bg = std::make_shared<BackgroundLightDecayGroup>();
   bg->getParameter("offset")->setFittingType(FittedLocally);
   bg->getParameter("offset")->setInitialValue(N_bg);
   if (use_background)
      model->addDecayGroup(bg);



   FitController controller;   

   std::vector<FitSettings> settings;
   //settings.push_back(FitSettings(MaximumLikelihood, Pixelwise, GlobalAnalysis, AverageWeighting, 4));
   settings.push_back(FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, AverageWeighting, 1));
   //settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, AverageWeighting, 1));
   settings.push_back(FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 1));
   
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

      //pass &= checkResult(results, "G1_tau_1", tau[0]);
      //pass &= checkResult(results, "G1_tau_2", tau[1]);
      pass &= checkResult(results, "G1_beta_1", beta1);
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

   int n_x = 5;
   int n_chan = 2;

   FLIMSimulationTCSPC sim(n_chan);
   sim.setImageSize(n_x, n_x);

   bool use_background = false;

   // Add decays to image
   int N_bg = 30;

   auto acq = std::make_shared<AcquisitionParameters>(sim);

   std::vector<std::shared_ptr<FLIMImage>> images;

   for (int i = 0; i < 1; i++)
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
   std::shared_ptr<InstrumentResponseFunction> irf;
   if (use_gaussian_irf)
      irf = sim.GetGaussianIRF();
   else
      irf = sim.GenerateIRF(1e6);

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

   std::vector<FitSettings> settings;
   //settings.push_back(FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, AverageWeighting, 4));
   settings.push_back(FitSettings(MaximumLikelihood, Pixelwise, GlobalAnalysis, AverageWeighting, 1));
   //settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, AverageWeighting, 1));
   //settings.push_back(FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 1));
   //settings.push_back(FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, PixelWeighting, 4));
   //settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, PixelWeighting, 4));

   FitController controller;


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

      double expected_std = tau / sqrt(N);
      pass &= checkResult(results, "[1] tau_1", tau, expected_std);
      if (use_background)
         pass &= checkResult(results, "[2] offset", N_bg, 0.5);

      if (!pass)
         throw std::runtime_error("Failed test");
   }

   return 0;
}



int testFittingCoreMultiChannel()
{
   std::vector<double> tau = { 1000 , 3000 };
   std::vector<double> test = { 700, 4000 };

   //std::vector<std::vector<double>> channel_factors = { { 0.5, 0.25, 0.25 },{ 0.25, 0.5, 0.25 }, { 0.33, 0.33, 0.34 } };
   std::vector<std::vector<double>> channel_factors = { { 0.75, 0.25 },{ 0.25, 0.75 } };

   int n_x = 50;
   int n_y = 50;

   // Create simulator
   FLIMSimulationTCSPC sim(test.size());
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
         for (int c = 0; c < channel_factors.size(); c++)
            sim.GenerateImage(tau[j], N * channel_factors[j][c], c, data_ptr);
      image->releaseModifiedPointer<uint32_t>();

      images.push_back(image);
   }

   std::vector<std::shared_ptr<Attenuator>> attenuator;
   attenuator.push_back(std::make_shared<Attenuator>([&](int x, int y) { return (0.1 * x) / n_x + 0.4; }, 1));
   //attenuator.push_back(std::make_shared<Attenuator>([&](int x, int y) { return (0.2 * y) / n_y + 0.4; }, 2));

   for(auto& im : images)
      for(auto& a : attenuator)
         a->attenuate(im);


   // Make data
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GetGaussianIRF(); //sim.GenerateIRF(1e5);
   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);


   auto model = std::make_shared<DecayModel>();
   model->setZernikeOrder(1);
   model->setUseSpectralCorrection(true);
   model->setTransformedDataParameters(data->GetTransformedDataParameters());

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


   FitController controller;

   std::vector<FitSettings> settings;
   //settings.push_back(FitSettings(MaximumLikelihood, Pixelwise, GlobalAnalysis, AverageWeighting, 4));
   //settings.push_back(FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, PixelWeighting, 1));
   //settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, AverageWeighting, 1));
   settings.push_back(FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 8));

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

      pass &= checkResult(results, "G1_tau_1", tau[0]);
      pass &= checkResult(results, "G2_tau_1", tau[1]);
      //checkResult(results, "G1_I_0", N / tau[0] * 1000);
      //checkResult(results, "G2_I_0", N / tau[1] * 1000);
      //pass &= checkResult(results, "G3_I_0", 0.1);

      //      pass &= checkResult(results, "[1] beta_1", beta1);

      if (!pass)
         throw std::runtime_error("Failed test");
   }

   return 0;
}
