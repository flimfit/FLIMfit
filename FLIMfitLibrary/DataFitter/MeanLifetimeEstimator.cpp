#include "MeanLifetimeEstimator.h"
#include "FlagDefinitions.h"
#include <cmath>

using namespace std;

MeanLifetimeEstimator::MeanLifetimeEstimator(shared_ptr<AcquisitionParameters> acq) :
   acq(acq)
{
   DetermineStartPosition(0);
}


/*
   Determine which data should be used when we're calculating the average lifetime for an initial guess.
   Since we won't take the IRF into account we need to only use data after the gate is mostly closed.
*/
int MeanLifetimeEstimator::DetermineStartPosition(int idx)
{
   int j_last = 0;
   start = 0;

   shared_ptr<InstrumentResponseFunction> irf = acq->irf;
   int n_meas = acq->n_meas;
   int n_t = acq->n_t;
   int n_irf = irf->n_irf;

   vector<double> storage(n_meas);
   double *lirf = irf->GetIRF(idx, 0, storage.data());
   double t_irf0 = irf->GetT0();
   double dt_irf = irf->timebin_width;



   //===================================================
   // If we have a scatter IRF use data after cumulative sum of IRF is
   // 95% of total sum (so we ignore any potential tail etc)
   //===================================================
   if (!(irf->type == Reference))
   {
      // Determine 95% of IRF
      double irf_95 = 0;
      for (int i = 0; i<n_irf; i++)
         irf_95 += lirf[i];
      irf_95 *= 0.95;

      // Cycle through IRF to find time at which cumulative IRF is 95% of sum.
      // Once we get there, find the time gate in the data immediately after this time
      double c = 0;
      for (int i = 0; i<n_irf; i++)
      {
         c += lirf[i];
         if (c >= irf_95)
         {
            for (int j = j_last; j<n_t; j++)
               if (acq->t[j] > t_irf0 + i*dt_irf)
               {
                  start = j;
                  j_last = j;
                  break;
               }
            break;
         }
      }
   }

   //===================================================
   // If we have reference IRF, use data after peak of reference which should roughly
   // correspond to end of gate
   //===================================================
   else
   {
      // Cycle through IRF, if IRF is larger then previously seen find the find the 
      // time gate in the data immediately after this time. Repeat until end of IRF.
      double c = 0;
      for (int i = 0; i<n_irf; i++)
      {
         if (lirf[i] > c)
         {
            c = lirf[i];
            for (int j = j_last; j<n_t; j++)
               if (acq->t[j] > t_irf0 + i*dt_irf)
               {
                  start = j;
                  j_last = j;
                  break;
               }
         }
      }
   }


   return start;
}


double MeanLifetimeEstimator::EstimateMeanLifetime(const vector<float>& decay, int data_type)
{
   if (data_type == DATA_TYPE_TCSPC)
      return EstimateMeanLifetimeTCSPC(decay);
   else
      return EstimateMeanLifetimeGated(decay);
}

/*
   For TCSPC data, calculate the mean arrival time and apply a correction for
   the data censoring (i.e. finite measurement window)
*/
double MeanLifetimeEstimator::EstimateMeanLifetimeTCSPC(const vector<float>& decay)
{
   double t_mean = 0;
   double n = 0;

   int n_meas = acq->n_meas;
   int n_t = acq->n_t;
   shared_ptr<InstrumentResponseFunction> irf = acq->irf;

   for (int i = start; i<acq->n_t; i++)
   {
      double c = decay[i]; //TODO: -adjust_buf[i];
      t_mean += c * (acq->t[i] - acq->t[start]);
      n += c;
   }

   // If polarisation resolevd add perp decay using I = para + 2*g*perp
   if (acq->polarisation_resolved)
   {
      for (int i = start; i<n_t; i++)
      {
         t_mean += 2 * irf->g_factor * decay[i + n_t] * (acq->t[i] - acq->t[start]);
         n += 2 * irf->g_factor * decay[i + n_t];
      }
   }

   t_mean = t_mean / n;

   // Apply correction for measurement window
   double T = acq->t[n_t - 1] - acq->t[start];

   // Older iterative correction; tends to same value more slowly
   //tau = t_mean;
   //for(int i=0; i<10; i++)
   //   tau = t_mean + T / (exp(T/tau)-1);

   t_mean /= T;
   double tau = t_mean;

   // Newton-Raphson update
   for (int i = 0; i<3; i++)
   {
      double e = exp(1 / tau);
      double iem1 = 1 / (e - 1);
      tau = tau - (-tau + t_mean + iem1) / (e * iem1 * iem1 / (tau*tau) - 1);
   }
   tau *= T;

   return tau;
}

/*
   For widefield data, apply linearised model
*/
double MeanLifetimeEstimator::EstimateMeanLifetimeGated(const vector<float>& decay)
{
   double sum_t = 0;
   double sum_t2 = 0;
   double sum_tlnI = 0;
   double sum_lnI = 0;
   double dt;
   int    N;

   double log_di;
   
   int n_t = acq->n_t;
   N = n_t - start;

   for (int i = start; i<n_t; i++)
   {
      dt = acq->t[i] - acq->t[start];

      sum_t += dt;
      sum_t2 += dt * dt;

      if (decay[i] > 0) // todo: add adjust_buf
         log_di = log(decay[i] / acq->t_int[i]);
      else
         log_di = 0;

      sum_tlnI += dt * log_di;
      sum_lnI += log_di;

   }

   double tau = -(N * sum_t2 - sum_t * sum_t) / 
                 (N * sum_tlnI - sum_t * sum_lnI);

   return tau;
}