#include "Aberration.h"
#include "AbstractDecayGroup.h"

Aberration::Aberration(int chan, int order) :
   chan(chan), order(order)
{

   std::vector<ParameterFittingType> fixed_or_global = { Fixed, FittedGlobally };
   std::vector<std::string> names = { "z0", "z10", "z11", "z20", "z21", "z22" };
   std::vector<double> initial = { 1, 0.1, 0.1, 0, 0, 0 };

   for (int i=0; i<names.size(); i++)
   {
      std::stringstream name;
      name << "c" << chan << "_" << names[i];
      all_parameters.push_back(std::make_shared<FittingParameter>(name.str(), initial[i], 1.0, fixed_or_global, FittedGlobally));
   }

   setOrder(order);
}


void Aberration::setTransformedDataParameters(std::shared_ptr<TransformedDataParameters> dp)
{
   bool recalculate = ((n_x != dp->n_x) || (n_y != dp->n_y));

   n_x = dp->n_x;
   n_y = dp->n_y;
   n_t = dp->n_t;

   if (recalculate)
   {
      cv::Mat rho(n_y, n_x, CV_64F);
      cv::Mat sin_theta(n_y, n_x, CV_64F);
      cv::Mat cos_theta(n_y, n_x, CV_64F);

      double image_radius = std::max(n_x, n_y);

      for (int y = 0; y < n_y; y++)
         for (int x = 0; x < n_x; x++)
         {
            double dx = x - (n_x * 0.5);
            double dy = y - (n_y * 0.5);

            double r = sqrt(dx * dx + dy * dy);

            rho.at<double>(y, x) = r / image_radius;
            sin_theta.at<double>(y, x) = (r == 0) ? 0 : dx / r;
            cos_theta.at<double>(y, x) = (r == 0) ? 0 : dy / r;
         }

      cv::Mat rho_rho = rho.mul(rho);
      cv::Mat rho_rho_cos_theta = rho_rho.mul(cos_theta);

      z.clear();
      z.push_back(cv::Mat(n_y, n_x, CV_64F, cv::Scalar(1.0)));
      z.push_back(2.0 * rho.mul(sin_theta));
      z.push_back(2.0 * rho.mul(cos_theta));
      z.push_back(sqrt(6.0) * 2.0 * rho_rho_cos_theta.mul(sin_theta));
      z.push_back(sqrt(3.0) * (2.0 * rho_rho - 1.0));
      z.push_back(sqrt(6.0) * (2.0 * rho_rho_cos_theta.mul(cos_theta) - 1.0));
   }
}

void Aberration::setOrder(int order_)
{
   order = order_;

   if (order < 0 || order > 2)
      throw std::runtime_error("Invalid zernike order");

   active_parameters.clear();

   if (order >= 0)
   {
      active_parameters.push_back(all_parameters[0]);
   }
   if (order >= 1)
   {
      active_parameters.push_back(all_parameters[1]);
      active_parameters.push_back(all_parameters[2]);
   }
   if (order >= 2)
   {
      active_parameters.push_back(all_parameters[3]);
      active_parameters.push_back(all_parameters[4]);
      active_parameters.push_back(all_parameters[5]);
   }

   coeff.resize(active_parameters.size());
}

void Aberration::setupIncMatrix(std::vector<int>& inc, int& row, int& col)
{
   for (auto& p : active_parameters)
   {
      if (p->isFittedGlobally())
      {
         for (int i = 0; i < col; i++)
            inc[row + i * MAX_VARIABLES] = 1;
         row++;
      }
   }
}

int Aberration::setVariables(const double* params)
{
   int idx = 0;
   int i = 0;
   for (; i < active_parameters.size(); i++)
      coeff[i] = active_parameters[i]->getValue<double>(params, idx);
   for (; i < coeff.size(); i++)
      coeff[i] = 0.0;
   return idx;
}


double Aberration::computeChannelFactor(int x, int y)
{
   double chan_factor = 0;
   for (int i = 0; i < coeff.size(); i++)
      chan_factor += coeff[i] * z[i].at<double>(y, x);
   assert(std::isfinite(chan_factor));
   return chan_factor;
}


void Aberration::apply(int x, int y, aligned_iterator& a, int adim, int n_col)
{
   double chan_factor = computeChannelFactor(x, y);

   for (int i = 0; i < n_col; i++)
      for (int t = 0; t < n_t; t++)
         a[t + chan * n_t + i * adim] *= chan_factor;
}

int Aberration::calculateDerivatives(int x, int y, const aligned_vector<double>& a, int adim, int n_col, aligned_iterator& b, int bdim)
{
   double chan_factor = 1.0 / computeChannelFactor(x, y);

   int col = 0;
   for (int i = 0; i < coeff.size(); i++)
   {
      for (int j = 0; j < n_col; j++)
      {
         for (int t = 0; t < n_t; t++)
            b[t + chan * n_t + col * bdim] = a[t + chan * n_t + j * adim] * chan_factor * z[i].at<double>(y, x); // we need to take channel factor out here
         col++;
      }
   }

   return col;
}