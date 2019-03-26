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

#include "FitStatus.h"
#include "FLIMData.h"
#include "GaussianIrf.h"
#include "MeasuredIrf.h"
#include "MexUtils.h"

#include <memory>
#include <unordered_set>


std::unordered_set<std::shared_ptr<FLIMData>> data_ptr;

DataTransformationSettings getDataTransformationSettings(const mxArray* settings_struct)
{
   AssertInputCondition(mxIsStruct(settings_struct));

   DataTransformationSettings settings;

   settings.smoothing_factor = getValueFromStruct(settings_struct, 0, "smoothing_factor", 0);
   settings.t_start = getValueFromStruct(settings_struct, 0, "t_start");
   settings.t_stop = getValueFromStruct(settings_struct, 0, "t_stop");
   settings.threshold = getValueFromStruct(settings_struct, 0, "threshold", 0);
   settings.limit = getValueFromStruct(settings_struct, 0, "limit", 0); // 0 = no limit

   return settings;
}

void getIrfCommon(const mxArray* irf_struct, std::shared_ptr<InstrumentResponseFunction> irf)
{
   if (mxGetFieldNumber(irf_struct, "frame_t0") >= 0)
   {
      std::vector<double> frame_t0 = getVectorFromStruct<double>(irf_struct, "frame_t0");
      irf->setFrameT0(frame_t0);
   }

   auto g_factor = getVectorFromStruct<double>(irf_struct, "g_factor");
   irf->setGFactor(g_factor);

   // TODO: irf.SetIRFShiftMap()
}

std::shared_ptr<InstrumentResponseFunction> getAnalyticalIrf(const mxArray* irf_struct)
{
   AssertInputCondition(mxIsStruct(irf_struct));

   mxArray* guassian_struct = getFieldFromStruct(irf_struct, 0, "gaussian_parameters");

   int n_chan = mxGetNumberOfElements(guassian_struct);
   std::vector<GaussianParameters> params;

   for (int i = 0; i < n_chan; i++)
      params.push_back(GaussianParameters(
         getValueFromStruct(guassian_struct, i, "mu"),
         getValueFromStruct(guassian_struct, i, "sigma"),
         getValueFromStruct(guassian_struct, i, "offset", 0)));

   auto irf = std::make_shared<GaussianIrf>(params);

   if (mxGetFieldNumber(irf_struct, "frame_sigma") >= 0)
   {
      std::vector<double> frame_sigma = getVectorFromStruct<double>(irf_struct, "frame_sigma");
      irf->setFrameSigma(frame_sigma);
   }

   getIrfCommon(irf_struct, irf);

   return irf;
}

std::shared_ptr<InstrumentResponseFunction> getIrf(const mxArray* irf_struct)
{
   AssertInputCondition(mxIsStruct(irf_struct));

   auto irf = std::make_shared<MeasuredIrf>();

   double timebin_t0 = getValueFromStruct(irf_struct, 0, "timebin_t0");
   double timebin_width = getValueFromStruct(irf_struct, 0, "timebin_width");

   const mxArray* irf_ = getFieldFromStruct(irf_struct, 0, "irf");
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
      irf->setIrf(n_t, n_chan, timebin_t0, timebin_width, irf_data);
   }

   bool ref_reconvolution = (bool)getValueFromStruct(irf_struct, 0, "ref_reconvolution", false);
   double ref_lifetime_guess = getValueFromStruct(irf_struct, 0, "ref_lifetime_guess", 80.0);

   irf->setReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   getIrfCommon(irf_struct, irf);

   return irf;
}


BOOST_CLASS_EXPORT_GUID(GaussianIrf, "GaussianIrf");
BOOST_CLASS_EXPORT_GUID(MeasuredIrf, "MeasuredIrf");

void FLIMDataMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
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
         transformation_settings.irf = getIrf(irf_struct);
      }

      if (isArgument(nrhs, prhs, "analytical_irf"))
      {
         const mxArray* irf_struct = getNamedArgument(nrhs, prhs, "analytical_irf");
         transformation_settings.irf = getAnalyticalIrf(irf_struct);
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

      if (isArgument(nrhs, prhs, "tvb_profile"))
      {
         std::vector<float> tvb_profile = getVector<float>(getNamedArgument(nrhs, prhs, "tvb_profile"));

         if (isArgument(nrhs, prhs, "tvb_I_map"))
         {
            const mxArray* I_map_ = getNamedArgument(nrhs, prhs, "tvb_I_map");
            cv::Mat I_map = getCvMat(I_map_);
            transformation_settings.background = std::make_shared<FLIMBackground>(tvb_profile, I_map, background_value);
         }
         else
         {
            transformation_settings.background = std::make_shared<FLIMBackground>(tvb_profile, background_value);
         }
      }
      else if (background_value != 0.0)
      {
         transformation_settings.background = std::make_shared<FLIMBackground>(background_value);
      }

      auto data = std::make_shared<FLIMData>(images, transformation_settings);

      plhs[0] = packageSharedPtrForMatlab(data);
      data_ptr.insert(data);
      return;
   }

   AssertInputCondition(nrhs >= 2);
   AssertInputCondition(mxIsChar(prhs[1]));

   std::shared_ptr<FLIMData> data = getSharedPtrFromMatlab<FLIMData>(prhs[0]);

   // Get command
   std::string command = getStringFromMatlab(prhs[1]);

   if (command == "Release")
   {
      data_ptr.erase(data);
      releaseSharedPtrFromMatlab<FLIMData>(prhs[0]);
   }

}
