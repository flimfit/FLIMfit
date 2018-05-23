//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================


#include "util.h"
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

/*
double NaN()
{
   unsigned long nan_l[2]={0xffffffff, 0x7fffffff};
   return *((double*)nan_l);

}
*/

//int _CrtCheckMemory( )
//{ return 0; };

/*
#ifndef USE_OMP

int omp_get_thread_num()
{
   return 0;
}

void omp_set_num_threads(int num_threads)
{
   return;
}

int omp_get_num_threads()
{
    return 1;
}

#endif
*/