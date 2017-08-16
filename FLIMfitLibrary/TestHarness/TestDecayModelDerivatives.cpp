
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

int testDerivatives()
{
   FLIMSimulationTCSPC sim;
   sim.setImageSize(10, 10);

   // Setup data
   std::shared_ptr<InstrumentResponseFunction> irf = sim.GenerateIRF(1e5);


   auto acq = std::make_shared<AcquisitionParameters>(sim);
   auto image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, FLIMImage::DataUint16);
 
   auto data_ptr = image->getDataPointer<uint16_t>();
   sim.GenerateImage(3000, 100, data_ptr);
   image->releaseModifiedPointer<uint16_t>();

   DataTransformationSettings transform(irf);
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

   model->validateDerivatives();

   return 0;
}