//
//  FLIMSimulation.h
//  FLIMfit
//
//  Created by Sean Warren on 19/09/2013.
//
//

#pragma once

#include "AcquisitionParameters.h"
#include "InstrumentResponseFunction.h"

#include <boost/random/mersenne_twister.hpp>
#include <boost/random/lagged_fibonacci.hpp>
#include <boost/random/normal_distribution.hpp>
#include <boost/random/exponential_distribution.hpp>
#include <boost/random/poisson_distribution.hpp>
#include <time.h>

#include <numeric>
#include <vector>

const double t_rep_default = 12500.0;

class FLIMSimulation : public AcquisitionParameters
{
public:
   FLIMSimulation(int data_type, int n_chan = 1);
   
   template <class U>
   void GenerateDecay(double tau, int N, std::vector<U>& decay);

   template <class U>
   void GenerateImage(double tau, int N, int chan, std::vector<U>& decay);
   
   template <class U>
   void GenerateImage(double tau, int N, int chan, U* decay);

   template <class U>
   void GenerateImageBackground(int N, U* decay);

   std::shared_ptr<InstrumentResponseFunction> GenerateIRF(int N);
   std::shared_ptr<InstrumentResponseFunction> GetGaussianIRF();

   GaussianParameters getIrfParameters() { return irf; };

protected:

   double SampleIRF();

   int mode;
   
   // IRF properties
   GaussianParameters irf;

   double dt;
   
   virtual void GenerateDecay(double tau, int N, std::vector<int>& decay) = 0;
   virtual void GenerateIRF_(int N, std::vector<double>& decay) = 0;

   boost::lagged_fibonacci44497 gen;
   boost::random::normal_distribution<double> norm_dist;
};



class FLIMSimulationTCSPC : public FLIMSimulation
{
public:
   FLIMSimulationTCSPC(int n_chan = 1);

   int GetTimePoints(std::vector<double>& t, std::vector<double>& t_int);

protected:
   void GenerateDecay(double tau, int N, std::vector<int>& decay);
   void GenerateIRF_(int N, std::vector<double>& decay);

};


class FLIMSimulationWF : public FLIMSimulation
{
public:
   FLIMSimulationWF();


protected:
   void GenerateDecay(double tau, int N, std::vector<int>& decay);
   void GenerateIRF_(int N, std::vector<double>& decay);

   double gate_width;
   double n_t_irf;
};


template <class U>
void FLIMSimulation::GenerateImage(double tau, int N, int chan, std::vector<U>& decay)
{
   decay.resize(n_meas_full * n_x * n_y);
   GenerateImage(tau, N, decay.data());
}

template <class U>
void FLIMSimulation::GenerateImage(double tau, int N, int chan, U* decay)
{
   #pragma omp parallel for
   for(int x=0; x<n_x; x++)
   {
      std::vector<int> buf(n_t_full);
      for(int y=0; y<n_y; y++)
      {
         int pos = y + n_y*x;
         GenerateDecay(tau, N, buf); 
         for(int i=0; i<n_t_full; i++)
            decay[(pos * n_chan + chan) * n_t_full + i] += (U) buf[i];
      }
   }
}

template <class U>
void FLIMSimulation::GenerateImageBackground(int N, U* decay)
{
   boost::random::poisson_distribution<int> poisson_dist(N);

   for (int x = 0; x < n_x; x++)
   {
      for (int y = 0; y < n_y; y++)
      {
         int pos = y + n_y*x;
         for (int i = 0; i < n_meas_full; i++)
            decay[pos * n_meas_full + i] += (U) poisson_dist(gen);
      }
   }
}


template <class U>
void FLIMSimulation::GenerateDecay(double tau, int N, std::vector<U>& decay)
{

   // Zero histogram
   decay.assign(n_t_full, 0);

   std::vector<int> buf(n_t_full);
   GenerateDecay(tau, N, buf);

   for (int i = 0; i<n_t_full; i++)
      decay[i] = (U)buf[i];

}

