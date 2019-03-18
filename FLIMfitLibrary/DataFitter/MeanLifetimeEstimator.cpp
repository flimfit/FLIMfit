#include "MeanLifetimeEstimator.h"
#include "FlagDefinitions.h"
#include <cmath>

using namespace std;

MeanLifetimeEstimator::MeanLifetimeEstimator(std::shared_ptr<TransformedDataParameters> dp) :
   dp(dp)
{
   t_irf = dp->irf->calculateMean();
}


double MeanLifetimeEstimator::EstimateMeanLifetime(const std::vector<float>& decay, int data_type)
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
double MeanLifetimeEstimator::EstimateMeanLifetimeTCSPC(const std::vector<float>& decay)
{
   double t_mean = 0;
   double n = 0;

   int n_t = dp->n_t;
   std::shared_ptr<InstrumentResponseFunction> irf = dp->irf;
   auto& t = dp->getTimepoints();

   for (int i = 0; i<n_t; i++)
   {
      double c = decay[i]; //TODO: -adjust_buf[i];
      t_mean += c * t[i];
      n += c;
   }

   // If polarisation resolevd add perp decay using I = para + 2*g*perp
   /*
   if (dp->polarisation_resolved)
   {
      for (int i = start; i<n_t; i++)
      {
         t_mean += 2 * irf->g_factor * decay[i + n_t] * (t[i] - t[start]);
         n += 2 * irf->g_factor * decay[i + n_t];
      }
   }
   */
   
   t_mean = t_mean / n;

   // Apply correction for measurement window
   double T = t[n_t - 1];

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

   return tau - t_irf;
}

/*
   For widefield data, apply linearised model
*/
double MeanLifetimeEstimator::EstimateMeanLifetimeGated(const std::vector<float>& decay)
{
   double sum_t = 0;
   double sum_t2 = 0;
   double sum_tlnI = 0;
   double sum_lnI = 0;
   double dt;

   double log_di;
   
   int n_t = dp->n_t;
   auto& t = dp->getTimepoints();
   auto& t_int = dp->getGateIntegrationTimes();

   for (int i = 0; i<n_t; i++)
   {
      dt = t[i] - t_irf;

      sum_t += dt;
      sum_t2 += dt * dt;

      if (decay[i] > 0) // todo: add adjust_buf
         log_di = log(decay[i] / t_int[i]);
      else
         log_di = 0;

      sum_tlnI += dt * log_di;
      sum_lnI += log_di;

   }

   double tau = -(n_t * sum_t2 - sum_t * sum_t) / 
                 (n_t * sum_tlnI - sum_t * sum_lnI);

   return tau - t_irf;
}
