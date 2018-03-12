#include "AbstractConvolver.h"
#include "MeasuredIrfConvolver.h"
#include "GaussianIrfConvolver.h"

AbstractConvolver::AbstractConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   dp(dp),
   irf(dp->irf),
   n_chan(dp->n_chan),
   n_t(dp->n_t)
{
}

std::shared_ptr<AbstractConvolver> AbstractConvolver::make(std::shared_ptr<TransformedDataParameters> dp)
{
   if (dp->irf->isGaussian())
      return std::make_shared<GaussianIrfConvolver>(dp);
   else
      return std::make_shared<MeasuredIrfConvolver>(dp);
}

std::vector<std::shared_ptr<AbstractConvolver>> AbstractConvolver::make_vector(size_t n, std::shared_ptr<TransformedDataParameters> dp)
{
   std::vector<std::shared_ptr<AbstractConvolver>> v;
   v.reserve(n);
   for (size_t i = 0; i < n; i++)
      v.push_back(make(dp));

   return v;
}
