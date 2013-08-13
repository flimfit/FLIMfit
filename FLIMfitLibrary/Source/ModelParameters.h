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

#ifndef _MODELPARAMETERS_H
#define _MODELPARAMETERS_H

class ModelParameters
{
public:

   void Validate();

protected:

   // Timegates
   int     n_t; 
   double *t;
   
   int data_type;
   
   // Instrument response function
   int     n_irf; 
   double *t_irf; 
   double *irf; 
   double  pulse_pileup;
   
   // Intensity decay
   int     n_exp; 
   int     n_fix; 
   double *tau_min; 
   double *tau_max;
   double *tau_guess;
 
   int     estimate_initial_tau; 
  
   // FRET model
   int fit_fret; 
   int n_fret; 
   int n_fret_fix;
   int inc_donor; 
   double *E_guess; 

   
   int     fit_beta; 
   double *fixed_beta;
   
   // Stray light parameters
   int     fit_offset; 
   int     fit_scatter;
   int     fit_tvb;  
   double  offset_guess; 
   double  scatter_guess;
   double  tvb_guess;
   double *tvb_profile;

   int     fit_t0; double t0_guess; 

  
   int pulsetrain_correction; double t_rep;
   int ref_reconvolution; double ref_lifetime_guess;

   // Anisotropy model
   int n_theta; 
   int n_theta_fix; 
   int inc_rinf;
   double *theta_guess;



   bool polarisation_resolved;


};

#endif
