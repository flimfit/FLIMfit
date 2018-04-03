#include "FLIMSimulation.h"
#include "FlagDefinitions.h"

FLIMSimulationWF::FLIMSimulationWF() :
   FLIMSimulation(DATA_TYPE_TIMEGATED),
   gate_width(1000)
{
   n_t_full = 5;

   dt = 25;
   n_t_irf = ceil((gate_width + irf.mu + 4 * irf.sigma) / dt); // make sure we record enough of the IRF

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
