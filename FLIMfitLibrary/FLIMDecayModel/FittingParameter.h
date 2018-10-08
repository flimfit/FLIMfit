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
#include <functional>

enum TransformType
{
   None,
   Inverse,
   Exponential
};

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

   FittingParameter(const std::string& name, double initial_value, double initial_min, double initial_max, double scale, const std::vector<ParameterFittingType>& allowed_fitting_types, ParameterFittingType fitting_type_, TransformType transform_type = None) :
      name(name),
      initial_value(initial_value),
      initial_min(initial_min),
      initial_max(initial_max),
      initial_search(true),
      scale(scale),
      allowed_fitting_types(allowed_fitting_types),
      transform_type(transform_type)
   {
      fitting_type = Fixed;
      setFittingType(fitting_type_);
      setupTransform();
   }

   FittingParameter(const std::string& name, double initial_value, double scale, const std::vector<ParameterFittingType>& allowed_fitting_types, ParameterFittingType fitting_type_, TransformType transform_type = None) :
      name(name),
      initial_value(initial_value),
      initial_min(0),
      initial_max(0),
      initial_search(false),
      scale(scale),
      allowed_fitting_types(allowed_fitting_types),
      transform_type(transform_type)
   {
      fitting_type = Fixed;
      setFittingType(fitting_type_);
      setupTransform();
   }

   bool isFixed() { return fitting_type == Fixed; }
   bool isFittedLocally() { return fitting_type == FittedLocally; }
   bool isFittedGlobally() { return (fitting_type == FittedGlobally) && !constrained; }
   bool isConstrained() { return constrained; }
   
   template<typename T, typename it>
   T getValue(it value, int& idx)
   {
      double v; 
      if (fitting_type == Fixed)
         return initial_value;
      if (fitting_type == FittedGlobally)
         v = static_cast<double>(value[idx++]);
      else
         throw std::runtime_error("No linear parameters provided");
      return static_cast<T>(reverse_transform(v));
   }

   template<typename T, typename it>
   T getTransformedValue(it value, int& idx)
   {
      if (fitting_type == FittedGlobally)
         return static_cast<T>(value[idx++]);
      else
         return forward_transform(initial_value);
   }

   template<typename T, typename it>
   T getValue(it value, int& idx, const double* lin_value, int& lin_idx)
   {
      double v;
      if (fitting_type == Fixed)
         return initial_value;
      if (fitting_type == FittedGlobally)
         v = static_cast<double>(value[idx++]);
      else if (fitting_type == FittedLocally && lin_value != nullptr)
         v = static_cast<double>(lin_value[lin_idx++]);
      return static_cast<T>(reverse_transform(v));
   }

   void setConstrained(bool constrained_ = true) { constrained = constrained_; }

   bool setFittingType(ParameterFittingType fitting_type_)
   {
      for (auto& allowed_type : allowed_fitting_types)
         if (fitting_type_ == allowed_type)
            fitting_type = fitting_type_;
      return fitting_type_ == fitting_type;
   }

   double getTransformedInitialValue() { return forward_transform(initial_value); }
   double getTransformedInitialMin() { return forward_transform(initial_min); }
   double getTransformedInitialMax() { return forward_transform(initial_max); }

   double getInitialValue() { return initial_value; }

   void setInitialValue(double initial_value_)
   {
      initial_value = initial_value_;
   }

   ParameterFittingType getFittingType() { return fitting_type; }

   std::string name;
   
   bool initial_search = false;
   double initial_min;
   double initial_max;

   double transformed_scale = 1;

   TransformType transform_type;
   std::function<double(double)> forward_transform;
   std::function<double(double)> reverse_transform;

   std::vector<ParameterFittingType> allowed_fitting_types;
   bool constrained = false;

private:

   double scale = 1;

   void setupTransform()
   {
      if (transform_type == None)
      {
         forward_transform = [](double x) { return x; };
         reverse_transform = forward_transform;
         transformed_scale = scale;
      }
      else if (transform_type == Inverse)
      {
         forward_transform = [](double x) { return 1 / x; };
         reverse_transform = forward_transform;
         transformed_scale = 1 / scale;
      }
      else if (transform_type == Exponential)
      {
         forward_transform = [](double x) { return exp(x); };
         reverse_transform = [](double x) { return log(x); };
         transformed_scale = scale;
      }
   }

   double initial_value;
   
   ParameterFittingType fitting_type;
   FittingParameter() {}
   
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
};

BOOST_CLASS_VERSION(FittingParameter, 4)

template<class Archive>
void FittingParameter::serialize(Archive & ar, const unsigned int version)
{
   ar & name;
   ar & initial_value;
   ar & allowed_fitting_types;
   ar & fitting_type;

   if (version >= 2)
   {
      ar & initial_search;
      ar & initial_min;
      ar & initial_max;
   }
   if (version >= 3)
   {
      ar & scale;
   }
   if (version >= 4)
      ar & transform_type;
   else
      transform_type = None;

   if (Archive::is_loading::value)
         setupTransform();
}
