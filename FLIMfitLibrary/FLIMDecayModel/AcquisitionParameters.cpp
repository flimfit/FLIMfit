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

#include "AcquisitionParameters.h"

#include <cassert>
#include <cmath>

AcquisitionParameters::AcquisitionParameters(int data_type, double t_rep, int polarisation_resolved, int n_chan , double counts_per_photon) :
   data_type(data_type),
   polarisation_resolved(polarisation_resolved),
   n_chan(n_chan),
   t_rep(t_rep),
   counts_per_photon(counts_per_photon)
{
   n_t_full = 0;
   n_meas_full = 0;
}

void AcquisitionParameters::setT(const std::vector<double>& t_)
{
   t = t_;

   n_t_full = (int) t.size();
   t_int.assign(n_t_full, 1);

   n_meas_full = n_chan * n_t_full;

   checkGateSpacing();
}


void AcquisitionParameters::setT(int n_t_full, double t_[], double t_int_[])
{
   n_meas_full = n_chan * n_t_full;

   // Copy t and t_int
   t.resize(n_t_full);
   t_int.resize(n_t_full);

   for(int i=0; i<n_t_full; i++)
   {
      t[i] = t_[i];
      t_int[i] = t_int_[i];
   }

   checkGateSpacing();
}

void AcquisitionParameters::setImageSize(int n_x_, int n_y_)
{
   n_x = n_x_;
   n_y = n_y_;

   n_px = n_x * n_y;
}


void AcquisitionParameters::setIntegrationTimes(std::vector<double>& t_int_)
{
   assert( t_int.size() == n_t_full );
   t_int = t_int_;
}

double* AcquisitionParameters::getT()
{
   return &t[0];
}

const std::vector<double>& AcquisitionParameters::getTimePoints()
{
   return t;
}


void AcquisitionParameters::checkGateSpacing()
{
   // Check to see if gates are equally spaced
   //---------------------------------------------
   equally_spaced_gates = true;
   double dt0 = t[1] - t[0];
   for (int i = 2; i<n_t_full; i++)
   {
      double dt = t[i] - t[i - 1];
      if (fabs(dt - dt0) > 1)
      {
         equally_spaced_gates = false;
         break;
      }

   }
}
