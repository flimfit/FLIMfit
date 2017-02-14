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

#include "ExponentialPrecomputationBuffer.h"
#include "InstrumentResponseFunction.h"
#include "DataTransformer.h"
#include "IRFConvolution.h"
#include "FittingParameter.h"


class AbstractDecayGroup : public QObject
{
   Q_OBJECT

public:

   AbstractDecayGroup(const QString& name = "", QObject* parent = 0)
      : QObject(parent)
   {
      setObjectName(name);
   }



   virtual ~AbstractDecayGroup() {};
   vector<shared_ptr<FittingParameter>>& getParameters() { return parameters; }
   const vector<std::string>& getChannelFactorNames() { return channel_factor_names; }
   virtual const vector<double>& getChannelFactors(int index) = 0;
   virtual void setChannelFactors(int index, const vector<double>& channel_factors) = 0;

   int getNumComponents() { return n_lin_components; };
   int getNumNonlinearParameters() { return n_nl_parameters; };

   void setTransformedDataParameters(shared_ptr<TransformedDataParameters> dp);
   void setNumChannels(int n_chan);
   virtual void init() = 0;

   virtual int setVariables(const double* variables) = 0;
   virtual int calculateModel(double* a, int adim, vector<double>& kap) = 0;
   virtual int calculateDerivatives(double* b, int bdim, vector<double>& kap) = 0;
   virtual void addConstantContribution(float* a) {}

   virtual int setupIncMatrix(std::vector<int>& inc, int& row, int& col) = 0;
   virtual int getNonlinearOutputs(float* nonlin_variables, float* output, int& nonlin_idx) = 0;
   virtual int getLinearOutputs(float* lin_variables, float* output, int& lin_idx) = 0;

   virtual void getNonlinearOutputParamNames(vector<string>& names);
   virtual void getLinearOutputParamNames(vector<string>& names) = 0;

   int getInitialVariables(std::vector<double>::iterator& variables);
   void setIRFPosition(int irf_idx_, double t0_shift_, double reference_lifetime_);

   template <typename T>
   void addIRF(double* irf_buf, int irf_idx, double t0_shift, T a[], const vector<double>& channel_factor, double* scale_fact = NULL);

signals:
   void parametersUpdated();

protected:

   void parametersChanged() { emit parametersUpdated(); };
   virtual int getNumPotentialChannels() { return 1; }
   bool constrain_nonlinear_parameters = true;

   int n_lin_components = 0;
   int n_nl_parameters = 0;

   vector<std::shared_ptr<FittingParameter>> parameters;
   vector<std::string> channel_factor_names;

   std::shared_ptr<TransformedDataParameters> dp;
   bool fit_t0 = false;

   // RUNTIME VARIABLE PARAMETERS
   int irf_idx = 0;
   double t0_shift = 0;
   double reference_lifetime;
   vector<double> irf_buf;
   
private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
   
};

template<class Archive>
void AbstractDecayGroup::serialize(Archive & ar, const unsigned int version)
{
   ar & constrain_nonlinear_parameters;
   ar & n_lin_components;
   ar & n_nl_parameters;
   ar & parameters;
   ar & dp;
   ar & fit_t0;
};


BOOST_CLASS_TRACKING(AbstractDecayGroup, track_always)




// TODO: move this to InstrumentResponseFunction
template <typename T>
void AbstractDecayGroup::addIRF(double* irf_buf, int irf_idx, double t0_shift, T a[], const vector<double>& channel_factor, double* scale_fact)
{
   shared_ptr<InstrumentResponseFunction> irf = dp->irf;
   auto& t = dp->getTimepoints();
   
   double* lirf = irf->GetIRF(irf_idx, t0_shift, irf_buf);
   double t_irf0 = irf->GetT0();
   double dt_irf = irf->timebin_width;
   int n_irf = irf->n_irf;

   int idx = 0;
   int ii;
   for (int k = 0; k<dp->n_chan; k++)
   {
      double scale = (scale_fact == NULL) ? 1 : scale_fact[k];
      for (int i = 0; i<dp->n_t; i++)
      {
         ii = (int)floor((t[i] - t_irf0) / dt_irf);

         if (ii >= 0 && ii<n_irf)
            a[idx] += (T)(lirf[k*n_irf + ii] * channel_factor[k] * scale); // TODO
         idx++;
      }
   }
}
