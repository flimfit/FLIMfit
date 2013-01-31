//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================


#include "util.h"
#include "omp_stub.h"

#include <stdio.h>

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

int _CrtCheckMemory( )
{ return 0; };

#ifndef USE_OMP

int omp_get_thread_num()
{
   return 0;
}

void omp_set_num_threads(int num_threads)
{
   return;
}

#endif