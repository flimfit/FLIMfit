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
#include "Aberration.h"

#include <vector>
#include <memory>
#include <cmath>

#include <QObject>

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

   DecayModel* clone() const { return new DecayModel(*this); }

   std::shared_ptr<TransformedDataParameters> getTransformedDataParameters() { return dp; }
   void setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp_);

   void setNumChannels(int n_chan);

   void init();

   void setupIncMatrix(std::vector<int>& inc);
   void setVariables(const std::vector<double>& alf);
   int calculateModel(double_iterator a, int adim, double_iterator kap, int irf_idx);
   int calculateDerivatives(double_iterator b, int bdim, const_double_iterator a, int adim, int n_col, double_iterator kap, int irf_idx);
   void getWeights(float_iterator y, float_iterator a, const std::vector<double>& alf, float_iterator lin_params, double_iterator w, int irf_idx);
   float_iterator getConstantAdjustment() { return adjust_buf.begin(); };

   void getInitialVariables(std::vector<double>& variables, double mean_arrival_time);
   void getOutputParamNames(std::vector<std::string>& param_names, std::vector<int>& param_group, int& n_nl_output_params, int& n_lin_output_params);
   int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator outputs);
   int getLinearOutputs(float_iterator lin_variables, float_iterator outputs);

   int getNumNonlinearVariables();
   int getNumColumns();
   int getNumDerivatives();

   bool isSpatiallyVariant();

   void decayGroupUpdated();

   void setUseSpectralCorrection(bool use_spectral_correction_);
   void setZernikeOrder(int zernike_order_);

   const std::vector<std::shared_ptr<FittingParameter>> getParameters() { return parameters; }
   const std::vector<std::shared_ptr<FittingParameter>> getAllParameters();


   void validateDerivatives();

   std::shared_ptr<FittingParameter> reference_parameter;
   std::shared_ptr<FittingParameter> t0_parameter;

protected:


   double getCurrentReferenceLifetime(const_double_iterator& param_values, int& idx);

   int addReferenceLifetimeDerivatives(double_iterator b, int bdim, double_iterator& kap_derv);
   int addT0Derivatives(double_iterator b, int bdim, double_iterator& kap_derv);

   void setupAdjust();
   void setupSpectralCorrection();

   std::shared_ptr<TransformedDataParameters> dp;

   std::vector<std::shared_ptr<FittingParameter>> parameters;
   std::vector<std::shared_ptr<AbstractDecayGroup>> decay_groups;

   float photons_per_count;
   std::vector<std::vector<double>> channel_factor;
   std::vector<float> adjust_buf;

   bool use_spectral_correction = false;
   int zernike_order = 1;

   int n_chan = 0; // for before transformed data parameters has been set

private:

   int n_derivatives = -1;
   std::vector<std::vector<double>> last_variables;

   double t0_shift;
   double reference_lifetime;

   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;

   std::vector<std::shared_ptr<Aberration>> spectral_correction;
   
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

   if (version >= 3)
   {
      ar & use_spectral_correction;
      ar & zernike_order;
   }
}


BOOST_CLASS_VERSION(DecayModel, 3)

class QDecayModel : public QObject, public DecayModel
{
   Q_OBJECT

public:

   Q_PROPERTY(bool use_spectral_correction MEMBER use_spectral_correction WRITE setUseSpectralCorrection USER true);
   Q_PROPERTY(int zernike_order MEMBER zernike_order WRITE setZernikeOrder USER true);

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
