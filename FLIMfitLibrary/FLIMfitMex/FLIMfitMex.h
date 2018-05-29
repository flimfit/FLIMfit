#pragma once
#include <mex.h>

void ControllerMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void DecayModelMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void FitResultsMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void FLIMDataMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void FLIMImageMex(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
