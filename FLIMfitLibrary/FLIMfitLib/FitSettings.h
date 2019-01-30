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

#include "FlagDefinitions.h"
#include "FLIMGlobalAnalysis.h"
#include <cstring>

class FitSettings
{
public:
   FitSettings(FittingAlgorithm algorithm = MaximumLikelihood, GlobalScope global_scope = Pixelwise, GlobalAlgorithm global_algorithm = GlobalAnalysis, WeightingMode weighting = AverageWeighting, int n_thread = 1, int runAsync = true, int(*callback)() = NULL);

   void setCalculateErrors(int calculate_errors, double conf_interval = 0.05);

   FittingAlgorithm algorithm;
   GlobalScope      global_scope;
   GlobalAlgorithm  global_algorithm;
   WeightingMode    weighting;

   int    calculate_errors;
   double conf_interval;

   int    n_thread;
   int    run_async;
   int(*callback)();


};