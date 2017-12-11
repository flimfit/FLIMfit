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

#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/serialization/export.hpp>

#include "DecayModel.h"
#include "BackgroundLightDecayGroup.h"
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "AnisotropyDecayGroup.h"
#include "PatternDecayGroup.h"
#include "MexUtils.h"
#include "PointerMap.h"
#include <unordered_set>

#include <QMetaProperty>

std::unordered_set<std::shared_ptr<QDecayModel>> ptr_set;

int loaded = 0;

void addDecayGroup(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsChar(prhs[2]));

   std::string group_type = getStringFromMatlab(prhs[2]);

   std::shared_ptr<AbstractDecayGroup> group;

   if (group_type == "Multi-Exponential Decay")
   {
      int n_components = (nrhs >= 4) ? mxGetScalar(prhs[3]) : 1;
      group = std::make_shared<MultiExponentialDecayGroup>(n_components);
   }
   else if (group_type == "FRET Decay")
   {
      int n_components = (nrhs >= 4) ? mxGetScalar(prhs[3]) : 1;
      int n_fret = (nrhs >= 5) ? mxGetScalar(prhs[4]) : 1;
      group = std::make_shared<FretDecayGroup>(n_components, n_fret);
   }
   else if (group_type == "Anisotropy Decay")
   {
      int n_components = (nrhs >= 4) ? mxGetScalar(prhs[3]) : 1;
      int n_anisotropy = (nrhs >= 5) ? mxGetScalar(prhs[4]) : 1;
      bool inc_r_inf = (nrhs >= 6) ? mxGetScalar(prhs[5]) : false;
      group = std::make_shared<AnisotropyDecayGroup>(n_components, n_anisotropy, inc_r_inf);
   }
   else if (group_type == "Pattern")
   {
      AssertInputCondition(nrhs >= 5);
      AssertInputCondition(mxIsCell(prhs[3]));

      std::vector<Pattern> patterns;
      int n_chan = mxGetNumberOfElements(prhs[3]);
      for (int i = 0; i < n_chan; i++)
      {
         mxArray* el = mxGetCell(prhs[3], i);
         std::vector<double> params = getVector<double>(el);
         patterns.push_back(Pattern(params));
      }     

      std::string name = getStringFromMatlab(prhs[4]);
      group = std::make_shared<PatternDecayGroup>(patterns,QString::fromStdString(name));
   }
   else if (group_type == "Background Light")
   {
      group = std::make_shared<BackgroundLightDecayGroup>();
   }

   if (group)
      model->addDecayGroup(group);
   else
      mexWarnMsgTxt("Unrecognised decay group type");
}

void removeDecayGroup(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   int group_idx = mxGetScalar(prhs[2])-1;
   AssertInputCondition(group_idx >= 0 && group_idx < model->getNumGroups());

   model->removeDecayGroup(group_idx);
}

mxArray* getVariables(const std::vector<std::shared_ptr<FittingParameter>> parameters)
{
   const char* field_names[] = { "Name", "InitialValue", "FittingType", "AllowedFittingTypes", "id"};
   mxArray* s = mxCreateStructMatrix(1, parameters.size(), 5, field_names);

   for (int i = 0; i < parameters.size(); i++)
   { 
      mxSetFieldByNumber(s, i, 0, mxCreateString(parameters[i]->name.c_str()));
      mxSetFieldByNumber(s, i, 1, mxCreateDoubleScalar(parameters[i]->initial_value));
      mxSetFieldByNumber(s, i, 2, mxCreateDoubleScalar(parameters[i]->getFittingType() + 1));

      auto& allowed_types = parameters[i]->allowed_fitting_types;
      mxArray* a = mxCreateNumericMatrix(1, allowed_types.size(), mxDOUBLE_CLASS, mxREAL);
      double* ap = mxGetPr(a);
      for (int j = 0; j < allowed_types.size(); j++)
         ap[j] = allowed_types[j] + 1;
      mxSetFieldByNumber(s, i, 3, a);
      mxSetFieldByNumber(s, i, 4, mxCreateUint64Scalar((uint64_t) parameters[i].get()));
   }

   return s;
}

mxArray* getParameters(std::shared_ptr<QDecayModel> model, int group_idx)
{
   AssertInputCondition(group_idx < model->getNumGroups());
   auto group = model->getGroup(group_idx);

   const QMetaObject* group_meta = group->metaObject();
   int n_properties = group_meta->propertyCount() - 1; // ignore objectName

   std::vector<const char*> field_names(n_properties);
   int n_user_properties = 0;
   for (int i = 0; i < n_properties; i++)
   {
      const auto& prop = group_meta->property(i + 1);
      if (prop.isUser())
         field_names[n_user_properties++] = prop.name();
   }

   mxArray* s = mxCreateStructMatrix(1, 1, n_user_properties, field_names.data());

   int idx = 0;
   for (int i = 0; i < n_properties; i++)
   {
      const auto& prop = group_meta->property(i + 1);
      
      if (prop.isUser())
      {

         QVariant v = prop.read(group.get());

         mxArray* vv;
         QByteArray vs;
         switch (v.type())
         {
         case QMetaType::Bool:
            mxSetFieldByNumber(s, 0, idx, mxCreateLogicalScalar(v.toDouble()));
            break;
         case QMetaType::Int:
         case QMetaType::UInt:
         case QMetaType::Long:
            vv = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
            static_cast<int64_t*>(mxGetData(vv))[0] = v.toInt();
            mxSetFieldByNumber(s, 0, idx, vv);
            break;
         case QMetaType::Char:
         case QMetaType::QString:
            vs = v.toString().toLocal8Bit();
            vv = mxCreateStringFromNChars(vs.constData(), vs.length());
            mxSetFieldByNumber(s, 0, idx, vv);
            break;
         default:
            mxSetFieldByNumber(s, 0, idx, mxCreateDoubleScalar(0));
         }

         idx++;
      }
   }

   return s;
}

void setParameter(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 5);

   int group_idx = mxGetScalar(prhs[2])-1;
   AssertInputCondition((group_idx < model->getNumGroups()) && (group_idx >= 0));

   auto group = model->getGroup(group_idx);

   std::string name = getStringFromMatlab(prhs[3]);
   double value = mxGetScalar(prhs[4]);

   group->setProperty(name.c_str(), value);
}

void setVariables(std::shared_ptr<QDecayModel> model, std::vector<std::shared_ptr<FittingParameter>> parameters, const mxArray* new_parameters)
{
   for (int i = 0; i < parameters.size(); i++)
   {
      parameters[i]->initial_value = mxGetScalar(mxGetField(new_parameters, i, "InitialValue"));
      ParameterFittingType type = static_cast<ParameterFittingType>((int)mxGetScalar(mxGetField(new_parameters, i, "FittingType")) - 1);
      parameters[i]->setFittingType(type);
   }
}

void getModelVariables(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);

   auto& parameters = model->getParameters();
   plhs[0] = getVariables(parameters);
}

void setModelVariables(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsStruct(prhs[3]));

   auto& parameters = model->getParameters();

   setVariables(model, parameters, prhs[3]);
}

mxArray* getGroupVariables(std::shared_ptr<QDecayModel> model, int group_idx)
{
   AssertInputCondition(group_idx < model->getNumGroups());
   auto group = model->getGroup(group_idx);
   auto& parameters = group->getParameters();

   return getVariables(parameters);
}

void setGroupVariables(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 4);
   AssertInputCondition(mxIsStruct(prhs[3]));

   int group_idx = mxGetScalar(prhs[2]) - 1;
   AssertInputCondition(group_idx < model->getNumGroups());

   auto group = model->getGroup(group_idx);
   auto& parameters = group->getParameters();

   setVariables(model, parameters, prhs[3]);
}


void getGroups(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);

   int n_group = model->getNumGroups();
   const char* field_names[] = { "Name", "Parameters", "Variables", "id" };
   plhs[0] = mxCreateStructMatrix(1, n_group, 4, field_names);

   for (int i = 0; i < n_group; i++)
   {
      auto group = model->getGroup(i);

      group->objectName();

      mxSetFieldByNumber(plhs[0], i, 0, mxCreateString(group->objectName().toLocal8Bit()));
      mxSetFieldByNumber(plhs[0], i, 1, getParameters(model, i));
      mxSetFieldByNumber(plhs[0], i, 2, getGroupVariables(model, i));
      mxSetFieldByNumber(plhs[0], i, 3, mxCreateUint64Scalar((uint64_t) group.get()));
   }
}

void getChannelFactorNames(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);
   AssertInputCondition(nrhs >= 3);

   int group_idx = mxGetScalar(prhs[2]) - 1;
   AssertInputCondition(group_idx < model->getNumGroups());

   auto group = model->getGroup(group_idx);
   auto names = group->getChannelFactorNames();

   plhs[0] = mxCreateCellMatrix(1, names.size());

   for (int i = 0; i < names.size(); i++)
      mxSetCell(plhs[0], i, mxCreateString(names[i].c_str()));
}

void getChannelFactors(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);
   AssertInputCondition(nrhs >= 4);

   int group_idx = mxGetScalar(prhs[2]) - 1;
   AssertInputCondition(group_idx < model->getNumGroups());

   int channel_idx = mxGetScalar(prhs[3]) - 1;

   auto group = model->getGroup(group_idx);
   auto channel_factors = group->getChannelFactors(channel_idx);

   plhs[0] = mxCreateDoubleMatrix(1, channel_factors.size(), mxREAL);
   double* ch_ptr = reinterpret_cast<double*>(mxGetData(plhs[0]));

   std::copy(channel_factors.begin(), channel_factors.end(), ch_ptr);
}


void setChannelFactors(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 5);

   int group_idx = mxGetScalar(prhs[2]) - 1;
   AssertInputCondition(group_idx < model->getNumGroups());

   int channel_idx = mxGetScalar(prhs[3]) - 1;
   auto channel_factors = getVector<double>(prhs[4]);

   auto group = model->getGroup(group_idx);
   group->setChannelFactors(channel_idx, channel_factors);
}


void setNumChannels(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   int n_chan = mxGetScalar(prhs[2]);
   AssertInputCondition(n_chan > 0);

   model->setNumChannels(n_chan);
}

void saveModel(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsChar(prhs[2]));

   std::string filename = getStringFromMatlab(prhs[2]);

   std::ofstream ofs(filename);
   boost::archive::text_oarchive oa(ofs);
  
   oa << *(model.get());
}

void loadModel(std::shared_ptr<QDecayModel> model, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsChar(prhs[2]));

   std::string filename = getStringFromMatlab(prhs[2]);

   std::ifstream ifs(filename);
   boost::archive::text_iarchive ia(ifs);

   ia >> *(model.get());
}


BOOST_CLASS_EXPORT_GUID(BackgroundLightDecayGroup, "BackgroundLightDecayGroup");
BOOST_CLASS_EXPORT_GUID(AnisotropyDecayGroup, "AnisotropyDecayGroup");
BOOST_CLASS_EXPORT_GUID(MultiExponentialDecayGroup, "MultiExponentialDecayGroup");
BOOST_CLASS_EXPORT_GUID(FretDecayGroup, "FretDecayGroup");
BOOST_CLASS_EXPORT_GUID(PatternDecayGroup, "PatternDecayGroup");

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nrhs == 0 && nlhs > 0)
      {
         AssertInputCondition(nlhs > 0);
         auto model = std::make_shared<QDecayModel>();
         ptr_set.insert(model);
         plhs[0] = packageSharedPtrForMatlab(model);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsScalar(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      // Get controller
      const auto& model = getSharedPtrFromMatlab<QDecayModel>(prhs[0]);

      if (ptr_set.find(model) == ptr_set.end())
         mexErrMsgIdAndTxt("FLIMfitMex:invalidImagePointer", "Invalid image pointer");

      // Get command
      std::string command = getStringFromMatlab(prhs[1]);

      if (command == "Release")
      {
         ptr_set.erase(model);
         releaseSharedPtrFromMatlab<QDecayModel>(prhs[0]);
      }
      else if (command == "GetModelVariables")
         getModelVariables(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SetModelVariables")
         setModelVariables(model, nlhs, plhs, nrhs, prhs);
      else if (command == "AddDecayGroup")
         addDecayGroup(model, nlhs, plhs, nrhs, prhs);
      else if (command == "RemoveDecayGroup")
         removeDecayGroup(model, nlhs, plhs, nrhs, prhs);
      else if (command == "GetGroups")
         getGroups(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SetGroupVariables")
         setGroupVariables(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SetGroupParameter")
         setParameter(model, nlhs, plhs, nrhs, prhs);
      else if (command == "GetChannelFactorNames")
         getChannelFactorNames(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SetChannelFactors")
         setChannelFactors(model, nlhs, plhs, nrhs, prhs);
      else if (command == "GetChannelFactors")
         getChannelFactors(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SetNumChannels")
         setNumChannels(model, nlhs, plhs, nrhs, prhs);
      else if (command == "SaveModel")
         saveModel(model, nlhs, plhs, nrhs, prhs);
      else if (command == "LoadModel")
         loadModel(model, nlhs, plhs, nrhs, prhs);
   }
   catch (std::runtime_error e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}





