//
//  FLIMSimulation.cpp
//  FLIMfit
//
//  Created by Sean Warren on 19/09/2013.
//
//

#include "FLIMSimulation.h"
#include "FlagDefinitions.h"

#include <boost/random/binomial_distribution.hpp>

using std::vector;

FLIMSimulationTCSPC::FLIMSimulationTCSPC() :
   FLIMSimulation(DATA_TYPE_TCSPC)
{
   n_t_full = 512;
   dt = t_rep / n_t_full;


   std::vector<double> t_;
   std::vector<double> t_int_;

   t_.assign(n_t_full, 0);

   for (int i = 0; i < n_t_full; i++)
      t_[i] = i * dt;

   // Equal integration times
   t_int_.assign(n_t_full, 1);

   setT(t_);
   setIntegrationTimes(t_int_);

}

FLIMSimulationWF::FLIMSimulationWF() :
   FLIMSimulation(DATA_TYPE_TIMEGATED),
   gate_width(1000)
{
   n_t_full = 5;

   dt = 25;
   n_t_irf = ceil((gate_width + irf_mu + 4 * irf_sigma) / dt); // make sure we record enough of the IRF

   std::vector<double> t_;
   std::vector<double> t_int_;

   t_.assign(n_t_full, 0);

   for (int i = 0; i < n_t_full; i++)
      t_[i] = i * 1000;

   // Equal integration times
   t_int_.assign(n_t_full, 1);

   setT(t_);
   setIntegrationTimes(t_int_);
}


FLIMSimulation::FLIMSimulation(int data_type) :
   AcquisitionParameters(data_type, t_rep_default, MODE_STANDARD, 1, 1.0),
   irf_mu(1000),
   irf_sigma(200)
{
   // Generate the IRF distribution
   norm_dist = boost::random::normal_distribution<double>(irf_mu, irf_sigma);

   gen.seed(100);
   //gen.seed( (uint32_t) time(NULL) );   
}



void FLIMSimulationTCSPC::GenerateDecay(double tau, int N, std::vector<int>& decay)
{
   boost::random::exponential_distribution<double> exp_dist(1 / tau);
   boost::random::poisson_distribution<int> poisson_dist(N);

   int N_ = poisson_dist(gen);

   // Generate decay histogram
   for (int i = 0; i < N_; i++)
   {
      double t_decay = exp_dist(gen);
      double t_irf = SampleIRF();
      double t_arrival = t_decay + t_irf + t_rep;

      // Wrap around to account for after pulsing
      t_arrival = fmod(t_arrival, t_rep);

      // Determine which bin the sample falls in
      int idx = (int)floor(t_arrival / dt);

      decay[idx]++;

   }

}


void FLIMSimulationWF::GenerateDecay(double tau, int N, std::vector<int>& decay)
{
   boost::random::exponential_distribution<double> exp_dist(1 / tau);


   // Calculate number of photons in each gate acquisition (note these will not necessarily fall in the gate)
   double total_integration = 0;
   for (int i = 0; i < n_t_full; i++)
      total_integration += t_int[i];

   for (int g = 0; g < n_t_full; g++)
   {
      double gate_N_avg = N * t_int[g] / total_integration;
      boost::random::poisson_distribution<int> poisson_dist(gate_N_avg);
      int gate_N = poisson_dist(gen);

      for (int i = 0; i < gate_N; i++)
      {
         double t_decay = exp_dist(gen);
         double t_irf = SampleIRF();
         double t_arrival = t_decay + t_irf;

         // Wrap around to account for after pulsing
         t_arrival = fmod(t_arrival, t_rep);

         if (t_decay >= t[g] && t_decay <= t[g] + gate_width)
            decay[g]++;
      }

   }

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

   auto irf = std::make_shared<InstrumentResponseFunction>();
   irf->setIRF(n_t_full, n_chan, 0.0, dt, &irf_data[0]);

   return irf;
}

void FLIMSimulationTCSPC::GenerateIRF_(int N, std::vector<double>& decay)
{
   decay.assign(n_t_full, 0);

   // Generate decay histogram
   for (int i = 0; i < N; i++)
   {
      double t_arrival = SampleIRF();

      // Determine which bin the sample falls in
      int idx = (int)floor(t_arrival / dt);

      // Make sure we're not outside of the sample window
      if (idx >= 0 && idx < n_t_full)
         decay[idx]++;

   }

   // Normalise IRF
   double sum = 0;
   for (int i = 0; i < n_t_full; i++)
      sum += decay[i];
   for (int i = 0; i < n_t_full; i++)
      decay[i] /= sum;

}


void FLIMSimulationWF::GenerateIRF_(int N, std::vector<double>& decay)
{

   // Calculate number of photons in each gate acquisition (note these will not necessarily fall in the gate)
   double total_integration = 0;
   for (int i = 0; i < n_t_full; i++)
      total_integration += t_int[i];

   for (int g = 0; g < n_t_irf; g++)
   {
      double gate_N_avg = N * t_int[g] / total_integration;
      boost::random::poisson_distribution<int> poisson_dist(gate_N_avg);
      int gate_N = poisson_dist(gen);

      for (int i = 0; i < gate_N; i++)
      {
         double t_irf = SampleIRF();

         // Wrap around to account for after pulsing
         t_irf = fmod(t_irf, t_rep);

         double t = g * dt;

         if (t_irf >= t && t_irf <= t + gate_width)
            decay[g]++;
      }

   }

}


double FLIMSimulation::SampleIRF()
{
   return norm_dist(gen);
}

int FLIMSimulationTCSPC::GetTimePoints(std::vector<double>& t, std::vector<double>& t_int)
{
   t.assign(n_t_full, 0);
   for (int i = 0; i < n_t_full; i++) {
      t[i] = i*dt;
   }

   // TCSPC has equal integration times by definition
   t_int.assign(n_t_full, 1.0);

   return n_t_full;
}
