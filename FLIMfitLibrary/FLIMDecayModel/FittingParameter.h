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

#pragma once

#include <string>
#include <vector>

enum ParameterFittingType
{
   Fixed,
   FittedLocally,
   FittedGlobally
};

class FittingParameter
{

public:

   const static char* fitting_type_names[];

   FittingParameter(const std::string& name, double initial_value, const std::vector<ParameterFittingType>& allowed_fitting_types, ParameterFittingType fitting_type) :
      name(name),
      initial_value(initial_value),
      allowed_fitting_types(allowed_fitting_types),
      fitting_type(fitting_type)
   {
   }

   bool IsFixed() { return fitting_type == Fixed; }
   bool IsFittedLocally() { return fitting_type == FittedLocally; }
   bool IsFittedGlobally() { return fitting_type == FittedGlobally; }
   
   template<typename T, typename U>
   T GetValue(const U* value, int& idx)
   {
      if (fitting_type == FittedGlobally)
         return static_cast<T>(value[idx++]);
      return static_cast<T>(initial_value);
   }

   template<typename T, typename U>
   T GetValue(const U* value, int& idx, const double* lin_value, int& lin_idx)
   {
      if (fitting_type == FittedGlobally)
         return static_cast<T>(value[idx++]);
      else if (fitting_type == FittedLocally && lin_value != nullptr)
         return static_cast<T>(lin_value[lin_idx++]);
      return static_cast<T>(initial_value);
   }


   std::string name;
   double initial_value;
   ParameterFittingType fitting_type;
   std::vector<ParameterFittingType> allowed_fitting_types;
};
