#include "util.h"

void SetNaN(double* var, int n)
{
   unsigned long nan_l[2]={0xffffffff, 0x7fffffff};
   double nan = *( double* )nan_l;

   if (var != NULL)
      for(int i=0; i<n; i++)
         var[i] = nan;
}


void SetNaN(float* var, int n)
{
   unsigned long nan_l[1] = {0x7fffffff};
   float nan = *( float* ) nan_l;

   if (var != NULL)
      for(int i=0; i<n; i++)
         var[i] = nan;
}
