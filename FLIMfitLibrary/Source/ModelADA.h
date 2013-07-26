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

#ifndef _MODELADA_H
#define _MODELADA_H

#include "FlagDefinitions.h"

#define T_FACTOR  1


double TransformRange(double v, double v_min, double v_max);
double InverseTransformRange(double t, double v_min, double v_max);
double TransformRangeDerivative(double v, double v_min, double v_max);

double kappa_spacer(double tau2, double tau1);
double kappa_lim(double tau);

extern "C"
void updatestatus_(int* gc, int* thread, int* iter, float* chi2, int* terminate);


#endif
