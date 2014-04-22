//
//  FLIMSimulation.h
//  FLIMfit
//
//  Created by Sean Warren on 19/09/2013.
//
//

#ifndef FLIMfit_FLIMSimulation_h
#define FLIMfit_FLIMSimulation_h

#include <boost/random/mersenne_twister.hpp>
#include <boost/random/normal_distribution.hpp>
#include <boost/random/exponential_distribution.hpp>
#include <time.h>

#include <vector>

using std::vector;

enum DataMode
{
   TCSPC,
   Widefield
};

class FLIMSimulation
{
public:
   FLIMSimulation();
   
   template <class U>
   void GenerateDecay(double tau, int N, vector<U>& decay);

   template <class U>
   void GenerateImage(double tau, int N, int n_x, int n_y, vector<U>& decay);
   
   void GenerateIRF(int N, vector<double>& decay);
   int GetTimePoints(vector<double>& t, vector<double>& t_int);
   
private:

   double SampleIRF();

   DataMode mode;
   
   // IRF properties
   double irf_mu;
   double irf_sigma;
   
   // Sampling
   int n_t;
   int T;
   int dt;
   
   template <class U>
   void GenerateDecay(double tau, int N, U* decay);


   boost::mt19937 gen;
   boost::random::normal_distribution<double> norm_dist;
};

template <class U>
void FLIMSimulation::GenerateImage(double tau, int N, int n_x, int n_y, vector<U>& decay)
{
   decay.assign(n_t * n_x * n_y, 0);

   for(int x=0; x<n_x; x++)
   {
      for(int y=0; y<n_y; y++)
      {
         int pos = y + n_y*x;
         GenerateDecay(tau, N, &decay[pos * n_t]); 
      }
   }
}



template <class U>
void FLIMSimulation::GenerateDecay(double tau, int N, U* decay)
{
   boost::random::exponential_distribution<double> exp_dist(1/tau);
   
   // Generate decay histogram
   for(int i=0; i<N; i++)
   {
      double t_decay = exp_dist(gen);
      double t_irf   = SampleIRF();
      double t_arrival = t_decay + t_irf;
      
      // Determine which bin the sample falls in
      int idx = floor(t_arrival/dt);
      
      // Make sure we're not outside of the sample window
      if (idx >= 0 && idx<n_t)
         decay[idx]++;
      
   }
   
}

template <class U>
void FLIMSimulation::GenerateDecay(double tau, int N, vector<U>& decay)
{
   // Zero histogram
   decay.assign(n_t, 0);
   
   GenerateDecay(tau, N, &decay[0]);
}

#endif
