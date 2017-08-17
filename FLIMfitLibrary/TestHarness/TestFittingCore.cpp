
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

bool checkResult(std::shared_ptr<FitResults> results, const std::string& param_name, float expected_value, float rel_tol)
{
   auto stats = results->getStats();
   int param_idx = results->getParamIndex(param_name);

   if (param_idx >= 0)
   {
      float mean = stats.GetStat(0, param_idx, PARAM_MEAN);
      float std = stats.GetStat(0, param_idx, PARAM_STD);
      float diff = mean - expected_value;
      float rel = fabs(diff) / expected_value;
      bool pass = (rel <= rel_tol) && std::isfinite(mean);

      printf("Compare %s\n", param_name.c_str());
      printf("   | Expected  : %f\n", expected_value);
      printf("   | Fitted    : %f\n", mean);
      printf("   | Std D.    : %f\n", std);
      printf("   | Rel Error : %f (%f)\n", rel, rel_tol);

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
   sim.setImageSize(20, 20);

   bool use_background = false;

   // Add decays to image
   int N_bg = 10;
   int N = 10000;
   std::vector<double> tau = { 1000 , 3000 };
   double beta1 = tau[1] / (tau[0] + tau[1]); // equal photons for each decay

   // Create images
   auto acq = std::make_shared<AcquisitionParameters>(sim);

   std::vector<std::shared_ptr<FLIMImage>> images;

   for (int i = 0; i < 2; i++)
   {
      auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

      auto data_ptr = image->getDataPointer<uint16_t>();
      int sz = image->getImageSizeInBytes();
      std::fill_n((char*)data_ptr, sz, 0);
      for (auto taui : tau)
         sim.GenerateImage(taui, N, data_ptr);
      if (use_background)
         sim.GenerateImageBackground(N_bg, data_ptr);
      image->releaseModifiedPointer<uint16_t>();

      images.push_back(image);
   }

   // Make data
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);
   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);
   
   
   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());
   
   std::vector<double> test = { 500, 4000 };
   auto group = std::make_shared<MultiExponentialDecayGroup>((int) test.size());
   model->addDecayGroup(group);
   
   auto params = group->getParameters();
   for (int i=0; i<params.size(); i++)
   {
      params[i]->fitting_type = ParameterFittingType::FittedGlobally;
      params[i]->initial_value = test[i];
      std::cout << params[i]->name << " " << params[i]->fitting_type << "\n";
   }

   auto bg = std::make_shared<BackgroundLightDecayGroup>();
   bg->getParameter("offset")->fitting_type = ParameterFittingType::FittedLocally;
   bg->getParameter("offset")->initial_value = N_bg;
   if (use_background)
      model->addDecayGroup(bg);



   FitController controller;   

   std::vector<FitSettings> settings;
   settings.push_back(FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, AverageWeighting, 4));
   settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, AverageWeighting, 4));
   settings.push_back(FitSettings(VariableProjection, Global, GlobalAnalysis, AverageWeighting, 4));
   
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

      pass &= checkResult(results, "[1] tau_1", tau[0], 0.02);
      pass &= checkResult(results, "[1] tau_2", tau[1], 0.02);
      pass &= checkResult(results, "[1] beta_1", beta1, 0.05);
      if (use_background)
         pass &= checkResult(results, "[2] offset", N_bg, 0.5);

      assert(pass);
   }

   return 0;
}


int testFittingCoreSingle(double tau, int N)
{
   // Create simulator

   int n_x = 20;

   FLIMSimulationTCSPC sim;
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
      int sz = image->getImageSizeInBytes();
      std::fill_n((char*)data_ptr, sz, 0);
      sim.GenerateImage(tau, N, data_ptr);
      if (use_background)
         sim.GenerateImageBackground(N_bg, data_ptr);
      image->releaseModifiedPointer<uint16_t>();

      images.push_back(image);
   }

   // Make data
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);
   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(images, transform);


   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());

   std::vector<double> test = {2000};
   auto group = std::make_shared<MultiExponentialDecayGroup>((int)test.size());
   model->addDecayGroup(group);

   auto params = group->getParameters();
   for (int i = 0; i < params.size(); i++)
   {
      params[i]->fitting_type = ParameterFittingType::FittedGlobally;
      params[i]->initial_value = test[i];
   }

   auto bg = std::make_shared<BackgroundLightDecayGroup>();
   bg->getParameter("offset")->fitting_type = ParameterFittingType::FittedLocally;
   bg->getParameter("offset")->initial_value = N_bg;
   if (use_background)
      model->addDecayGroup(bg);

   std::vector<FitSettings> settings;
   settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, PixelWeighting, 1));
   settings.push_back(FitSettings(VariableProjection, Pixelwise, GlobalAnalysis, PixelWeighting, 4));
   settings.push_back(FitSettings(VariableProjection, Imagewise, GlobalAnalysis, PixelWeighting, 4));
   settings.push_back(FitSettings(VariableProjection, Global, GlobalAnalysis, PixelWeighting, 4));

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

      double rel = std::max(0.0001, 6.0 / (sqrt(N - 1) * sqrt(n_x*n_x - 1)));
      pass &= checkResult(results, "[1] tau_1", tau, rel);
      if (use_background)
         pass &= checkResult(results, "[2] offset", N_bg, 0.5);

      if (!pass)
         throw std::runtime_error("Failed test");
   }

   return 0;
}