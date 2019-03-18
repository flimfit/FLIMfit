#include "AbstractConvolver.h"
#include "DataTransformer.h"

AbstractConvolver::AbstractConvolver(std::shared_ptr<TransformedDataParameters> dp) :
   dp(dp),
   n_chan(dp->n_chan),
   n_t(dp->n_t)
{
}

std::shared_ptr<AbstractConvolver> AbstractConvolver::make(std::shared_ptr<TransformedDataParameters> dp)
{
   return dp->irf->getConvolver(dp);
}

std::vector<std::shared_ptr<AbstractConvolver>> AbstractConvolver::make_vector(size_t n, std::shared_ptr<TransformedDataParameters> dp)
{
   std::vector<std::shared_ptr<AbstractConvolver>> v;
   v.reserve(n);
   for (size_t i = 0; i < n; i++)
      v.push_back(make(dp));

   return v;
}
