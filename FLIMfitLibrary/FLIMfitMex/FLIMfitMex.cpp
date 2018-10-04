#include "FLIMfitMex.h"
#include "MexUtils.h"
#include <stdexcept>

DLL_EXPORT_SYM
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      AssertInputCondition(nrhs >= 1);

      std::string module = getStringFromMatlab(prhs[0]);

      if (module == "Controller") ControllerMex(nlhs, plhs, nrhs - 1, prhs + 1);
      if (module == "DecayModel") DecayModelMex(nlhs, plhs, nrhs - 1, prhs + 1);
      if (module == "FitResults") FitResultsMex(nlhs, plhs, nrhs - 1, prhs + 1);
      if (module == "FLIMData") FLIMDataMex(nlhs, plhs, nrhs - 1, prhs + 1);
      if (module == "FLIMImage") FLIMImageMex(nlhs, plhs, nrhs - 1, prhs + 1);
   }
   catch (std::runtime_error e)
   {
      mexErrMsgIdAndTxt("FLIMfitMex:runtimeErrorOccurred", e.what());
   }
}