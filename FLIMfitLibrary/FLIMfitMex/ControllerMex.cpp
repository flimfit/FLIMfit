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
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <string>
#include "MexUtils.h"
#include "PointerMap.h"

using std::string;

PointerMap<FLIMGlobalFitController> pointer_map;

void CheckInput(int nrhs, int needed);
void ErrorCheck(int nlhs, int nrhs, const mxArray *prhs[]);
void CheckSize(const mxArray* array, int needed);


void Init();
int  RunWorkers();
int  GetErrorCode();

int GetFit(int im, int n_fit, int fit_mask[], double fit[], int& n_valid);


void SetupFit(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 9);

   int global_algorithm = mxGetScalar(prhs[2]);
   int algorithm = mxGetScalar(prhs[3]);
   int weighting = mxGetScalar(prhs[4]);
   int calculate_errors = mxGetScalar(prhs[5]); 
   double conf_interval = mxGetScalar(prhs[6]);
   int n_thread = mxGetScalar(prhs[7]);
   int runAsync = mxGetScalar(prhs[8]);

   FitSettings settings(algorithm, global_algorithm, weighting, n_thread, runAsync, nullptr);
   settings.CalculateErrors(calculate_errors, conf_interval);

   c->SetFitSettings(settings);
}

void SetData(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   auto data = GetSharedPtrFromMatlab<FLIMData>(prhs[2]);
   c->SetData(data);
}

void SetModel(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   
   auto model = GetSharedPtrFromMatlab<DecayModel>(prhs[2]);
   c->SetModel(model);
}

void StartFit(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   
   c->Init();
   c->RunWorkers();
}

void GetFit(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(nlhs >= 3);

   // TODO

   //int im = mxGetScalar(prhs[2]);
   //int fit_mask[]= mxGetScalar(prhs[2]);  
   //double fit[]= mxGetScalar(prhs[2]);  
   //int* n_valid;
   
   //c->GetFit(im, n_fit, fit_mask, fit, *n_valid);
}

void ClearFit(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   c->Init();
   c->RunWorkers();
}

void StopFit(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   c->StopFit();
}

void GetFitStatus(shared_ptr<FLIMGlobalFitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 5);
   
   c->status->CalculateProgress();

   int n_thread = c->status->n_thread;

   plhs[0] = mxCreateDoubleScalar(c->status->progress);
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
      auto controller = pointer_map.Get(c_idx);
      if (controller == nullptr)
         mexErrMsgIdAndTxt("FLIMfitMex:invalidControllerIndex", "Controller index is not valid");

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "Clear")
         pointer_map.Clear(c_idx);
      else if (command == "SetupFit")
         SetupFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "SetData")
         SetupFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "SetModel")
         SetupFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "StartFit")
         SetupFit(controller, nlhs, plhs, nrhs, prhs);

   }
   catch (std::exception e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}
 




