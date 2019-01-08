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

#pragma once

#include <vector>
#include <memory>

typedef std::vector<float>::iterator float_iterator;
typedef std::vector<int>::iterator int_iterator;

class RegionData
{
public:
   RegionData();
   RegionData(int data_type, int n_px, int n_meas);
   RegionData(RegionData* region, int px);

   RegionData(const RegionData&) = delete; // delete copy constructor
   
   RegionData(RegionData&& other) = delete;
   RegionData& operator=( const RegionData& other ) = delete;

   void clear();
   void getPointersForInsertion(int n, float_iterator& y, int_iterator& irf_idx);
   void getPointersForArbitaryInsertion(int pos, int n, float_iterator& y, int_iterator& irf_idx);
   void getPointers(float_iterator& y, int_iterator& irf_idx);
   std::shared_ptr<RegionData> getBinnedRegion();
   int getSize();


   void getAverageDecay(float_iterator average_decay);

   std::shared_ptr<RegionData> getPixel(int px);

   int data_type;

private:

   
   int n_px_max;
   int n_px_cur;
   int n_meas;

   float_iterator data_it;
   int_iterator irf_idx_it;

   std::vector<float> data;
   std::vector<int> irf_idx;

   bool is_shallow_ptr;

   friend class FLIMData;
};
