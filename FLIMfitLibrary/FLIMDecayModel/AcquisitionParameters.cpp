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

AcquisitionParameters::AcquisitionParameters(int data_type, int polarisation_resolved, int n_chan, int n_t_full, int n_t, double t_[], double t_int_[], int t_skip_[], double t_rep, double counts_per_photon) :
   data_type(data_type),
   polarisation_resolved(polarisation_resolved),
   n_chan(n_chan),
   n_t_full(n_t_full),
   n_t(n_t),
   t_rep(t_rep),
   counts_per_photon(counts_per_photon)
{
   t_skip.assign(n_chan, 0);
 
   SetT(n_t_full, n_t, t_, t_int_, t_skip_);
}


AcquisitionParameters::AcquisitionParameters(int data_type, int polarisation_resolved, int n_chan, double t_rep, double counts_per_photon) :
   data_type(data_type),
   polarisation_resolved(polarisation_resolved),
   n_chan(n_chan),
   t_rep(t_rep),
   counts_per_photon(counts_per_photon)
{
   t_skip.assign(n_chan, 0);
  
   n_t_full = 0;
   n_t      = 0;

   n_meas_full = 0;
   n_meas      = 0;
}

void AcquisitionParameters::SetT(vector<double>& t_)
{
   t = t_;

   n_t_full = t.size();
   n_t = n_t_full;
   t_int.assign(n_t_full, 1);

   for(int i=0; i<n_chan; i++)
      t_skip[i] = 0;

   n_meas      = n_chan * n_t;
   n_meas_full = n_chan * n_t_full;

   CheckGateSpacing();
}


void AcquisitionParameters::SetT(vector<double>& t_, double t_min, double t_max)
{
   SetT(t_);

   int skip = 0;

   for(int i=0; i<n_t_full; i++)
   {
      if (t[i] < t_min)
      {
         skip = i;
      }
      if (t[i] > t_max && i > skip) // ensure we have at least one point
      {
         n_t = i - skip;
         break;
      }
   }

   // If an invalid t_min was specified pull out the first gate
   if (skip == n_t_full)
   {
      skip = 0;
      n_t = 1;
   }

   for(int i=0; i<n_chan; i++)
      t_skip[i] = skip;

   n_meas = n_chan * n_t;

   CheckGateSpacing();
}

void AcquisitionParameters::SetT(int n_t_full, int n_t, double t_[], double t_int_[], int t_skip_[])
{

   n_meas      = n_chan * n_t;
   n_meas_full = n_chan * n_t_full;

   if (t_skip_ != NULL)
   {
      for(int i=0; i<n_chan; i++)
         t_skip[i] = t_skip_[i];
   }

   // Copy t and t_int
   t.resize(n_t);
   t_int.resize(n_t);

   int i0 = t_skip[0];
   for(int i=0; i<n_t; i++)
   {
      t[i] = t_[i + i0];
      t_int[i] = t_int_[i + i0];
   }

   CheckGateSpacing();
}

void AcquisitionParameters::SetIRF(shared_ptr<InstrumentResponseFunction> irf_)
{
   irf = irf_;
   CalculateIRFMax();
}


void AcquisitionParameters::SetIntegrationTimes(vector<double>& t_int_)
{
   assert( t_int.size() == n_t_full );
   t_int = t_int_;
}

double* AcquisitionParameters::GetT()
{
   return &t[0];
}

void AcquisitionParameters::CheckGateSpacing()
{
   // Check to see if gates are equally spaced
   //---------------------------------------------
   equally_spaced_gates = true;
   double dt0 = t[1] - t[0];
   for (int i = 2; i<n_t; i++)
   {
      double dt = t[i] - t[i - 1];
      if (abs(dt - dt0) > 1)
      {
         equally_spaced_gates = false;
         break;
      }

   }
}

void AcquisitionParameters::CalculateIRFMax()
{
   irf_max.assign(n_meas, 0);

   double t0 = irf->GetT0();
   double dt_irf = irf->timebin_width;
   int n_irf = irf->n_irf;

   for (int j = 0; j<n_chan; j++)
   {
      for (int i = 0; i<n_t; i++)
      {
         int k = 0;
         while (k < n_irf && (t[i] - t0 - k*dt_irf) >= -1.0)
         {
            irf_max[j*n_t + i] = k + j*n_irf;
            k++;
         }
      }
   }

}