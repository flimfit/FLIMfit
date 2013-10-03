//
//  FLIMSimulation.cpp
//  FLIMfit
//
//  Created by Sean Warren on 19/09/2013.
//
//

#include "FLIMSimulation.h"


using std::vector;

FLIMSimulation::FLIMSimulation() :
   irf_mu( 1000 ),
   irf_sigma( 150 ),
   n_t( 128 ),
   T( 12500 )
{
   // Generate the IRF distribution
   norm_dist = boost::random::normal_distribution<double>(irf_mu, irf_sigma);
   
   dt = T / n_t;
   
}



void FLIMSimulation::GenerateIRF(int N, vector<double>& decay)
{
   decay.assign(n_t, 0);
   
   // Generate decay histogram
   for(int i=0; i<N; i++)
   {
      double t_arrival = SampleIRF();
      
      // Determine which bin the sample falls in
      int idx = floor(t_arrival/dt);
      
      // Make sure we're not outside of the sample window
      if (idx >= 0 && idx<n_t)
         decay[idx]++;
      
   }
   
   // Normalise IRF
   double sum = 0;
   for(int i=0; i<n_t; i++)
       sum += decay[i];
   for(int i=0; i<n_t; i++)
       decay[i] /= sum;
   
}

double FLIMSimulation::SampleIRF()
{  
   return norm_dist(gen);
}

int FLIMSimulation::GetTimePoints(vector<double>& t, vector<double>& t_int)
{
   t.assign(n_t, 0);
   for (int i=0; i<n_t; i++) {
      t[i] = i*dt;
   }
 
   // TCSPC has equal integration times by definition
   t_int.assign(n_t, 1.0);
   
   return n_t;
}
