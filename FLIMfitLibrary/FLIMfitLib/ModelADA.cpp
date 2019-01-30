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


#include "ModelADA.h"
#include "FitController.h"
#include "IRFConvolution.h"

#define PI        3.141592654
#define halfPI    1.570796327
#define invPI     0.318309886

double TransformRange(double v, double v_min, double v_max)
{
   return v;
//   return log(v);

   double diff = v_max - v_min;
   return tan( PI*(v-v_min)/diff - halfPI );
}

double InverseTransformRange(double t, double v_min, double v_max)
{
   return t;
//   return exp(t);

   double diff = v_max - v_min;
   return invPI*diff*( atan(t) + halfPI ) + v_min;
}

double TransformRangeDerivative(double v, double v_min, double v_max)
{
   return 1;
//   return v;

   double t = TransformRange(v,v_min,v_max);
   double diff = v_max - v_min;
   return invPI*diff/(t*t+1);
}
/*
double tau2alf(double tau, double tau_min, double tau_max)
{
   return tau;

   double diff = tau_max - tau_min;
   return tan( PI*(tau-tau_min)/diff - halfPI );
}

double alf2tau(double alf, double tau_min, double tau_max)
{
   return alf;

   double diff = tau_max - tau_min;
   return invPI*diff*( atan(alf) + halfPI ) + tau_min;
}

double d_tau_d_alf(double tau, double tau_min, double tau_max)
{
   return 1;

   double alf = tau2alf(tau,tau_min,tau_max);
   double diff = tau_max - tau_min;
   return invPI*diff/(alf*alf+1);
}

double beta2alf(double beta)
{
   return beta; //log(beta);
}

double alf2beta(double alf)
{
   return alf; //exp(alf);
}

double d_beta_d_alf(double beta)
{
   return 1; //beta;
}
*/

double kappa_spacer(double tau2, double tau1)
{
  //return 0; 

   double diff_max = 30;
   double spacer = 50;

   double diff = tau2 - tau1 + spacer;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}

double kappa_lim(double tau)
{
   //return 0;

   double diff_max = 30;
   double tau_min = 50;

   double diff = - tau + tau_min;

   diff = diff > diff_max ? diff_max : diff;
   double kappa = exp(diff);
   return kappa;
}
/*
void updatestatus_(int* gc_int, int* thread, int* iter, float* chi2, int* terminate)
{
   FitController* gc= (FitController*) gc_int;
   int t = gc->status->UpdateStatus(*thread, -1, *iter, *chi2);
   *terminate = t;
}
 */
