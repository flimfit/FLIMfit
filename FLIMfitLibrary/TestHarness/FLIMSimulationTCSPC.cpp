#include "FLIMSimulation.h"
#include "FlagDefinitions.h"

FLIMSimulationTCSPC::FLIMSimulationTCSPC(int n_chan) :
   FLIMSimulation(DATA_TYPE_TCSPC, n_chan)
{
   double Tmax = 12500;

   n_t_full = 256;
   dt = Tmax / n_t_full;


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
