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

void ModelParameters::Validate()
{
   if (polarisation_resolved)
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