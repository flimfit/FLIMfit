
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
      bool pass = (rel <= rel_tol);

      printf("Compare %s\n", param_name.c_str());
      printf("   | Expected  : %f\n", expected_value);
      printf("   | Fitted    : %f\n", mean);
      printf("   | Std D.    : %f\n", std);
      printf("   | Rel Error : %f\n", rel);

      if (pass)
         printf("   | PASS\n");
      else
         printf("   | FAIL\n");

      return (pass);
   }

   printf("FAIL: Expected parameter %s not found", param_name.c_str());
   return false;
}

int testFittingCore()
{
   FLIMSimulationTCSPC sim;


   std::vector<double> irf;
   std::vector<float>  image_data;
   std::vector<double> t;
   std::vector<double> t_int;

   int n_x = 20;
   int n_y = 20;

   int N = 10000;
   std::vector<double> tau = { 1000, 3000 };
 

   sim.GenerateIRF(1e5, irf);

   for (auto taui : tau)
      sim.GenerateImage(taui, N, n_x, n_y, image_data);
   

   double beta1 = tau[1] / (tau[0] + tau[1]); // equal photons for each decay

   int n_t = sim.GetTimePoints(t, t_int);
   int n_irf = n_t;

   // Data Parameters
   //===========================
   std::vector<int> use_im(n_x, 1);
   
   
   int algorithm = ALG_LM;

   int data_type = DATA_TYPE_TCSPC;
   bool polarisation_resolved = false;

   int n_chan = 1;

   auto irf_ = std::make_shared<InstrumentResponseFunction>();
   irf_->setIRF(n_irf, n_chan, t[0], t[1] - t[0], irf.data());

   auto acq = std::make_shared<AcquisitionParameters>(data_type, t_rep_default, polarisation_resolved, n_chan);
   acq->setT(t);
   acq->setImageSize(n_x, n_y);
   
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::DataMode::InMemory, image_data.data());
   image->init();
   
   DataTransformationSettings transform;
   transform.irf = irf_;
   auto data = std::make_shared<FLIMData>(image, transform);
   
   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());
   

   std::vector<double> test = { 1500, 2000 };

   auto group = std::make_shared<MultiExponentialDecayGroup>(test.size());
   model->addDecayGroup(group);
   
   auto params = group->getParameters();
   for (int i=0; i<params.size(); i++)
   {
      params[i]->fitting_type = ParameterFittingType::FittedGlobally;
      params[i]->initial_value = test[i];
      std::cout << params[i]->name << " " << params[i]->fitting_type << "\n";
   }

   FitController controller;   
   controller.setFitSettings(FitSettings(algorithm, MODE_IMAGEWISE, AVERAGE_WEIGHTING, 4));
   controller.setModel(model);

   controller.setData(data);
   controller.init();
   controller.runWorkers();
   
   controller.waitForFit();
   
   // Get results
   auto results = controller.getResults();
   auto stats = results->getStats();

   bool pass = true;
   pass &= checkResult(results, "[1] tau_1", tau[0], 0.01);
   pass &= checkResult(results, "[1] tau_2", tau[1], 0.01);
   pass &= checkResult(results, "[1] beta_1", beta1, 0.01);

   //__debugbreak();

   return !pass;
}