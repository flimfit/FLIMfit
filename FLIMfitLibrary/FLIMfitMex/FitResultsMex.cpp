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
#include "PointerMap.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <map>
#include "MexUtils.h"

int next_id = 0;

void getOutputParamNames(std::shared_ptr<FitResults> r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);

   auto& names = r->getOutputParamNames();
   plhs[0] = mxCreateCellMatrix(1, names.size());

   for (int i = 0; i < names.size(); i++)
   {
      mxArray* s = mxCreateString(names[i].c_str());
      mxSetCell(plhs[0], i, s);
   }

   if (nlhs >= 2)
   {
      auto& group = r->getOutputParamGroup();
      plhs[1] = mxCreateDoubleMatrix(1, group.size(), mxREAL);
      std::copy(group.begin(), group.end(), (double*)mxGetData(plhs[1]));
   }
}

void getTotalNumOutputRegions(std::shared_ptr<FitResults> r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);

   int n_regions = r->getNumOutputRegions();
   plhs[0] = mxCreateDoubleScalar(n_regions);
}


void getImageStats(std::shared_ptr<FitResults> r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);
    
   // Summary
   auto& summary = r->getRegionSummary();
   const char* labels[] = { "image", "region", "size", "iterations", "success" };;

   uint num_regions = summary.size();

   plhs[0] = mxCreateStructMatrix(1, 1, 5, labels);
   mxArray* image = mxCreateDoubleMatrix(num_regions, 1, mxREAL);
   mxArray* region = mxCreateDoubleMatrix(num_regions, 1, mxREAL);
   mxArray* size = mxCreateDoubleMatrix(num_regions, 1, mxREAL);
   mxArray* iterations = mxCreateDoubleMatrix(num_regions, 1, mxREAL);
   mxArray* success = mxCreateDoubleMatrix(num_regions, 1, mxREAL);

   mxSetFieldByNumber(plhs[0], 0, 0, image);
   mxSetFieldByNumber(plhs[0], 0, 1, region);
   mxSetFieldByNumber(plhs[0], 0, 2, size);
   mxSetFieldByNumber(plhs[0], 0, 3, iterations);
   mxSetFieldByNumber(plhs[0], 0, 4, success);

   double* imaged = reinterpret_cast<double*>(mxGetData(image));
   double* regiond = reinterpret_cast<double*>(mxGetData(region));
   double* sized = reinterpret_cast<double*>(mxGetData(size));
   double* iterationsd = reinterpret_cast<double*>(mxGetData(iterations));
   double* successd = reinterpret_cast<double*>(mxGetData(success));

   for (uint i = 0; i < num_regions; i++)
   {
      imaged[i] = summary[i].image;
      regiond[i] = summary[i].region;
      sized[i] = summary[i].size;
      iterationsd[i] = summary[i].iterations;
      successd[i] = summary[i].success;
   }

   if (nlhs < 2)
      return;

   // Statistics
   auto& stats = r->getStats();
   uint num_params = stats.GetNumParams();
   uint num_stats = stats.GetNumStats();

   mwSize dims[] = { num_stats, num_params, num_regions };
   plhs[1] = mxCreateNumericArray(3, dims, mxSINGLE_CLASS, mxREAL);
   float* sf = reinterpret_cast<float*>(mxGetData(plhs[1]));

   auto stats_vector = stats.GetStats();
   std::copy(stats_vector.begin(), stats_vector.end(), sf);
}

void getParameterImage(std::shared_ptr<FitResults> r, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 2);
   AssertInputCondition(nrhs >= 4);

   int im = mxGetScalar(prhs[2]) - 1;
   int param = mxGetScalar(prhs[3]) - 1;

   int n_x = r->getNumX(im);
   int n_y = r->getNumY(im);

   plhs[0] = mxCreateNumericMatrix(n_x, n_y, mxSINGLE_CLASS, mxREAL);
   plhs[1] = mxCreateNumericMatrix(n_x, n_y, mxUINT8_CLASS, mxREAL);
   
   float* ptr_param = reinterpret_cast<float*>(mxGetData(plhs[0]));
   uint8_t* ptr_mask = reinterpret_cast<uint8_t*>(mxGetData(plhs[1]));

   r->getParameterImage(im, param, ptr_mask, ptr_param);
}


void FitResultsMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 2);
   AssertInputCondition(mxIsChar(prhs[1]));

   auto results = getSharedPtrFromMatlab<FitResults>(prhs[0]);

   // Get command
   std::string command = getStringFromMatlab(prhs[1]);

   if (command == "GetOutputParamNames")
      getOutputParamNames(results, nlhs, plhs, nrhs, prhs);
   else if (command == "GetTotalNumOutputRegions")
      getTotalNumOutputRegions(results, nlhs, plhs, nrhs, prhs);
   else if (command == "GetStats")
      getImageStats(results, nlhs, plhs, nrhs, prhs);
   else if (command == "GetParameterImage")
      getParameterImage(results, nlhs, plhs, nrhs, prhs);
   else if (command == "Clear")
      releaseSharedPtrFromMatlab<FitResults>(prhs[0]);
   else
      mexErrMsgIdAndTxt("FLIMfitMex:invalidIndex", "Unrecognised command");

}
