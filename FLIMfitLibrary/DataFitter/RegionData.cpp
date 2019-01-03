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
   data_type(0),
   n_px_max(0),
   n_px_cur(0),
   n_meas(0),
   is_shallow_ptr(true)
{
}

RegionData::RegionData(int data_type, int n_px_max, int n_meas) :
   n_px_max(n_px_max),
   n_px_cur(0),
   n_meas(n_meas),
   data_type(data_type),
   is_shallow_ptr(false)
{
   data.assign(n_px_max * n_meas, 0);
   irf_idx.assign(n_px_max, 0);

   data_it = data.begin();
   irf_idx_it = irf_idx.begin();
}

RegionData::RegionData(RegionData* region, int px) :
   n_px_max(1),
   n_px_cur(1),
   is_shallow_ptr(true)
{  
   n_meas = region->n_meas;
   data_type = region->data_type;

   data_it = region->data_it + px * n_meas;
   irf_idx_it = region->irf_idx_it + px;
}

std::shared_ptr<RegionData> RegionData::GetPixel(int px)
{
   assert(px < n_px_cur);
   return std::make_shared<RegionData>(this, px);
}

std::shared_ptr<RegionData> RegionData::GetBinnedRegion()
{
   auto binned_region = std::make_shared<RegionData>(data_type, 1, n_meas);

   float_iterator binned_data;
   int_iterator   binned_irf_idx;

   binned_region->GetPointersForInsertion(1, binned_data, binned_irf_idx);

   GetAverageDecay(binned_data);
   binned_irf_idx[0] = 0;

   return binned_region;
}

void RegionData::Clear()
{
   n_px_cur = 0;
}

void RegionData::GetPointersForInsertion(int n, float_iterator& data_, int_iterator& irf_idx_)
{
   assert(!is_shallow_ptr);
   assert( n + n_px_cur <= n_px_max );

   data_    = data_it + n_px_cur * n_meas;
   irf_idx_ = irf_idx_it  + n_px_cur;

   n_px_cur += n;
}

void RegionData::GetPointersForArbitaryInsertion(int pos, int n, float_iterator& data_, int_iterator& irf_idx_)
{
   assert(!is_shallow_ptr);
   assert( n + pos <= n_px_max );

   data_    = data_it + pos * n_meas;
   irf_idx_ = irf_idx_it  + pos;

   n_px_cur = std::max(n_px_cur, pos + n);
}

void RegionData::GetAverageDecay(float_iterator average_decay)
{
   std::fill_n(average_decay, n_meas, 0.0f);

   for(int i=0; i<n_px_cur; i++)
      for(int j=0; j<n_meas; j++)
         average_decay[j] += data_it[i*n_meas + j];
      
   for(int j=0; j<n_meas; j++)
      average_decay[j] /= n_px_cur;
}

void RegionData::GetPointers(float_iterator& data_, int_iterator& irf_idx_)
{
   data_ = data_it;
   irf_idx_ = irf_idx_it;
}

int RegionData::GetSize()
{
   return n_px_cur;
}