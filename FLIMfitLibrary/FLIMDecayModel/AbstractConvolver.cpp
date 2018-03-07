#include "AbstractConvolver.h"
#include "MeasuredIrfConvolver.h"

AbstractConvolver::AbstractConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   dp(dp),
   irf(dp->irf),
   n_chan(dp->n_chan),
   n_t(dp->n_t)
{
}

std::shared_ptr<AbstractConvolver> AbstractConvolver::make(std::shared_ptr<TransformedDataParameters> dp)
{
   return std::make_shared<MeasuredIrfConvolver>(dp);
}
