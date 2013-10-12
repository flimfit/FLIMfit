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


#include "FitStatus.h"
#include "InstrumentResponseFunction.h"
#include "ModelADA.h" 
#include "FLIMGlobalAnalysis.h"
#include "FLIMGlobalFitController.h"
#include "FLIMData.h"
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <boost/shared_ptr.hpp>
#include <boost/ptr_container/ptr_map.hpp>

using std::pair;
using boost::ptr_map;
using boost::shared_ptr;

int next_id = 0;

typedef ptr_map<int, FLIMGlobalFitController> ControllerMap;

ControllerMap controller;


#ifdef _WINDOWS

#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
                )
{
   switch (ul_reason_for_call)
   {
   case DLL_PROCESS_ATTACH:
      #ifdef USE_CONCURRENCY_ANALYSIS
      writer = new marker_series("FLIMfit");
      #endif
      //VLDDisable();
      break;
      
   case DLL_THREAD_ATTACH:
      //VLDEnable();
      break;
 
   case DLL_THREAD_DETACH:
      //VLDDisable();
      break;

   case DLL_PROCESS_DETACH:
      FLIMGlobalClearFit(-1);
      #ifdef USE_CONCURRENCY_ANALYSIS
      delete writer;
      #endif
      break;
   }
    return TRUE;
}

#else

void __attribute__ ((constructor)) myinit() 
{
}

void __attribute__ ((destructor)) myfini()
{
   FLIMGlobalClearFit(-1);
}

#endif


StartFit(FLIMData)