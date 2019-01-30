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

#include "FitSettings.h"
#include "FlagDefinitions.h"

#include <cstring>


FitSettings::FitSettings(FittingAlgorithm algorithm_, GlobalScope global_scope_, GlobalAlgorithm global_algorithm_, WeightingMode weighting_, int n_thread_, int runAsync_, int(*callback_)())
{
   algorithm = algorithm_;
   global_scope = global_scope_;
   global_algorithm = global_algorithm_;
   weighting = weighting_;

   n_thread = n_thread_;
   run_async = runAsync_;
   callback = callback_;

   calculate_errors = false;
   conf_interval = 0.05;

}

void FitSettings::setCalculateErrors(int calculate_errors_, double conf_interval_)
{
   calculate_errors = calculate_errors_;
   conf_interval = conf_interval_;
}
