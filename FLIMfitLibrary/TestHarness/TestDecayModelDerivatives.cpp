
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
#include "AnisotropyDecayGroup.h"
#include "FLIMImage.h"
#include "PatternDecayGroup.h"

void validate(std::vector<std::shared_ptr<AbstractDecayGroup>> groups)
{

   FLIMSimulationTCSPC sim;
   //std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GetGaussianIRF();
   auto acq = std::make_shared<AcquisitionParameters>(sim);
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(image, transform);

   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());

   for (auto& g : groups)
   {
      auto params = g->getParameters();
      std::for_each(params.begin(), params.end(), [](auto& p) { p->setFittingType(FittedGlobally); });
      model->addDecayGroup(g);
   }
   
   model->init();
   model->validateDerivatives();

}

void validate(std::shared_ptr<AbstractDecayGroup> g)
{

   //std::cout << "\nTesting derivatives for " << g->objectName().toStdString() << "\n================\n";
   
   int n_chan = 2;
   FLIMSimulationTCSPC sim(n_chan);
   //std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GetGaussianIRF();
   auto acq = std::make_shared<AcquisitionParameters>(sim);
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(image, transform);

   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());

   model->t0_parameter->setFittingType(FittedGlobally);

   model->addDecayGroup(g);
   model->init();

   // Test with all free
   auto params = g->getParameters();
   std::for_each(params.begin(), params.end(), [](auto& p) { p->setFittingType(FittedGlobally); });
   model->init();
   model->validateDerivatives();

   // Test with one fixed
   for (int i = 0; i < params.size(); i++)
   {
      std::for_each(params.begin(), params.end(), [](auto& p) { p->setFittingType(FittedGlobally); });
      params[i]->setFittingType(Fixed);
      model->init();
      model->validateDerivatives();
   }

   // Test with two fixed
   for (int i = 0; i < params.size(); i++)
   {
      for (int j = i+1; j < params.size(); j++)
      {
         std::for_each(params.begin(), params.end(), [](auto& p) { p->setFittingType(FittedGlobally); });
         params[i]->setFittingType(Fixed);
         params[j]->setFittingType(Fixed);
         model->init();
         model->validateDerivatives();
      }
   }

}

int testModelDerivatives()
{
   
   // Fitting channel factors
   {
      auto group = std::make_shared<MultiExponentialDecayGroup>(2);
      group->setFitChannelFactors(true);
      validate(group);
   }

   // Test multiexponential group
   for (int n_exp : { 1,3 })
   {
      auto group = std::make_shared<MultiExponentialDecayGroup>(n_exp);
      validate(group);

      // with global beta
      group->setContributionsGlobal(true);
      validate(group);
   }


   // Test FRET group
   for (int n_fret : {1, 2})
      for (int n_exp : {1, 3})
         for (int n_acc : {1, 2})
         {
            auto group = std::make_shared<FretDecayGroup>(n_exp, n_fret, true);
            group->setNumAcceptorExponential(n_acc);
            group->setUseStaticModel(false);


            group->setIncludeAcceptor(false);
            //validate(group);

            group->setIncludeAcceptor(true);
            validate(group);

            group->setUseStaticModel(false);
            validate(group);

            group->setIncludeDonorOnly(false);
            validate(group);
         }
   
   // Test anisotropy group
   for (int n_exp : {1, 2})
      for (int n_pol : {1, 2})
      {
         auto group = std::make_shared<AnisotropyDecayGroup>(n_exp, n_pol);
         validate(group);
      }


   // Test some basic combinations of FRET groups
   {
      std::vector<std::shared_ptr<AbstractDecayGroup>> groups;
      groups.push_back(std::make_shared<FretDecayGroup>(1, 1, true));
      groups.push_back(std::make_shared<FretDecayGroup>(1, 2, true));
      validate(groups);
   }

   {
      std::vector<std::shared_ptr<AbstractDecayGroup>> groups;
      groups.push_back(std::make_shared<FretDecayGroup>(2, 1, false));
      groups.push_back(std::make_shared<FretDecayGroup>(1, 1, false));
      validate(groups);
   }

   // Test combination of multiexponential groups
   {
      std::vector<std::shared_ptr<AbstractDecayGroup>> groups;
      groups.push_back(std::make_shared<MultiExponentialDecayGroup>(3, true));
      groups.push_back(std::make_shared<MultiExponentialDecayGroup>(2, true));
      validate(groups);
   }
   return 0;
}