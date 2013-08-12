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

#include "RegionData.h"
#include <algorithm>

RegionData::RegionData(int n_px, int n_meas) :
   n_px_max(n_px_max),
   n_px_cur(0),
   n_meas(n_meas)
{
   data = new float[n_px_max * n_meas];
   irf_idx = new int[n_px];
}

RegionData::~RegionData()
{
   delete[] data;
   delete[] irf_idx;
}

void RegionData::Clear()
{
   n_px_cur = 0;
}

void RegionData::GetPointersForInsertion(int n, float*& y_, int*& irf_idx_)
{
   assert( n + n_px_cur <= n_px_max );

   data_    = data + n_px_cur * n_meas;
   irf_idx_ = irf_idx  + n_px_cur;

   n_px_cur += n;
}


void RegionData::GetPointersForArbitaryInsertion(int pos, int n, float*& y_, int*& irf_idx_)
{
   assert( n + pos <= n_px_max );

   data_    = data + pos * n_meas;
   irf_idx_ = irf_idx  + pos;

   n_px_cur = std::max(n_px_cur, pos + n);
}

void RegionData::GetAverageDecay(float* average_decay)
{
   memset(average_decay, 0, n_meas * sizeof(float));

   for(int i=0; i<n_px_cur; i++)
      for(int j=0; j<n_meas; j++)
         average_decay[j] += data[i*n_meas + j];
      
   for(int j=0; j<n_meas; j++)
      average_decay[j] /= n_px_cur;
}

int RegionData::GetPointers(float*& y, int*& irf_idx);