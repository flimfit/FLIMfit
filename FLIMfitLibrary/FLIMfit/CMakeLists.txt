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

project(FLIMfit)
find_package(OpenCV REQUIRED)

include_directories(${LEVMAR_INCLUDE_DIRS} ${OpenCV_INCLUDE_DIRS} ../FLIMDecayModel ../DataFitter )


# Set the source and header files
#===================================================
set(SOURCE
   ModelADA.cpp
   FitController.cpp
   FLIMGlobalFitController_ProcessRegion.cpp
   FLIMGlobalFitController_GetImageResults.cpp
   FitSettings.cpp
)

set(HEADERS   
   FitController.h
   FLIMGlobalAnalysis.h
   ModelADA.h
   FitSettings.h
   QFitController.h
)

# Make library
#===================================================
add_library(FLIMfit STATIC ${SOURCE} ${HEADERS} )
target_link_libraries(FLIMfit Qt5::Core)

set( FLIMfit_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR} PARENT_SCOPE )
set( FLIMfit_LIB_DIR ${OUT_DIR} PARENT_SCOPE )

