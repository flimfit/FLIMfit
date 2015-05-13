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

#include "DataTransformer.h"
#include "AbstractDecayGroup.h"

#include <QObject>
#include <cmath>
#include <vector>

#include <memory>

using std::shared_ptr;
using std::unique_ptr;

using std::string;
using std::vector;

class DecayModel
{

public:

   DecayModel();
   //DecayModel(const DecayModel &obj);
   
   void AddDecayGroup(shared_ptr<AbstractDecayGroup> group);
   shared_ptr<AbstractDecayGroup> GetGroup(int idx) { return decay_groups[idx]; };
   int GetNumGroups() { return static_cast<int>(decay_groups.size()); }

   void RemoveDecayGroup(int idx) { decay_groups.erase(decay_groups.begin() + idx); }

   void RemoveDecayGroup(shared_ptr<AbstractDecayGroup> group) 
   { 
      auto iter = std::find(decay_groups.begin(), decay_groups.end(), group); 
      if (iter != decay_groups.end())
         decay_groups.erase(iter, iter);
   }


   shared_ptr<TransformedDataParameters> GetTransformedDataParameters() { return dp; }
   void SetTransformedDataParameters(shared_ptr<TransformedDataParameters> dp_);

   void Init();

   void   SetupIncMatrix(int* inc);
   int    CalculateModel(vector<double>& a, int adim, vector<double>& b, int bdim, vector<double>& kap, const vector<double>& alf, int irf_idx, int isel);
   void   GetWeights(float* y, const vector<double>& a, const vector<double>& alf, float* lin_params, double* w, int irf_idx);
   float* GetConstantAdjustment() { return adjust_buf.data(); };

   void GetInitialVariables(vector<double>& variables, double mean_arrival_time);
   void GetOutputParamNames(vector<string>& param_names, int& n_nl_output_params);
   int GetNonlinearOutputs(float* nonlin_variables, float* outputs);
   int GetLinearOutputs(float* lin_variables, float* outputs);

   int GetNumNonlinearVariables();
   int GetNumColumns();
   int GetNumDerivatives();

   void DecayGroupUpdated();

protected:

   void ValidateDerivatives();

   double GetCurrentReferenceLifetime(const double* param_values, int& idx);
   double GetCurrentT0(const double* param_values, int& idx);

   int AddReferenceLifetimeDerivatives(double* b, int bdim, vector<double>& kap);
   int AddT0Derivatives(double* b, int bdim, vector<double>& kap);

   void SetupAdjust();
   
   shared_ptr<TransformedDataParameters> dp;

   FittingParameter reference_parameter;
   FittingParameter t0_parameter;

   vector<shared_ptr<AbstractDecayGroup>> decay_groups;

   float photons_per_count;
   vector<vector<double>> channel_factor; // TODO!
   vector<float> adjust_buf;
};

class QDecayModel : public QObject, public DecayModel
{
   Q_OBJECT

public:


   void AddDecayGroup(shared_ptr<QAbstractDecayGroup> group) 
   {
      connect(group.get(), &QAbstractDecayGroup::parametersUpdated, this, &QDecayModel::parametersChanged);
      DecayModel::AddDecayGroup(group);
      emit GroupsUpdated();
   };
   
   shared_ptr<QAbstractDecayGroup> GetGroup(int idx) 
   {
      return std::dynamic_pointer_cast<QAbstractDecayGroup>(decay_groups[idx]);
   };
   
   void RemoveDecayGroup(shared_ptr<QAbstractDecayGroup> group)
   {
      auto iter = std::find(decay_groups.begin(), decay_groups.end(), group);
      if (iter != decay_groups.end())
      {
         decay_groups.erase(iter, iter);
         emit GroupsUpdated();
      }
   }
   
   void parametersChanged()
   {
      emit GroupsUpdated();
   }

signals:

   void GroupsUpdated();

};