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

#include <boost/serialization/type_info_implementation.hpp>
#include <boost/serialization/shared_ptr.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/base_object.hpp>

#include "DataTransformer.h"
#include "AbstractDecayGroup.h"
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"


#include <QObject>
#include <cmath>
#include <vector>

#include <memory>

class DecayModel
{

public:

   DecayModel();
   DecayModel(const DecayModel &obj);
   
   void addDecayGroup(std::shared_ptr<AbstractDecayGroup> group);
   std::shared_ptr<AbstractDecayGroup> getGroup(int idx) { return decay_groups[idx]; };
   int getNumGroups() { return static_cast<int>(decay_groups.size()); }

   void removeDecayGroup(int idx) { decay_groups.erase(decay_groups.begin() + idx); }

   void removeDecayGroup(std::shared_ptr<AbstractDecayGroup> group) 
   { 
      auto iter = std::find(decay_groups.begin(), decay_groups.end(), group); 
      if (iter != decay_groups.end())
         decay_groups.erase(iter, iter);
   }

   
   std::shared_ptr<TransformedDataParameters> getTransformedDataParameters() { return dp; }
   void setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp_);

   void setNumChannels(int n_chan);

   void init();

   void   setupIncMatrix(std::vector<int>& inc);
   int    calculateModel(std::vector<double>& a, int adim, std::vector<double>& kap, const std::vector<double>& alf, int irf_idx);
   int    calculateDerivatives(std::vector<double>& b, int bdim, std::vector<double>& kap, const std::vector<double>& alf, int irf_idx);
   void   getWeights(float* y, const std::vector<double>& a, const std::vector<double>& alf, float* lin_params, double* w, int irf_idx);
   float* getConstantAdjustment() { return adjust_buf.data(); };

   void getInitialVariables(std::vector<double>& variables, double mean_arrival_time);
   void getOutputParamNames(std::vector<std::string>& param_names, std::vector<int>& param_group, int& n_nl_output_params, int& n_lin_output_params);
   int getNonlinearOutputs(float* nonlin_variables, float* outputs);
   int getLinearOutputs(float* lin_variables, float* outputs);

   int getNumNonlinearVariables();
   int getNumColumns();
   int getNumDerivatives();

   void decayGroupUpdated();

   const std::vector<std::shared_ptr<FittingParameter>> getParameters() { return parameters; }

   void validateDerivatives();

   std::shared_ptr<FittingParameter> reference_parameter;
   std::shared_ptr<FittingParameter> t0_parameter;

protected:


   double getCurrentReferenceLifetime(const double* param_values, int& idx);

   int addReferenceLifetimeDerivatives(double* b, int bdim, double_iterator& kap_derv);
   int addT0Derivatives(double* b, int bdim, double_iterator& kap_derv);

   void setupAdjust();
   
   std::shared_ptr<TransformedDataParameters> dp;

   std::vector<std::shared_ptr<FittingParameter>> parameters;
   std::vector<std::shared_ptr<AbstractDecayGroup>> decay_groups;

   float photons_per_count;
   std::vector<std::vector<double>> channel_factor;
   std::vector<float> adjust_buf;

private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};


template<class Archive>
void DecayModel::serialize(Archive & ar, const unsigned int version)
{
   ar & dp;
   ar & reference_parameter;
   ar & t0_parameter;
   ar & decay_groups;
   ar & photons_per_count;
   ar & channel_factor;

   if (version >= 2)
      ar & parameters;
   else
      parameters = { t0_parameter }; // get rid of this later
}


BOOST_CLASS_VERSION(DecayModel, 2)

class QDecayModel : public QObject, public DecayModel
{
   Q_OBJECT

public:


   void addDecayGroup(std::shared_ptr<AbstractDecayGroup> group) 
   {
      connect(group.get(), &AbstractDecayGroup::parametersUpdated, this, &QDecayModel::parametersChanged);
      DecayModel::addDecayGroup(group);
      emit groupsUpdated();
   };
   
   std::shared_ptr<AbstractDecayGroup> getGroup(int idx) 
   {
      return decay_groups[idx];
   };
   
   void removeDecayGroup(int idx) { decay_groups.erase(decay_groups.begin() + idx); }

   void removeDecayGroup(std::shared_ptr<AbstractDecayGroup> group)
   {
      auto iter = std::find(decay_groups.begin(), decay_groups.end(), group);
      if (iter != decay_groups.end())
      {
         decay_groups.erase(iter);
         emit groupsUpdated();
      }
   }
   
   void parametersChanged()
   {
      emit groupsUpdated();
   }

signals:

   void groupsUpdated();

private:
   template<class Archive>
   void save(Archive & ar, const unsigned int version) const
   {
      ar & boost::serialization::base_object<DecayModel>(*this);
   }

   template<class Archive>
   void load(Archive & ar, const unsigned int version)
   {
      ar & boost::serialization::base_object<DecayModel>(*this);
      
      for (auto& group : decay_groups)
      {
         connect(group.get(), &AbstractDecayGroup::parametersUpdated, this, &QDecayModel::parametersChanged);
      }
   }
   
   friend class boost::serialization::access;
   BOOST_SERIALIZATION_SPLIT_MEMBER()
};
