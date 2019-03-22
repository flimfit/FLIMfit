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

project(DataFitter)

find_package(OpenMP)

find_package(dlib REQUIRED VERSION 19.8)
set_target_properties(dlib::dlib PROPERTIES MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release)

# Set the source and header files
#===================================================
set(SOURCE
   FLIMData.cpp
   RegionData.cpp
   VariableProjectionFitter.cpp
   VariableProjector.cpp
   MaximumLikelihoodFitter.cpp
   AbstractFitter.cpp
   lmstr.cpp
   lmstx.cpp
   lmdif.cpp
   nnls.cpp
   fdjac2.cpp
   cminpack_support.cpp
   FitResults.cpp
   MeanLifetimeEstimator.cpp
   LinearMLModel.cpp
)

set(HEADERS   
   FLIMData.h
   RegionData.h
   VariableProjectionFitter.h
   VariableProjector.h
   nnls.h
   AbstractFitter.h
   MaximumLikelihoodFitter.h
   cminpack.h
   ConcurrencyAnalysis.h
   omp_stub.h
   FitResults.h
   FlagDefinitions.h
   util.h
   MeanLifetimeEstimator.h
   RegionStats.h
   RegionStatsCalculator.h
   ProgressReporter.h
   DecayResampler.h 
   LinearMLModel.h
)

# Make library
#===================================================
add_library(DataFitter STATIC ${SOURCE} ${HEADERS})
target_link_libraries(DataFitter PUBLIC levmar FLIMDecayModel dlib::dlib OpenMP::OpenMP_CXX)
target_include_directories(DataFitter INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})