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
#pragma warning(disable: 4250) // inherits ... via dominance

#include <boost/serialization/type_info_implementation.hpp>
#include <boost/serialization/shared_ptr.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/base_object.hpp>

#include <vector>
#include <memory>
#include <QObject>
#include <dlib/matrix.h>

#include "PixelIndex.h"
#include "AlignedVectors.h"
#include "DataTransformer.h"

class FittingParameter;
class TransformedDataParmeters;

#define INC_ENTRIES     256
#define MAX_VARIABLES   32
#define MAX_COLUMNS     32

typedef dlib::matrix<int, MAX_VARIABLES, MAX_COLUMNS> inc_matrix;


typedef std::vector<float>::iterator float_iterator;

class AbstractDecayGroup : public QObject
{
   Q_OBJECT

public:

   AbstractDecayGroup(const QString& name = "", QObject* parent = 0);
   AbstractDecayGroup(const AbstractDecayGroup& obj);

   virtual AbstractDecayGroup* clone() const = 0;

   virtual ~AbstractDecayGroup() {};

   std::shared_ptr<FittingParameter> getParameter(const std::string& param);
   std::vector<std::shared_ptr<FittingParameter>>& getParameters() { return parameters; }
   const std::vector<std::string>& getChannelFactorNames() { return channel_factor_names; }

   int getNumComponents() { return n_lin_components; };
   int getNumNonlinearParameters() { return n_nl_parameters; };

   void setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp);
   virtual void setNumChannels(int n_chan);

   void init();
   int setVariables(std::vector<double>::const_iterator variables);
   void precompute();

   virtual int calculateModel(double_iterator a, int adim, double& kap) = 0;
   virtual int calculateDerivatives(double_iterator b, int bdim, double_iterator& kap_derv) = 0;
   virtual void addConstantContribution(float_iterator a) {}
   virtual void addUnscaledContribution(double_iterator a) {}

   virtual void setupIncMatrix(inc_matrix& inc, int& row, int& col) = 0;
   virtual int getNonlinearOutputs(float_iterator nonlin_variables, float_iterator output, int& nonlin_idx) = 0;
   virtual int getLinearOutputs(float_iterator lin_variables, float_iterator output, int& lin_idx) = 0;

   virtual std::vector<std::string> getNonlinearOutputParamNames();
   virtual std::vector<std::string> getLinearOutputParamNames() = 0;

   virtual const std::vector<double>& getChannelFactors(int index) = 0;
   virtual void setChannelFactors(int index, const std::vector<double>& channel_factors) = 0;

   int getInitialVariables(std::vector<double>::iterator variables);

   void setIRFPosition(PixelIndex irf_idx_);
   void setT0Shift(double t0_shift_);
   void setReferenceLifetime(double reference_lifetime_);

signals:
   void parametersUpdated();

protected:

   void parametersChanged() { emit parametersUpdated(); };
   virtual int getNumPotentialChannels() { return 1; }

   virtual void init_() = 0;
   virtual void precompute_() = 0;
   virtual int setVariables_(std::vector<double>::const_iterator variables) = 0;

   void normaliseChannelFactors(const std::vector<double>& channel_factors, std::vector<double>& norm_channel_factors);

   bool constrain_nonlinear_parameters = true;

   std::vector<std::shared_ptr<FittingParameter>> parameters;
   std::vector<std::string> channel_factor_names;

   std::shared_ptr<TransformedDataParameters> dp;

   int n_lin_components = 0;
   int n_nl_parameters = 0;

   // RUNTIME VARIABLE PARAMETERS
   PixelIndex irf_idx = 0;
   double t0_shift = 0;
   double reference_lifetime;
   aligned_vector<double> irf_buf;
   std::vector<double> last_parameters;
   bool precompute_valid = false;

private:
   template<class Archive>
   void load(Archive & ar, const unsigned int version);

   template<class Archive>
   void save(Archive & ar, const unsigned int version) const;

   friend class boost::serialization::access;
   BOOST_SERIALIZATION_SPLIT_MEMBER()
};

template<class Archive>
void AbstractDecayGroup::load(Archive & ar, const unsigned int version)
{
   ar & constrain_nonlinear_parameters;
   ar & n_lin_components;
   ar & n_nl_parameters;
   ar & parameters;
   ar & dp;

   if (version >= 2)
   {
      std::string name;
      ar >> name;
      setObjectName(QString::fromStdString(name));
   }
};

template<class Archive>
void AbstractDecayGroup::save(Archive & ar, const unsigned int version) const
{
   ar & constrain_nonlinear_parameters;
   ar & n_lin_components;
   ar & n_nl_parameters;
   ar & parameters;
   ar & dp;

   if (version >= 2)
      ar & objectName().toStdString();
};


BOOST_CLASS_TRACKING(AbstractDecayGroup, track_always)
BOOST_CLASS_VERSION(AbstractDecayGroup, 2)
