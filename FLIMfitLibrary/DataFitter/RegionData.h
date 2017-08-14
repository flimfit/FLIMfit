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

class RegionData
{
public:
   RegionData();
   RegionData(RegionData* region, int px);
   ~RegionData();

   RegionData(const RegionData&) = delete; // delete copy constructor
   
   RegionData(RegionData&& other);
   RegionData& operator=( const RegionData& other );

   void Clear();
   void GetPointersForInsertion(int n, float*& y, int*& irf_idx);
   void GetPointersForArbitaryInsertion(int pos, int n, float*& y, int*& irf_idx);
   void  GetPointers(float*& y, int*& irf_idx);
   const RegionData GetBinnedRegion();
   int GetSize();


   void GetAverageDecay(float* average_decay);

   RegionData GetPixel(int px);

   int data_type;

private:

   RegionData(int data_type, int n_px, int n_meas);
   
   int n_px_max;
   int n_px_cur;
   int n_meas;

   float* data;
   int* irf_idx;

   bool is_shallow_ptr;

   friend class FLIMData;
};