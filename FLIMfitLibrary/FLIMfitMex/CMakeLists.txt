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

project(FLIMfitMex)

find_package(Qt5Core)
find_package(OpenCV REQUIRED)
# MATLAB stuff
#====================================

# Find MATLAB
set(MATLAB_ADDITIONAL_VERSIONS
    "R2015b=8.6"
    "R2015a=8.5"
    "R2014b=8.4")
set(MATLAB_FIND_DEBUG TRUE)
find_package(Matlab COMPONENTS MEX_COMPILER MX_LIBRARY REQUIRED)


include_directories(${LEVMAR_INCLUDE_DIRS} ${OpenCV_INCLUDE_DIRS} ../FLIMDecayModel ../DataFitter ../FLIMfit)
link_directories(${LAPACKBLAS_DIR}) # lapack doesn't give us the right path

set (COMMON_LIBS FLIMfit DataFitter FLIMDecayModel Qt5::Core)

matlab_add_mex(NAME ff_FLIMImage SRC MexUtils.h FLIMImageMex.cpp)
target_link_libraries(ff_FLIMImage ${COMMON_LIBS})
add_custom_command(TARGET ff_FLIMImage POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_FLIMImage> ${MEX_OUT_DIR})

matlab_add_mex(NAME ff_FLIMData SRC MexUtils.h FLIMDataMex.cpp)
target_link_libraries(ff_FLIMData ${COMMON_LIBS})
add_custom_command(TARGET ff_FLIMData POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_FLIMData> ${MEX_OUT_DIR})

matlab_add_mex(NAME ff_Controller SRC MexUtils.h ControllerMex.cpp)
target_link_libraries(ff_Controller ${COMMON_LIBS} levmar ${LAPACKBLAS_LIB_NAMES} ${F2C_LIB_NAME})
add_custom_command(TARGET ff_Controller POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_Controller> ${MEX_OUT_DIR})

matlab_add_mex(NAME ff_FitResults SRC MexUtils.h FitResultsMex.cpp)
target_link_libraries(ff_FitResults ${COMMON_LIBS})
add_custom_command(TARGET ff_FitResults POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_FitResults> ${MEX_OUT_DIR})

matlab_add_mex(NAME ff_DecayModel SRC MexUtils.h DecayModelMex.cpp)
target_link_libraries(ff_DecayModel ${COMMON_LIBS})
add_custom_command(TARGET ff_DecayModel POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_DecayModel> ${MEX_OUT_DIR})


