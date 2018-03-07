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

#include <memory>
#include <QObject>

#include "MeasuredIrfConvolver.h"
#include "InstrumentResponseFunction.h"
#include "DataTransformer.h"
#include "IRFConvolution.h"
#include "FittingParameter.h"

typedef std::vector<double>::iterator double_iterator;

class AbstractDecayGroup : public QObject
{
   Q_OBJECT

public:

   AbstractDecayGroup(const QString& name = "", QObject* parent = 0)
      : QObject(parent)
   {
      setObjectName(name);
   }

   AbstractDecayGroup(const AbstractDecayGroup& obj)
   {
      constrain_nonlinear_parameters = obj.constrain_nonlinear_parameters;
      channel_factor_names = obj.channel_factor_names;
      dp = obj.dp;
   };

   virtual AbstractDecayGroup* clone() const = 0;

   virtual ~AbstractDecayGroup() {};
   
   std::shared_ptr<FittingParameter> getParameter(const std::string& param);
   std::vector<std::shared_ptr<FittingParameter>>& getParameters() { return parameters; }
   const std::vector<std::string>& getChannelFactorNames() { return channel_factor_names; }

   int getNumComponents() { return n_lin_components; };
   int getNumNonlinearParameters() { return n_nl_parameters; };

   void setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp);
   void setNumChannels(int n_chan);

   virtual void init() = 0;

   virtual int setVariables(const double* variables) = 0;
   virtual int calculateModel(double* a, int adim, double& kap, int bin_shift = 0) = 0;
   virtual int calculateDerivatives(double* b, int bdim, double_iterator& kap_derv) = 0;
   virtual void addConstantContribution(float* a) {}

   virtual void setupIncMatrix(std::vector<int>& inc, int& row, int& col) = 0;
   virtual int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx) = 0;
   virtual int getLinearOutputs(float* lin_variables, float* output, int& lin_idx) = 0;

   virtual std::vector<std::string> getNonlinearOutputParamNames();
   virtual std::vector<std::string> getLinearOutputParamNames() = 0;

   virtual const std::vector<double>& getChannelFactors(int index) = 0;
   virtual void setChannelFactors(int index, const std::vector<double>& channel_factors) = 0;

   int getInitialVariables(std::vector<double>::iterator variables);
   void setIRFPosition(int irf_idx_, double t0_shift_, double reference_lifetime_);

   template <typename T>
   void addIRF(double* irf_buf, int irf_idx, double t0_shift, T a[], const std::vector<double>& channel_factor, double factor = 1);

signals:
   void parametersUpdated();

protected:

   void parametersChanged() { emit parametersUpdated(); };
   virtual int getNumPotentialChannels() { return 1; }
   
   void validateChannelFactors();

   bool constrain_nonlinear_parameters = true;

   std::vector<std::shared_ptr<FittingParameter>> parameters;
   std::vector<std::string> channel_factor_names;

   std::shared_ptr<TransformedDataParameters> dp;

   int n_lin_components = 0;
   int n_nl_parameters = 0;

   // RUNTIME VARIABLE PARAMETERS
   int irf_idx = 0;
   double t0_shift = 0;
   double reference_lifetime;
   std::vector<double> irf_buf;
   
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

template <typename T>
void AbstractDecayGroup::addIRF(double* irf_buf, int irf_idx, double t0_shift, T a[], const std::vector<double>& channel_factor, double factor)
{
   std::shared_ptr<InstrumentResponseFunction> irf = dp->irf;
   auto& t = dp->getTimepoints();
   
   double* lirf = irf->getIRF(irf_idx, t0_shift, irf_buf);
   double t_irf0 = irf->getT0();
   double dt_irf = irf->timebin_width;
   int n_irf = irf->n_irf;

   int idx = 0;
   int ii;
   for (int k = 0; k<dp->n_chan; k++)
   {
      for (int i = 0; i<dp->n_t; i++)
      {
         ii = (int)floor((t[i] - t_irf0) / dt_irf);

         if (ii >= 0 && ii<n_irf)
            a[idx] += (T)(lirf[k*n_irf + ii] * channel_factor[k] * factor);
         idx++;
      }
   }
}
