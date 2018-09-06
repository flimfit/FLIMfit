
#define PI        3.141592654
#define halfPI    1.570796327
#define invPI     0.318309886

#include <cmath>

double kappaSpacer(double tau2, double tau1)
{
  //return 0; 

   double diff_max = 30;
   double spacer = 50;

   double diff = tau2 - tau1 + spacer;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double kappaLim(double tau)
{
   //return 0;

   double diff_max = 30;
   double tau_min = 5;

   double diff = - tau + tau_min;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double transformRange(double v, double v_min, double v_max)
{
   return v;
//   return log(v);

   double diff = v_max - v_min;
   return tan( PI*(v-v_min)/diff - halfPI );
}

double inverseTransformRange(double t, double v_min, double v_max)
{
   return t;
//   return exp(t);

   double diff = v_max - v_min;
   return invPI*diff*( atan(t) + halfPI ) + v_min;
}

double transformRangeDerivative(double v, double v_min, double v_max)
{
   return 1;
//   return v;

   double t = transformRange(v,v_min,v_max);
   double diff = v_max - v_min;
   return invPI*diff/(t*t+1);
}