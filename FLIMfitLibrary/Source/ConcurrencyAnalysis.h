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

#ifndef CONANALYSIS_H_
#define CONANALYSIS_H_

// Uncomment this to use concurrency analysis, make sure you add the SDK to visual studio
//#define USE_CONCURRENCY_ANALYSIS

#ifdef USE_CONCURRENCY_ANALYSIS

#include "cvmarkersobj.h"
using namespace Concurrency::diagnostic;

#define INIT_CONCURRENCY   span* sp
#define START_SPAN(x)      sp = new span (*writer, _T(x))
#define END_SPAN           delete sp  

extern marker_series* writer;

#else

#define INIT_CONCURRENCY   
#define START_SPAN(x)
#define END_SPAN           

#define _T(x) 0 

#endif


#endif