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

#include "ModelParameters.h"
#include "FlagDefinitions.h"

#include <algorithm>


ModelParameters::ModelParameters()
{

   // Decay
   n_exp = 1;
   n_fix = 1;

   tau_min[0]   = 0;
   tau_max[0]   = 10e4;
   tau_guess[0] = 2000;

   fit_beta    = FIT_LOCALLY; 

   // FRET 
   fit_fret    = false;
   n_fret      = 0;
   n_fret_fix  = 0;
   inc_donor   = true;
     
   // Anisotropy 
   n_theta     = 0; 
   n_theta_fix = 0; 
   inc_rinf    = false;

   // Stray light
   fit_offset  = FIX;
   fit_scatter = FIX;
   fit_tvb     = FIX;
   
   offset_guess  = 0;
   scatter_guess = 0;
   tvb_guess     = 0;

   pulsetrain_correction = false;
   
}

ModelParameters::ModelParameters(ModelParametersStruct& params_) :
   ModelParametersStruct(params_)
{
   Validate();
}

// TODO: real validation here

void ModelParameters::Validate()
{

   if (n_theta > 0)
   {
      if (fit_beta == FIT_LOCALLY)
         fit_beta = FIT_GLOBALLY;

      if (n_fret > 0)
         n_fret = 0;
   }

   // Set up FRET parameters
   //---------------------------------------
   fit_fret = (n_fret > 0) & (fit_beta != FIT_LOCALLY);
   if (!fit_fret)
   {
      n_fret = 0;
      n_fret_fix = 0;
      inc_donor = true;
   }
   else
      n_fret_fix = std::min(n_fret_fix,n_fret);
}

int ModelParameters::SetDecay(int n_exp, int n_fix, double tau_min[], double tau_max[], double tau_guess[], int fit_beta, double fixed_beta[])
{
   this->n_exp = n_exp;
   this->n_fix = n_fix;
   this->n_decay_group = n_decay_group;
   this->fit_beta = fit_beta;
   
   n_decay_group = 1;

   for(int i=0; i<n_exp; i++)
   {
      this->tau_min[i]     = tau_min[i];
      this->tau_max[i]     = tau_max[i];
      this->tau_guess[i]   = tau_guess[i];
      this->decay_group[i] = 0;
   }

   // TODO - put this in seperate function?
   if (fixed_beta)
   {
      for(int i=0; i<n_exp; i++)
      {
         this->fixed_beta[i]  = fixed_beta[i];
      }
   }


   return SUCCESS;
}

int ModelParameters::SetDecayGroups(int decay_group[])
{
   bool modified_groups = false;

   // Check to make sure that decay groups increase contiguously from zero
   int cur_group = 0;
   for(int i=0; i<n_exp; i++)
   {
      if (decay_group[i] == (cur_group + 1))
      {
         cur_group++;
      }
      else if (decay_group[i] != cur_group)
      {
         decay_group[i] = cur_group;
         modified_groups = true;
      }
   }

   n_decay_group = decay_group[n_exp-1];

   for(int i=0; i<n_exp; i++)
   {
      this->decay_group[i] = decay_group[i];
   }

   if (modified_groups)
      return WARN_DECAY_GROUPS_NOT_CONSISTENT;
   else
      return SUCCESS;
}

int ModelParameters::SetStrayLight(int fit_offset, double offset_guess, int fit_scatter, double scatter_guess, int fit_tvb, double tvb_guess)
{
   this->fit_offset = fit_offset;
   this->fit_scatter = fit_scatter;
   this->fit_tvb = fit_tvb;

   this->offset_guess = offset_guess;
   this->scatter_guess = scatter_guess;
   this->tvb_guess = tvb_guess;

   return SUCCESS;
}

int ModelParameters::SetFRET(int n_fret, int n_fret_fix, int inc_donor, double E_guess[])
{
   this->n_fret = n_fret;
   this->n_fret_fix = n_fret_fix;
   this->inc_donor = inc_donor;

   for(int i=0; i<n_fret; i++)
      this->E_guess[i] = E_guess[i];

   return SUCCESS;
}

int ModelParameters::SetAnisotropy(int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[])
{
   this->n_theta = n_theta;
   this->n_theta_fix = n_theta_fix;
   this->inc_rinf = inc_rinf;

   for(int i=0; i<n_exp; i++)
   {
      this->theta_guess[i] = theta_guess[i];
   }

   return SUCCESS;
}

int ModelParameters::SetPulseTrainCorrection(int pulsetrain_correction_)
{
   pulsetrain_correction = pulsetrain_correction_;

   return SUCCESS;
}


ModelParametersStruct ModelParameters::GetStruct()
{
   return (ModelParametersStruct) *this;
}