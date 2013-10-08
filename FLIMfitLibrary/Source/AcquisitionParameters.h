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

#ifndef _ACQUISITIONPARAMETERS_H
#define _ACQUISITIONPARAMETERS_H

#include <vector>

using std::vector;

class AcquisitionParameters
{
public:

   AcquisitionParameters(int data_type, int polarisation_resolved, int n_chan, int n_t_full, int n_t, double t[], double t_int[], int t_skip[], double t_rep, double counts_per_photon);

   int data_type;
   int polarisation_resolved;

   int n_t;
   int n_t_full;
   int n_chan;
   
   double  counts_per_photon;
   double  t_rep;
   
   vector<int> t_skip;
   vector<double> t;
   vector<double> t_int;
   vector<double> tvb_profile;

   double* GetT();

   // Computed parameters
   int n_meas;

};

#endif