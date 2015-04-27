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
#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "PointerMap.h"
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <map>
#include "MexUtils.h"

int next_id = 0;

PointerMap<FitResults> pointer_map;


void GetOutputParamNames(FitResults* r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);

   const vector<string>& names = r->GetOutputParamNames();

   plhs[0] = mxCreateCellMatrix(1, names.size());

   for (int i = 0; i < names.size(); i++)
   {
      mxArray* s = mxCreateString(names[i].c_str());
      mxSetCell(plhs[0], i, s);
   }
}

void GetTotalNumOutputRegions(FitResults* r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);

   int n_regions = r->GetNumOutputRegions();
   plhs[0] = mxCreateDoubleScalar(n_regions);
}

void GetImageStats(FitResults* r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 2);

   int n_regions = r->GetNumOutputRegions();

   int* image = reinterpret_cast<int*>(mxCreateNumericMatrix(n_regions, 1, mxINT32_CLASS, mxREAL));
   int* region_idx = reinterpret_cast<int*>(mxCreateNumericMatrix(n_regions, 1, mxINT32_CLASS, mxREAL));
   int* regions_size = reinterpret_cast<int*>(mxCreateNumericMatrix(n_regions, 1, mxINT32_CLASS, mxREAL));
   int* success = reinterpret_cast<int*>(mxCreateNumericMatrix(n_regions, 1, mxINT32_CLASS, mxREAL));
   int* iterations = reinterpret_cast<int*>(mxCreateNumericMatrix(n_regions, 1, mxINT32_CLASS, mxREAL));

   vector<RegionSummary> summary;
   ImageStats<float> stats;
   r->ComputeImageStats(0.05f, summary, stats);

   const char* fieldnames[5] =
   {  "image",
      "index",
      "size",
      "succes",
      "iterations"
   };

   plhs[0] = mxCreateStructMatrix(1, n_regions, 4, fieldnames);

   for (int i = 0; i < n_regions; i++)
   {
      mxSetFieldByNumber(plhs[0], i, 0, mxCreateDoubleScalar(summary[i].image));
      mxSetFieldByNumber(plhs[0], i, 1, mxCreateDoubleScalar(summary[i].region));
      mxSetFieldByNumber(plhs[0], i, 2, mxCreateDoubleScalar(summary[i].size));
      mxSetFieldByNumber(plhs[0], i, 3, mxCreateDoubleScalar(summary[i].success));
      mxSetFieldByNumber(plhs[0], i, 4, mxCreateDoubleScalar(summary[i].iterations));
   }

   mwSize sz[3] = { stats.GetNumStats(), stats.GetNumParams(), n_regions };
   plhs[1] = mxCreateNumericArray(3, sz, mxSINGLE_CLASS, mxREAL);

   float* ptr = reinterpret_cast<float*>(mxGetPr(plhs[0]));
   vector<float>& stats_data = stats.GetStats();
   std::copy(stats_data.begin(), stats_data.end(), ptr);
}

void GetParameterImage(FitResults* r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 2);
   AssertInputCondition(nrhs >= 4);

   int im = mxGetScalar(prhs[2]);
   int param = mxGetScalar(prhs[3]);

   int n_x = r->GetNumX();
   int n_y = r->GetNumY();

   plhs[0] = mxCreateNumericMatrix(n_y, n_x, mxUINT8_CLASS, mxREAL);
   plhs[1] = mxCreateNumericMatrix(n_y, n_x, mxSINGLE_CLASS, mxREAL);

   uint8_t* ptr_map = reinterpret_cast<uint8_t*>(plhs[0]);
   float* ptr_param = reinterpret_cast<float*>(plhs[0]);

   r->GetParameterImage(im, param, ptr_map, ptr_param);
}





void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   try
   {
      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsUint64(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      FitResults* results = *reinterpret_cast<FitResults**>(mxGetData(prhs[0]));

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "GetOutputParamNames")
         GetOutputParamNames(results, nlhs, plhs, nrhs, prhs);
      else if (command == "GetTotalNumOutputRegions")
         GetTotalNumOutputRegions(results, nlhs, plhs, nrhs, prhs);
      else if (command == "GetImageStats")
         GetImageStats(results, nlhs, plhs, nrhs, prhs);
      else if (command == "GetParameterImage")
         GetParameterImage(results, nlhs, plhs, nrhs, prhs);
      else
         mexErrMsgIdAndTxt("FLIMfitMex:invalidIndex", "Unrecognised command");

   }
   catch (std::exception e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}
