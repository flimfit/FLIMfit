//
//  FLIMSimulation.cpp
//  FLIMfit
//
//  Created by Sean Warren on 19/09/2013.
//
//

#include "FLIMSimulation.h"
#include "FlagDefinitions.h"
#include "MeasuredIrf.h"

#include <boost/random/binomial_distribution.hpp>

using std::vector;

FLIMSimulation::FLIMSimulation(int data_type, int n_chan) :
   AcquisitionParameters(data_type, t_rep_default, n_chan, 1.0), 
   irf(2000, 100)
{
   // Generate the IRF distribution
   norm_dist = boost::random::normal_distribution<double>(irf.mu, irf.sigma);

   gen.seed(100);
}

std::shared_ptr<InstrumentResponseFunction> FLIMSimulation::GenerateIRF(int N)
{
   std::vector<double> irf_data;

   GenerateIRF_(N, irf_data);

   // Normalise IRF
   double sum = 0;
   for (int i = 0; i < n_t_full; i++)
      sum += irf_data[i];
   for (int i = 0; i < n_t_full; i++)
      irf_data[i] /= sum;

   irf_data.resize(n_meas_full);
   for (int c = 1; c < n_chan; c++)
      for (int i = 0; i < n_t_full; i++)
         irf_data[c*n_t_full + i] = irf_data[i];

   auto irf = std::make_shared<MeasuredIrf>();
   irf->setIrf(n_t_full, n_chan, 0.0, dt, irf_data.begin());

   return irf;
}

std::shared_ptr<InstrumentResponseFunction> FLIMSimulation::GetGaussianIRF()
{
   std::vector<GaussianParameters> irf_params(n_chan, irf);
   return std::make_shared<GaussianIrf>(irf_params);
}


double FLIMSimulation::SampleIRF()
{
   return norm_dist(gen);
}