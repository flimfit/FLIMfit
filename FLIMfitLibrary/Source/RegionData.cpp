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
#include <cassert>
#include <string.h>

RegionData::RegionData() :
   n_px_max(0),
   n_px_cur(0),
   n_meas(0),
   is_shallow_ptr(false)
{
}

RegionData::RegionData(int n_px, int n_meas) :
   n_px_max(n_px_max),
   n_px_cur(0),
   n_meas(n_meas),
   is_shallow_ptr(false)
{
   data = new float[n_px_max * n_meas];
   irf_idx = new int[n_px];
}

RegionData::~RegionData()
{
   if (!is_shallow_ptr)
   {
      delete[] data;
      delete[] irf_idx;
   }
}

void RegionData::Clear()
{
   n_px_cur = 0;
}

void RegionData::GetPointersForInsertion(int n, float*& data_, int*& irf_idx_)
{
   assert( n + n_px_cur <= n_px_max );

   data_    = data + n_px_cur * n_meas;
   irf_idx_ = irf_idx  + n_px_cur;

   n_px_cur += n;
}


void RegionData::GetPointersForArbitaryInsertion(int pos, int n, float*& data_, int*& irf_idx_)
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

void RegionData::GetPointers(float*& data, int*& irf_idx)
{
   data = this->data;
   irf_idx = this->irf_idx;
}

int RegionData::GetSize()
{
   return n_px_cur;
}

const RegionData RegionData::GetPixel(int px)
{
   return RegionData(this, px);
}


RegionData::RegionData(RegionData* region, int px) : 
   n_px_max(1),
   n_px_cur(1),
   is_shallow_ptr(true)
{
   data    = region->data + px * n_meas;
   irf_idx = region->irf_idx + px;
   n_meas  = region->n_meas;
}

const RegionData RegionData::GetBinnedRegion()
{
   RegionData binned_region(1, n_meas);

   float* binned_data;
   int*   binned_irf_idx;

   binned_region.GetPointersForInsertion(1, binned_data, binned_irf_idx);

   GetAverageDecay(binned_data);
   binned_irf_idx[0] = 0;

   return binned_region;
}

RegionData& RegionData::operator=( const RegionData& other ) 
{
   is_shallow_ptr = true;
   
   n_px_max = other.n_px_max;
   n_px_cur = other.n_px_max; // to stop the copy modifying the data
      
   data     = other.data;
   irf_idx  = other.irf_idx;
   
   return *this;
}