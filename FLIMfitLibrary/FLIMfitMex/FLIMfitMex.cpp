#include "FLIMfitMex.h"
#include "MexUtils.h"
#include <stdexcept>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      AssertInputCondition(nrhs >= 1);
      AssertInputCondition(nlhs >= 1);

      std::string module = getStringFromMatlab(prhs[0]);

      if (module == "Controller") ControllerMex(nlhs - 1, plhs + 1, nrhs - 1, prhs + 1);
      if (module == "DecayModel") DecayModelMex(nlhs - 1, plhs + 1, nrhs - 1, prhs + 1);
      if (module == "FitResults") FitResultsMex(nlhs - 1, plhs + 1, nrhs - 1, prhs + 1);
      if (module == "FLIMData") FLIMDataMex(nlhs - 1, plhs + 1, nrhs - 1, prhs + 1);
      if (module == "FLIMImage") FLIMImageMex(nlhs - 1, plhs + 1, nrhs - 1, prhs + 1);

      plhs[0] = mxCreateString("OK");
   }
   catch (std::runtime_error e)
   {
      if (nlhs >= 1)
      {
         plhs[0] = mxCreateString(e.what());
      }
      else
      {
         mexErrMsgIdAndTxt2("FLIMfitMex:exceptionOccurred",
            e.what());
      }

   }
}