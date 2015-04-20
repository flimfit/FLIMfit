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

#pragma once

#include "InstrumentResponseFunction.h"
#include <vector>
#include <memory>
using std::shared_ptr;
using std::vector;


class AcquisitionParameters
{
public:

   AcquisitionParameters(int data_type = 0, double t_rep = 12500.0, int polarisation_resolved = false, int n_chan = 1, double counts_per_photon = 1);
  
   void SetIRF(shared_ptr<InstrumentResponseFunction> irf);
   void SetT(int n_t_full, int n_t, double t_[], double t_int_[], int t_skip_[]);
   
   void SetT(vector<double>& t_, double t_min, double t_max);
   void SetT(vector<double>& t_);
   void SetIntegrationTimes(vector<double>& t_int_);
   
   double* GetT();

   int data_type;
   int polarisation_resolved;

   int n_t;
   int n_t_full;
   int n_chan;
   
   double  counts_per_photon;
   double  t_rep;
   
   vector<int>    t_skip;
   vector<double> t;
   vector<double> t_int;
   vector<double> tvb_profile;

   shared_ptr<InstrumentResponseFunction> irf;

   // Computed parameters
   int n_meas;
   int n_meas_full;
   bool equally_spaced_gates;
   vector<int> irf_max;

protected:

   void CheckGateSpacing();
   void CalculateIRFMax();
};