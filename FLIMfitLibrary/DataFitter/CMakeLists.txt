#=========================================================================
#
# Copyright (C) 2013 Imperial College London.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# This software tool was developed with support from the UK 
# Engineering and Physical Sciences Council 
# through  a studentship from the Institute of Chemical Biology 
# and The Wellcome Trust through a grant entitled 
# "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
#
# Author : Sean Warren
#
#=========================================================================

cmake_minimum_required(VERSION 2.8.4)

project(DataFitter)

# Include the BOOST header files
#===================================================
FIND_PACKAGE(Boost)
if(Boost_FOUND)
    INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIR})
endif()
include_directories( "../Boost" )


include_directories( ${LEVMAR_INCLUDE_DIRS} ../FLIMDecayModel)
# Set the source and header files
#===================================================
set(SOURCE
   FLIMData.cpp
   RegionData.cpp
   VariableProjector.cpp
   MaximumLikelihoodFitter.cpp
   AbstractFitter.cpp
   lmstr.cpp
   lmstx.cpp
   lmdif.cpp
   fdjac2.cpp
   cminpack_support.cpp
   FitStatus.cpp
   FitResults.cpp
   tinythread.cpp
   util.cpp
   MeanLifetimeEstimator.cpp
)

set(HEADERS   
   FLIMData.h
   RegionData.h
   VariableProjector.h
   AbstractFitter.h
   MaximumLikelihoodFitter.h
   cminpack.h
   ConcurrencyAnalysis.h
   omp_stub.h
   FitStatus.h
   FitResults.h
   tinythread.h
   FlagDefinitions.h
   util.h
   MeanLifetimeEstimator.h
   ImageStats.h
   TrimmedMean.h
)

# Include optimisation flags in Visual Studio
#===================================================
if(MSVC)
   set(PLATFORM_FLAGS_ALL "/Oi /fp:fast")
   set(PLATFORM_FLAGS_RELEASE "/Ox /Ot /Ob2")
   set(PLATFORM_FLAGS_RELWITHDEBINFO "/Ox /Ot /Ob2")
   set(PLATFORM_FLAGS_DEBUG "/ZI")
   add_definitions(-D_CRT_SECURE_NO_WARNINGS)
   add_definitions(-D_MSVC)
   add_definitions(-DNOMINMAX)

   if(CMAKE_VS_PLATFORM_TOOLSET MATCHES "v110")
	 message("Warning: When using VS2012 make sure you select the v110_xp toolchain to allow use on WinXP")
   endif(CMAKE_VS_PLATFORM_TOOLSET MATCHES "v110")
endif(MSVC)

if(UNIX)
   set(PLATFORM_FLAGS_ALL "-msse3")
   set(PLATFORM_FLAGS_RELEASE "-O3 -ffast-math -ftree-vectorize")
   set(PLATFORM_FLAGS_DEBUG "")
endif(UNIX)

# Add platform specific flags
#===================================================
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PLATFORM_FLAGS_ALL}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${PLATFORM_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${PLATFORM_FLAGS_DEBUG}")

add_definitions(-DBOOST_DATE_TIME_NO_LIB)

# Make library
#===================================================
add_library(DataFitter STATIC ${SOURCE} ${HEADERS})
