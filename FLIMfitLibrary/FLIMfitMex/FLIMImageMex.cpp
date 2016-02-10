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
#include "MexUtils.h"
#include "PointerMap.h"

PointerMap<FLIMData> pointer_map;

#ifdef _WINDOWS
#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif
#endif

class Container
{
public:
   AcquisitionParameters acq;
   InstrumentResponseFunction irf;
   FLIMImage image;
};

void SetAcquisitionParameters(shared_ptr<Container> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 12);
   AssertInputCondition(mxIsInt32(prhs[11]));

   int data_type = mxGetScalar(prhs[2]);
   double t_rep = mxGetScalar(prhs[3]);
   int polarisation_resolved = mxGetScalar(prhs[4]);
   int n_chan = mxGetScalar(prhs[5]);
   double counts_per_photon = mxGetScalar(prhs[6]);

   int n_t_full = mxGetScalar(prhs[7]);
   int n_t = mxGetScalar(prhs[8]);
   double* t = mxGetPr(prhs[9]);
   double* t_int = mxGetPr(prhs[10]);
   int* t_skip = reinterpret_cast<int*>(mxGetData(prhs[11]));

   auto acq = AcquisitionParameters(data_type, t_rep, polarisation_resolved, n_chan, counts_per_photon);
   acq.setT(n_t_full, t, t_int);

   d->acq = acq;
}

void SetIRF(shared_ptr<Container> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 10);

   int n_irf = mxGetN(prhs[2]);
   int n_chan = mxGetM(prhs[3]);
   double* data = mxGetPr(prhs[4]);

   double t0 = mxGetScalar(prhs[5]);
   double dt = mxGetScalar(prhs[6]);

   int ref_reconvolution = mxGetScalar(prhs[7]);
   double ref_lifetime_guess = mxGetScalar(prhs[8]);

   InstrumentResponseFunction irf;
   irf.SetIRF(n_irf, n_chan, t0, dt, data);
   if (ref_reconvolution)
      irf.SetReferenceReconvolution(ref_reconvolution, ref_lifetime_guess);

   d->irf = irf;
}

void SetDataSize(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 5);

   int n_im = mxGetScalar(prhs[2]);
   int n_x = mxGetScalar(prhs[3]);
   int n_y = mxGetScalar(prhs[4]);

   d->SetImageSize(n_x, n_y);
   d->SetNumImages(n_im);
}

void SetMasking(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 5);
   AssertInputCondition(mxGetNumberOfElements(prhs[2]) == d->n_im);
   AssertInputCondition(mxGetNumberOfElements(prhs[3]) == d->n_im * d->n_x * d->n_y);

   int* use_im = reinterpret_cast<int32_t*>(mxGetData(prhs[2]));
   uint8_t* mask = reinterpret_cast<uint8_t*>(mxGetData(prhs[3]));
   int merge_regions = mxGetScalar(prhs[4]);

   d->SetMasking(use_im, mask, merge_regions);
}

void SetData(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   const mxArray* data = prhs[2];

   if (mxIsSingle(data))
   {
      float* ptr = reinterpret_cast<float*>(mxGetData(data));
      d->SetData(ptr);
   }
   else if (mxIsUint16(data))
   {
      uint16_t* ptr = reinterpret_cast<uint16_t*>(mxGetData(data));
      d->SetData(ptr);
   }
   else
   {
      mexErrMsgIdAndTxt("FLIMfitMex:invalidInput", "FLIMData must be single precision floating point or uint16");
   }
}

void SetDataFromFile(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 5);
   AssertInputCondition(mxIsChar(prhs[2]));

   std::string data_file = GetStringFromMatlab(prhs[2]);
   int data_class = mxGetScalar(prhs[3]);
   int data_skip = mxGetScalar(prhs[4]);

   d->SetData(data_file.c_str(), data_class, data_skip);
}

void SetAcceptor(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsSingle(prhs[2]));

   float* acceptor = reinterpret_cast<float*>(mxGetData(prhs[2]));
   d->SetAcceptor(acceptor);
}

void SetBackgroundImage(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsSingle(prhs[2]));

   float* data = reinterpret_cast<float*>(mxGetData(prhs[2]));
   d->SetBackground(data);
}

void SetBackground(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   float data = mxGetScalar(prhs[2]);
   d->SetBackground(data);
}

void SetBackgroundTVImage(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 5);
   AssertInputCondition(mxIsSingle(prhs[2]));
   AssertInputCondition(mxIsSingle(prhs[3]));

   float* tvb_profile = reinterpret_cast<float*>(mxGetData(prhs[2]));
   float* tvb_I_map = reinterpret_cast<float*>(mxGetData(prhs[3]));
   float const_background = mxGetScalar(prhs[4]);

   d->SetTVBackground(tvb_profile, tvb_I_map, const_background);
}

void SetImageT0Shift(shared_ptr<FLIMData> d, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsDouble(prhs[3]));

   double* data = mxGetPr(prhs[2]);
   d->SetImageT0Shift(data);
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nrhs == 0 && nlhs > 0)
      {
         AssertInputCondition(nlhs > 0);
         int idx = pointer_map.CreateObject();
         plhs[0] = mxCreateDoubleScalar(idx);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsScalar(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      int c_idx = mxGetScalar(prhs[0]);

      // Get controller
      auto d = pointer_map.Get(c_idx);
      if (d == nullptr)
         mexErrMsgIdAndTxt("FLIMfitMex:invalidControllerIndex", "Controller index is not valid");

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "Clear")
         pointer_map.Clear(c_idx);
      else if (command == "SetAcquisitionParameters")
         SetAcquisitionParameters(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetIRF")
         SetIRF(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetDataSize")
         SetDataSize(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetMasking")
         SetMasking(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetThresholds")
         SetThresholds(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetGlobalMode")
         SetGlobalMode(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetData")
         SetData(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetSmoothing")
         SetSmoothing(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetDataFromFile")
         SetDataFromFile(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetAcceptor")
         SetAcceptor(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetBackgroundImage")
         SetBackgroundImage(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetBackground")
         SetBackground(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetBackgroundTVImage")
         SetBackgroundTVImage(d, nlhs, plhs, nrhs, prhs);
      else if (command == "SetImageT0Shift")
         SetImageT0Shift(d, nlhs, plhs, nrhs, prhs);
      else
         mexErrMsgIdAndTxt("FLIMfitMex:invalidIndex", "Unrecognised command");

   }
   catch (std::exception e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}
