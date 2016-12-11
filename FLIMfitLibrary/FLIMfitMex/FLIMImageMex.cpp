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

#include "FLIMImage.h"
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <unordered_set>
#include "MexUtils.h"

std::unordered_set<std::shared_ptr<FLIMImage>> ptr_set;

#ifdef _WINDOWS
#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif
#endif

std::shared_ptr<AcquisitionParameters> getAcquisitionParameters(const mxArray* acq_params_struct)
{
   AssertInputCondition(mxIsStruct(acq_params_struct));

   int data_type = getValueFromStruct(acq_params_struct, "data_type");
   double t_rep = getValueFromStruct(acq_params_struct, "t_rep");
   int polarisation_resolved = getValueFromStruct(acq_params_struct, "polarisation_resolved");
   int n_chan = getValueFromStruct(acq_params_struct, "n_chan");
   double counts_per_photon = getValueFromStruct(acq_params_struct, "counts_per_photon");

   int n_x = getValueFromStruct(acq_params_struct, "n_x");
   int n_y = getValueFromStruct(acq_params_struct, "n_y");


   std::vector<double> t = getVectorFromStruct<double>(acq_params_struct, "t");
   std::vector<double> t_int = getVectorFromStruct<double>(acq_params_struct, "t_int");

   auto acq = std::make_shared<AcquisitionParameters>(data_type, t_rep, polarisation_resolved, n_chan, counts_per_photon);
   acq->setT(t);
   acq->setIntegrationTimes(t_int);
   acq->setImageSize(n_x, n_y);
   
   return acq;
}


void setMask(std::shared_ptr<FLIMImage> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsUint8(prhs[2]));
   AssertInputCondition(mxGetNumberOfElements(prhs[2]) == d->getAcquisitionParameters()->n_px);
   
   uint8_t* mask = reinterpret_cast<uint8_t*>(mxGetData(prhs[3]));

   d->setSegmentationMask(mask);
}

void setAcceptor(std::shared_ptr<FLIMImage> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsSingle(prhs[2]));

   float* acceptor = reinterpret_cast<float*>(mxGetData(prhs[2]));
   //d->setAcceptor(acceptor); // TODO
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nlhs > 0 && nrhs > 0 && !mxIsScalar(prhs[0]))
      {
         const mxArray* acq_struct = getNamedArgument(nrhs, prhs, "acquisition_parmeters");
         auto acq = getAcquisitionParameters(acq_struct);

         std::shared_ptr<FLIMImage> image;

         if (isArgument(nrhs, prhs, "data"))
         {
            const mxArray* data = getNamedArgument(nrhs, prhs, "data");
            
            FLIMImage::DataClass data_class;
            if (mxIsUint16(data))
               data_class = FLIMImage::DataUint16;
            if (mxIsSingle(data))
               data_class = FLIMImage::DataFloat;
            else
               mexErrMsgIdAndTxt("FLIMfit:invalidDataClass", "data must be single precision floating point or uint16");

            image = std::make_shared<FLIMImage>(acq, FLIMImage::InMemory, data_class, mxGetData(data));
         }
         else if (isArgument(nrhs, prhs, "mapped_file"))
         {
            std::string mapped_file = GetStringFromMatlab(getNamedArgument(nrhs, prhs, "mapped_file"));
            int map_offset = mxGetScalar(getNamedArgument(nrhs, prhs, "data_offset"));

            std::string data_class_str = GetStringFromMatlab(getNamedArgument(nrhs, prhs, "data_class"));
            FLIMImage::DataClass data_class;
            if (data_class_str == "uint16")
               data_class = FLIMImage::DataUint16;
            else if (data_class_str == "float" || data_class_str == "single")
               data_class = FLIMImage::DataFloat;
            else
               mexErrMsgIdAndTxt("FLIMfit:unknownDataClass", "Data class is not recognised; should be uint16 or float/single");

            
            image = std::make_shared<FLIMImage>(acq, mapped_file, data_class, map_offset);
         }
         else
         {
            mexErrMsgIdAndTxt("FLIMfit:dataNotProvided", "Data must be provided using 'data' or 'mapped_file' named arguments");
         }

         ptr_set.insert(image);
         plhs[0] = PackageSharedPtrForMatlab(image);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsChar(prhs[1]));

      // Get controller
      auto& d = GetSharedPtrFromMatlab<FLIMImage>(prhs[0]);

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "Release")
         ReleaseSharedPtrFromMatlab<FLIMImage>(prhs[0]);
      else if (command == "SetMask")
         setMask(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetAcceptor")
         setAcceptor(d, nlhs, plhs, nrhs, prhs);
      else
         mexErrMsgIdAndTxt("FLIMfitMex:invalidCommand", "Unrecognised command");

   }
   catch (std::runtime_error e)
   {
      mexErrMsgIdAndTxt("FLIMfitMex:exceptionOccurred",
         e.what());
   }
}
