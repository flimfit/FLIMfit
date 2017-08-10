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

#include "FitController.h"
#include "FitStatus.h"
#include "InstrumentResponseFunction.h"
#include "ModelADA.h" 
#include "FLIMGlobalAnalysis.h"
#include "FLIMData.h"
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <string>
#include <unordered_set>
#include "MexUtils.h"

std::unordered_set<std::shared_ptr<FitController>> ptr_set;

void setFitSettings(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsStruct(prhs[2]));

   FitSettings settings;

   settings.global_algorithm = getValueFromStruct(prhs[2],"global_algorithm", 1);
   settings.global_scope = getValueFromStruct(prhs[2], "global_scope", 0);
    settings.algorithm = getValueFromStruct(prhs[2], "algorithm", 0);
   settings.weighting = getValueFromStruct(prhs[2], "weighting");
   settings.n_thread = getValueFromStruct(prhs[2], "n_thread", 4);
   settings.run_async = getValueFromStruct(prhs[2], "run_async", 1);

   int calculate_errors = getValueFromStruct(prhs[2], "calculate_errors", 0);
   double conf_interval = getValueFromStruct(prhs[2], "conf_interval", 0.05);
   settings.setCalculateErrors(calculate_errors, conf_interval);

   c->setFitSettings(settings);
}

void setData(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   auto data = getSharedPtrFromMatlab<FLIMData>(prhs[2]);
   c->setData(data);
}

void setModel(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   
   auto model = getSharedPtrFromMatlab<QDecayModel>(prhs[2]);
   c->setModel(model);
}

void startFit(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{   
   c->init();
   c->runWorkers();
}

void clearFit(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
// TODO
}

void stopFit(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   c->stopFit();
}

void getFitStatus(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 2);
   
   auto reporter = c->getProgressReporter();

   plhs[0] = mxCreateDoubleScalar(reporter->getProgress());
   plhs[1] = mxCreateLogicalScalar(reporter->isFinished());

   //const char* labels[] = { "group", "n_completed", "iter", "chi2" };
   //plhs[2] = mxCreateStructMatrix(1, 1, 4, labels);

   /* TODO
   //   int n_thread = c->status->n_thread;
   plhs[1] = mxCreateDoubleMatrix(1, n_thread, mxREAL);
   plhs[2] = mxCreateDoubleMatrix(1, n_thread, mxREAL);
   plhs[3] = mxCreateDoubleMatrix(1, n_thread, mxREAL);
   plhs[4] = mxCreateDoubleMatrix(1, n_thread, mxREAL);

   double* group = mxGetPr(plhs[1]);
   double* n_completed = mxGetPr(plhs[2]);
   double* iter = mxGetPr(plhs[3]);
   double* chi2 = mxGetPr(plhs[4]);

   for (int i = 0; i<c->status->n_thread; i++)
   {
      group[i] = c->status->group[i];
      n_completed[i] = c->status->n_completed[i];
      iter[i] = c->status->iter[i];
      chi2[i] = c->status->chi2[i];
   }
   */
}

void getFitResults(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 1);
   plhs[0] = packageSharedPtrForMatlab(c->getResults());
}

void getFit(std::shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 4);
   AssertInputCondition(nlhs >= 1);

   AssertInputCondition(mxIsNumeric(prhs[2])); // image
   AssertInputCondition(mxIsUint32(prhs[3])); // fitloc

   int im = mxGetScalar(prhs[2]);
   uint32_t* loc = reinterpret_cast<uint32_t*>(mxGetData(prhs[3]));
   int n_fit = mxGetNumberOfElements(prhs[3]);
   
   auto dp = c->getData()->GetTransformedDataParameters();  
   mwSize dims[] = { (uint) dp->n_t, (uint) dp->n_chan, (uint) n_fit };

   plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
   double* fit = reinterpret_cast<double*>(mxGetData(plhs[0]));

   int n_valid;
   c->getFit(im, n_fit, loc, fit, n_valid);

   if (nlhs >= 2)
      plhs[1] = mxCreateDoubleScalar(n_valid);
}




void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nrhs == 0 && nlhs > 0)
      {
         AssertInputCondition(nlhs > 0);
         auto c = std::make_shared<FitController>();
         ptr_set.insert(c);
         plhs[0] = packageSharedPtrForMatlab(c);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsScalar(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      // Get controller
      const auto& controller = getSharedPtrFromMatlab<FitController>(prhs[0]);
      
      if (ptr_set.find(controller) == ptr_set.end())
         mexErrMsgIdAndTxt("FLIMfitMex:invalidControllerPointer", "Invalid controller pointer");

      // Get command
      std::string command = getStringFromMatlab(prhs[1]);

      if (command == "Clear")
      {
         ptr_set.erase(controller);
         releaseSharedPtrFromMatlab<FitController>(prhs[0]);
      }
      else if (command == "SetFitSettings")
         setFitSettings(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "SetData")
         setData(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "SetModel")
         setModel(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "StartFit")
         startFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "StopFit")
         stopFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "GetFitStatus")
         getFitStatus(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "GetFit")
         getFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "GetFitResults")
         getFitResults(controller, nlhs, plhs, nrhs, prhs);

   }
   catch (std::runtime_error e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}
 




