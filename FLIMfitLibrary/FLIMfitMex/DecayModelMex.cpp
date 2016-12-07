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

#pragma warning(disable: 4244 4267)

#include "DecayModel.h"
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "AnisotropyDecayGroup.h"
#include "MexUtils.h"
#include "PointerMap.h"
#include <unordered_set>
#include "FittingParametersWidget.h"

std::unordered_set<std::shared_ptr<QDecayModel>> ptr_set;

int loaded = 0;

void addDecayGroup(shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsChar(prhs[2]));

   string group_type = GetStringFromMatlab(prhs[2]);

   shared_ptr<AbstractDecayGroup> group;

   if (group_type == "Multi-Exponential Decay")
   {
      AssertInputCondition(nrhs >= 4);
      int n_components = mxGetScalar(prhs[3]);
      group = std::make_shared<MultiExponentialDecayGroup>(n_components);
   }
   else if (group_type == "FRET Decay")
   {
      AssertInputCondition(nrhs >= 5);
      int n_components = mxGetScalar(prhs[3]);
      int n_fret = mxGetScalar(prhs[4]);
      group = std::make_shared<FretDecayGroup>(n_components, n_fret);

   }
   //else if (group_type == "Anisotropy Decay")
   //   group = std::make_shared<AnisotropyDecayGroup>();

   model->addDecayGroup(group);
}

void removeDecayGroup(shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   int group_idx = mxGetScalar(prhs[2]);
   model->removeDecayGroup(group_idx);
}

void getParameters(shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(nlhs >= 1);

   int group_idx = mxGetScalar(prhs[2]);

   auto group = model->getGroup(group_idx);
   auto& parameters = group->getParameters();

   const char* field_names[4] = { "Name", "InitialValue", "FittingType", "AllowedFittingTypes"};
   plhs[0] = mxCreateStructMatrix(1, parameters.size(), 4, field_names);

   for (int i = 0; i < parameters.size(); i++)
   { 
      mxSetFieldByNumber(plhs[0], i, 0, mxCreateString(parameters[i]->name.c_str()));
      mxSetFieldByNumber(plhs[0], i, 1, mxCreateDoubleScalar(parameters[i]->initial_value));
      mxSetFieldByNumber(plhs[0], i, 2, mxCreateDoubleScalar(parameters[i]->fitting_type));

      auto& allowed_types = parameters[i]->allowed_fitting_types;
      mxArray* a = mxCreateNumericMatrix(1, allowed_types.size(), mxDOUBLE_CLASS, mxREAL);
      double* ap = mxGetPr(a);
      for (int j = 0; j < allowed_types.size(); j++)
         ap[j] = allowed_types[j];
      mxSetFieldByNumber(plhs[0], i, 3, a);
   }
}

void setParameters(shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 4);
   AssertInputCondition(mxIsStruct(prhs[3]));

   int group_idx = mxGetScalar(prhs[2]);

   auto group = model->getGroup(group_idx);
   auto& parameters = group->getParameters();

   const char* field_names[4] = { "Name", "InitialValue", "FittingType", "AllowedFittingTypes" };
   plhs[0] = mxCreateStructMatrix(1, parameters.size(), 4, field_names);

   for (int i = 0; i < parameters.size(); i++)
   {
      parameters[i]->initial_value = mxGetScalar(mxGetField(prhs[3], i, "InitialValue"));
      ParameterFittingType type = static_cast<ParameterFittingType>((int) mxGetScalar(mxGetField(prhs[3], i, "FittingType")));

      int is_allowed = false;
      auto& allowed_types = parameters[i]->allowed_fitting_types;
      for (int j = 0; j < allowed_types.size(); j++)
         is_allowed |= (type == allowed_types[j]);
      
      if (is_allowed)
         parameters[i]->fitting_type = type;
   }
}

void openUI(shared_ptr<QDecayModel> model)
{
   
   auto widget = new FittingParametersWidget();
   widget->setDecayModel(model);
   widget->show();
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nrhs == 0 && nlhs > 0)
      {
         AssertInputCondition(nlhs > 0);
         auto model = std::make_shared<QDecayModel>();
         ptr_set.insert(model);
         plhs[0] = PackageSharedPtrForMatlab(model);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsScalar(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      // Get controller
      auto& model = GetSharedPtrFromMatlab<QDecayModel>(prhs[0]);

      if (ptr_set.find(model) == ptr_set.end())
         mexErrMsgIdAndTxt("FLIMfitMex:invalidImagePointer", "Invalid image pointer");

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "Clear")
         ptr_set.erase(model);
      else if (command == "AddDecayGroup")
         addDecayGroup(model, nlhs, plhs, nrhs, prhs);
      else if (command == "RemoveDecayGroup")
         removeDecayGroup(model, nlhs, plhs, nrhs, prhs);
      else if (command == "GetParameters")
         getParameters(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SetParameters")
         setParameters(model, nlhs, plhs, nrhs, prhs);
      else if (command == "OpenUI")
         openUI(model);
   }
   catch (std::exception e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}





