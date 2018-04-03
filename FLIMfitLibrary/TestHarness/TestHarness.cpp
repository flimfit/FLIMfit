
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


#include "Cout2VisualStudioDebugOutput.h"

#include "FLIMSimulation.h"
#include <iostream>
#include <string>
#include <cmath>
#include "FitController.h"
#include "MultiExponentialDecayGroup.h"
#include "BackgroundLightDecayGroup.h"
#include "FLIMImage.h"
#include "PatternDecayGroup.h"

extern int testFittingCoreDouble();
extern void testDecayResampler();
extern int testFittingCoreSingle(double tau, int N, bool use_gaussian_irf);
extern int testModelDerivatives();
extern int testFittingCoreMultiChannel();

#define CATCH_CONFIG_MAIN
#include "catch.hpp"


TEST_CASE("Gaussian IRF", "[irf]")
{
   FLIMSimulationTCSPC sim;
   sim.GenerateIRF(10000);

   auto params = sim.getIrfParameters();

   auto irf_normal = sim.GenerateIRF(10000);

   auto irf_gaussian = std::make_shared<InstrumentResponseFunction>();
   irf_gaussian->setGaussianIRF({params});

}

TEST_CASE("Model derivatives", "[model]") 
{
   testModelDerivatives();
}

TEST_CASE("Single fit", "[fitting]") 
{
   for (int N_ : {100, 200, 2000, 5000, 10000})
      testFittingCoreSingle(1000, N_, true);
   for (int N_ : {100, 200, 2000, 5000, 10000})
      testFittingCoreSingle(4000, N_, true);
}

TEST_CASE("Double fit", "[fitting]")
{
   testFittingCoreDouble();
}

TEST_CASE("Multichannel fit", "[fitting2]")
{
   testFittingCoreMultiChannel();
}

TEST_CASE("FRET", "[fret]")
{
   auto group = std::make_shared<FretDecayGroup>(1, 1, false);
   group->setIncludeAcceptor(true);
   //validate(group);

}


int main0()
{

   std::vector<double> test = { 1500, 2000 };

   auto group = std::make_shared<MultiExponentialDecayGroup>((int)test.size());


   std::vector<Pattern> patterns(1, Pattern({ 1500, 0.5, 2000, 0.5, 0 }));

   //auto pgroup = std::make_shared<PatternDecayGroup>(patterns);
   //model->addDecayGroup(pgroup);

   
   
   auto params = group->getParameters();
   for (int i=0; i<params.size(); i++)
   {
      params[i]->setFittingType(FittedGlobally);
      params[i]->initial_value = test[i];
//      std::cout << params[i]->name << " " << params[i]->fitting_type << "\n";
   }
   

   //auto bg_group = std::make_shared<BackgroundLightDecayGroup>();
   //model->addDecayGroup(bg_group);
   //bg_group->getParameter("offset")->fitting_type = FittedLocally;
   //bg_group->getParameter("scatter")->fitting_type = FittedLocally;
   //bg_group->getParameter("tvb")->fitting_type = FittedLocally;

   return 0;
}