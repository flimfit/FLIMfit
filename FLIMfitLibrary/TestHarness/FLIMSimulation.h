//
//  FLIMSimulation.h
//  FLIMfit
//
//  Created by Sean Warren on 19/09/2013.
//
//

#ifndef FLIMfit_FLIMSimulation_h
#define FLIMfit_FLIMSimulation_h

#include "AcquisitionParameters.h"
#include "InstrumentResponseFunction.h"

#include <boost/random/mersenne_twister.hpp>
#include <boost/random/normal_distribution.hpp>
#include <boost/random/exponential_distribution.hpp>
#include <boost/random/poisson_distribution.hpp>
#include <time.h>

#include <numeric>
#include <vector>

using std::vector;


const double t_rep_default = 12500.0;

class FLIMSimulation : public AcquisitionParameters
{
public:
   FLIMSimulation(int data_type);
   
   template <class U>
   void GenerateDecay(double tau, int N, vector<U>& decay);

   template <class U>
   void GenerateImage(double tau, int N, int n_x, int n_y, vector<U>& decay);
   
   InstrumentResponseFunction GenerateIRF(int N);
  
protected:

   double SampleIRF();

   int mode;
   
   // IRF properties
   double irf_mu;
   double irf_sigma;

   double dt;

   
   virtual void GenerateDecay(double tau, int N, vector<int>& decay) = 0;
   virtual void GenerateIRF(int N, vector<double>& decay) = 0;

   boost::mt19937 gen;
   boost::random::normal_distribution<double> norm_dist;
};



class FLIMSimulationTCSPC : public FLIMSimulation
{
public:
   FLIMSimulationTCSPC();

   void GenerateIRF(int N, vector<double>& decay);
   int GetTimePoints(vector<double>& t, vector<double>& t_int);

private:
   void GenerateDecay(double tau, int N, vector<int>& decay);

};


class FLIMSimulationWF : public FLIMSimulation
{
public:
   FLIMSimulationWF();

   void GenerateIRF(int N, vector<double>& decay);

private:
   void GenerateDecay(double tau, int N, vector<int>& decay);

   double gate_width;

   double n_t_irf;
   
};


template <class U>
void FLIMSimulation::GenerateImage(double tau, int N, int n_x, int n_y, vector<U>& decay)
{
//   decay.assign(n_t * n_x * n_y, 0);
   decay.resize(n_t_full * n_x * n_y);

   vector<int> buf(n_t_full);
   GenerateDecay(tau, N, buf);

   for(int x=0; x<n_x; x++)
   {
      for(int y=0; y<n_y; y++)
      {
         int pos = y + n_y*x;
         GenerateDecay(tau, N, buf); 
         for(int i=0; i<n_t_full; i++)
            decay[pos * n_t_full + i] += (U) buf[i];
      }
   }
}

template <class U>
void FLIMSimulation::GenerateDecay(double tau, int N, vector<U>& decay)
{
   
   // Zero histogram
   decay.assign(n_t_full, 0);

   vector<int> buf(n_t_full);
   GenerateDecay(tau, N, buf);

   for(int i=0; i<n_t_full; i++)
      decay[i] = (U) buf[i];

}

#endif


