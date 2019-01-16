#pragma once

#include <vector>
#include <opencv2/core.hpp>
#include "AbstractConvolver.h"
#include "FittingParameter.h"

class Aberration
{
public:
   Aberration(int chan, int order);

   void setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp);
   void setOrder(int order);

   void setupIncMatrix(std::vector<int>& inc, int& row, int& col);
   int setVariables(std::vector<double>::const_iterator params);

   void apply(int x, int y, double_iterator a, int adim, int n_col);

   int calculateDerivatives(int x, int y, const_double_iterator a, int adim, int n_col, double_iterator b, int bdim);

   const std::vector<std::shared_ptr<FittingParameter>>& getParameters() { return active_parameters; };

protected:

   double computeChannelFactor(int x, int y);

private:

   std::vector<double> coeff;
   std::vector<std::shared_ptr<FittingParameter>> all_parameters;
   std::vector<std::shared_ptr<FittingParameter>> active_parameters;
   int n_x = 0;
   int n_y = 0;
   int n_t, chan;
   int order;
   std::vector<cv::Mat> z;
};
