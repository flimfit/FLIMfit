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

project(FlimDecayModel)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(OpenCV REQUIRED)
find_package(Boost REQUIRED COMPONENTS system filesystem serialization date_time)
find_package(LibLZMA REQUIRED)

# Set the source and header files
#===================================================
set(SOURCE
   IRFConvolution.cpp
   InstrumentResponseFunction.cpp
   MeasuredIrf.cpp
   GaussianIrf.cpp
   AbstractDecayGroup.cpp
   MultiExponentialDecayGroupPrivate.cpp
   MultiExponentialDecayGroup.cpp
   FretDecayGroup.cpp
   AnisotropyDecayGroup.cpp
   BackgroundLightDecayGroup.cpp
   PatternDecayGroup.cpp
   AcquisitionParameters.cpp
   DecayModel.cpp
   DataTransformer.cpp
   FLIMImage.cpp
   PhasorCalculator.cpp
   ParameterConstraints.cpp
   AbstractConvolver.cpp
   MeasuredIrfConvolver.cpp
   GaussianIrfConvolver.cpp   
   Aberration.cpp
)

set(HEADERS   
   AbstractDecayGroup.h
   FretDecayGroup.h
   MultiExponentialDecayGroupPrivate.h
   MultiExponentialDecayGroup.h
   AnisotropyDecayGroup.h
   BackgroundLightDecayGroup.h
   PatternDecayGroup.h
   IRFConvolution.h
   InstrumentResponseFunction.h
   MeasuredIrf.h
   GaussianIrf.h
   AcquisitionParameters.h
   DecayModel.h
   FittingParameter.h
   DataTransformer.h
   FLIMImage.h
   FLIMBackground.h
   cvmat_serialization.h
   PhasorCalculator.h
   ParameterConstraints.h
   AbstractConvolver.h
   MeasuredIrfConvolver.h
   GaussianIrfConvolver.h
   Aberration.h
   AlignedVectors.h
   FastErf.h
   simd_avx.h
)

add_definitions(-DBOOST_DATE_TIME_NO_LIB)

# Make library
#===================================================
add_library(FLIMDecayModel STATIC ${SOURCE} ${HEADERS})
target_link_libraries(FLIMDecayModel Qt5::Core ${Boost_LIBRARIES} ${OpenCV_LIBRARIES} ${LIBLZMA_LIBRARIES})
target_include_directories(FLIMDecayModel INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
                                          PUBLIC ${OpenCV_INCLUDE_DIRS})