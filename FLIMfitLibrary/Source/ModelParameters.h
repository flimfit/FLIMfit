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

#include "FLIMGlobalAnalysis.h"

class ModelParameters : public ModelParametersStruct
{

public:

   ModelParameters();

   void Validate();
   ModelParametersStruct GetStruct();

   int SetDecay(int n_exp, int n_fix, double tau_min[], double tau_max[], double tau_guess[], int fit_beta, double fixed_beta[]);
   int SetDecayGroups(int decay_group[]);
   int SetStrayLight(int fit_offset, double offset_guess, int fit_scatter, double scatter_guess, int fit_tvb, double tvb_guess);
   int SetFRET(int n_fret, int n_fret_fix, int inc_donor, double E_guess[]);
   int SetAnisotropy(int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[]);
   int SetPulseTrainCorrection(int pulsetrain_correction);
};

#endif
