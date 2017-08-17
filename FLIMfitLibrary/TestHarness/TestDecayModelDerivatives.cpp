
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

void validate(std::shared_ptr<AbstractDecayGroup> g)
{

   std::cout << "\nTesting derivatives for " << g->objectName().toStdString() << "\n================\n\n";
   

   FLIMSimulationTCSPC sim;
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);
   auto acq = std::make_shared<AcquisitionParameters>(sim);
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);

   DataTransformationSettings transform(irf);
   auto data = std::make_shared<FLIMData>(image, transform);

   auto model = std::make_shared<DecayModel>();
   model->setTransformedDataParameters(data->GetTransformedDataParameters());

   model->addDecayGroup(g);


   model->init();
   model->validateDerivatives();
}

int testModelDerivatives()
{
   // Add a FRET group
   {
      auto group = std::make_shared<FretDecayGroup>(2, 2, false);
      auto params = group->getParameters();
      for (int i = 0; i < params.size(); i++)
         params[i]->fitting_type = ParameterFittingType::FittedGlobally;
      validate(group);
   }

   // Add a multiexponential group
   {
      auto group = std::make_shared<MultiExponentialDecayGroup>(3);
      auto params = group->getParameters();
      for (int i = 0; i < params.size(); i++)
         params[i]->fitting_type = ParameterFittingType::FittedGlobally;
      validate(group);

      // with global beta
      group->setContributionsGlobal(true);
      params = group->getParameters();
      for (int i = 0; i < params.size(); i++)
         params[i]->fitting_type = ParameterFittingType::FittedGlobally;
      validate(group);
   }



   return 0;
}