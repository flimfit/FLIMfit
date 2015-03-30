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

#ifndef _IRFCONV_H
#define _IRFCONV_H

//void alf2beta(int n, const double* alf, double beta[]);
//double beta_derv(int n_beta, int alf_idx, int beta_idx, const double alf[]);

#include <cmath>

template <typename T>
void alf2beta(int n, const T* alf, double beta[])
{
   // For example if there are four components
   // beta[0] =                              alf[0] 
   // beta[1] =                 alf[1]  * (1-alf[0])
   // beta[2] =    alf[2]  * (1-alf[1]) * (1-alf[0])
   // beta[3] = (1-alf[2]) * (1-alf[1]) * (1-alf[0])

   for(int i=0; i<n; i++)
      beta[i] = 1;

   for(int i=0; i<n-1; i++)
   {
      beta[i] *= alf[i];
      for(int j=i+1; j<n; j++)
         beta[j] *= 1-alf[i];
   }

}

template <typename T>
T alf2beta(int n, const T* alf, int j)
{
   T beta = 1;
   for(int i=0; i<(j-1); i++)
      beta *= (1-alf[i]);
   
   if ( j == (n-1) )
      beta *= (1-alf[j-1]);
   else
      beta *= alf[j];

   return beta;
}

template <typename T>
double beta_derv(int n_beta, int alf_idx, int beta_idx, const T alf[])
{
   double d;

   if(beta_idx<=alf_idx)
      d = 1;
   else if (beta_idx<n_beta-1)
      d = -alf[beta_idx];
   else
      d = -1;

   for(int k=0; k<(beta_idx-1); k++)
   {
      d *= (1-alf[k]);
   }

   return d;
}




inline double anscombe(double x)
{
   return 2 * sqrt(x + 0.375);
}

inline double inv_anscombe(double x)
{
   return x*x*0.25 - 0.375;
}

inline double anscombe_diff(double x)
{
   return 1 / sqrt(x + 0.375);
}



#endif
