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

#include "FitStatus.h"
#include "InstrumentResponseFunction.h"
#include "ModelADA.h" 
#include "FLIMGlobalAnalysis.h"
#include "FLIMData.h"
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <unordered_set>
#include "MexUtils.h"

#ifdef _WINDOWS
#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif
#endif

std::unordered_set<std::shared_ptr<FLIMData>> ptr_set;

DataTransformationSettings getDataTransformationSettings(const mxArray* settings_struct)
{
   AssertInputCondition(mxIsStruct(settings_struct));

   DataTransformationSettings settings;

   settings.smoothing_factor = getValueFromStruct(settings_struct, "smoothing_factor");
   settings.t_start = getValueFromStruct(settings_struct, "t_start");
   settings.t_stop = getValueFromStruct(settings_struct, "t_stop");
   settings.threshold = getValueFromStruct(settings_struct, "threshold");
   settings.limit = getValueFromStruct(settings_struct, "limit");

   return settings;
}

std::shared_ptr<InstrumentResponseFunction> getIRF(const mxArray* irf_struct)
{
   AssertInputCondition(mxIsStruct(irf_struct));
   
   auto irf = std::make_shared<InstrumentResponseFunction>();

   double timebin_t0 = getValueFromStruct(irf_struct, "timebin_t0");
   double timebin_width = getValueFromStruct(irf_struct, "timebin_width");

   const mxArray* irf_ = getFieldFromStruct(irf_struct, "irf");
   AssertInputCondition(mxIsDouble(irf_) && mxGetNumberOfDimensions(irf_) == 2);

   int n_t = mxGetM(irf_);
   int n_chan = mxGetN(irf_);
   double* irf_data = static_cast<double*>(mxGetData(irf_));

   if (mxGetNumberOfDimensions(irf_) > 2)
   {
      int n_rep = mxGetNumberOfElements(irf_) / (n_t * n_chan);
      //irf->SetImageIRF(n_t, n_chan, n_rep, timebin_t0, timebin_width, irf_data); TODO
   }
   else
   {
      irf->setIRF(n_t, n_chan, timebin_t0, timebin_width, irf_data);
   }

   bool ref_reconvolution = (bool) getValueFromStruct(irf_struct, "ref_reconvolution", false);
   double ref_lifetime_guess = getValueFromStruct(irf_struct, "ref_lifetime_guess", 80.0);
   
   irf->setReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   // TODO: irf.SetIRFShiftMap()

   return irf;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nlhs > 0 && nrhs > 0 && !mxIsScalar(prhs[0]))
      {
         const mxArray* image_ptrs = getNamedArgument(nrhs, prhs, "images");
         auto images = getSharedPtrVectorFromMatlab<FLIMImage>(image_ptrs);

         const mxArray* settings_struct = getNamedArgument(nrhs, prhs, "data_transformation_settings");
         auto transformation_settings = getDataTransformationSettings(settings_struct);

         if (isArgument(nrhs, prhs, "irf"))
         {
            const mxArray* irf_struct = getNamedArgument(nrhs, prhs, "irf");
            transformation_settings.irf = getIRF(irf_struct);
         }

         double background_value = 0.0;

         if (isArgument(nrhs, prhs, "background_value"))
         {
            const mxArray* background_value_ = getNamedArgument(nrhs, prhs, "background_value");
            AssertInputCondition(mxIsScalar(background_value_));
            background_value = mxGetScalar(background_value_);
         }

         if (isArgument(nrhs, prhs, "background_image"))
         {
            const mxArray* background_image_ = getNamedArgument(nrhs, prhs, "background_image");
            cv::Mat background_image = getCvMat(background_image_);
            transformation_settings.background = std::make_shared<FLIMBackground>(background_image);
         }

         if (isArgument(nrhs, prhs, "tvb_profile") && isArgument(nrhs, prhs, "tvb_I_map"))
         {
            std::vector<float> tvb_profile = getVector<float>(getNamedArgument(nrhs, prhs, "tvb_profile"));
            const mxArray* I_map_ = getNamedArgument(nrhs, prhs, "I_map");
            cv::Mat I_map = getCvMat(I_map_);
            FLIMBackground(tvb_profile, I_map, background_value);
         }
         else if (background_value != 0.0)
         {
            transformation_settings.background = std::make_shared<FLIMBackground>(background_value);
         }

         auto data = std::make_shared<FLIMData>(images, transformation_settings);

         plhs[0] = packageSharedPtrForMatlab(data);
         return;
      }


      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsChar(prhs[1]));

      auto data = getSharedPtrFromMatlab<FLIMData>(prhs[0]);

      // Get command
      string command = getStringFromMatlab(prhs[1]);

      if (command == "Release")
         releaseSharedPtrFromMatlab<FLIMData>(prhs[0]);
   }
   catch (std::runtime_error e)
   {
      mexErrMsgIdAndTxt("FLIMfitMex:exceptionOccurred",
         e.what());
   }
}
