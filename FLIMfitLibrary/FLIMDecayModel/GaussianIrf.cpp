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

#include "GaussianIrf.h"
#include "GaussianIrfConvolver.h"

#include <algorithm>
#include <cmath>
#include <cassert>

std::shared_ptr<AbstractConvolver> GaussianIrf::getConvolver(std::shared_ptr<TransformedDataParameters> dp)
{
   return std::make_shared<GaussianIrfConvolver>(dp);
}

GaussianIrf::GaussianIrf(const std::vector<GaussianParameters>& gaussian_params_)
{
   gaussian_params = gaussian_params_;

   n_chan = (int)gaussian_params.size();
   g_factor.resize(n_chan);
}

GaussianIrf::GaussianIrf(const GaussianParameters& gaussian_params_)
{
   gaussian_params.push_back(gaussian_params_);

   n_chan = 1;
   g_factor.resize(n_chan);
}

double GaussianIrf::calculateMean()
{
   return gaussian_params[0].mu;
}
