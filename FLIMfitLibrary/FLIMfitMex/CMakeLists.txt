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

cmake_minimum_required(VERSION 3.9)
project(FLIMfitMex)

include("cmake/DeployQt.cmake")

set(CMAKE_AUTOMOC ON)

# Find MATLAB
set(MATLAB_FIND_DEBUG TRUE)
find_package(Matlab COMPONENTS MEX_COMPILER MX_LIBRARY REQUIRED)

link_directories(${LAPACKBLAS_DIR}) # lapack doesn't give us the right path

set (COMMON_LIBS FLIMfit DataFitter FLIMDecayModel Qt5::Core ${Boost_LIBRARIES} levmar ${LEVMAR_LIBRARIES})
set (COMMON_FILES MexUtils.h FLIMfitMex.h FLIMfitMex.cpp DecayModelMex.cpp FitResultsMex.cpp ControllerMex.cpp FLIMDataMex.cpp FLIMImageMex.cpp)

matlab_add_mex(NAME FLIMfitMex SRC ${COMMON_FILES} LINK_TO ${COMMON_LIBS})

set(CMAKE_INSTALL_OPENMP_LIBRARIES TRUE)

deployqt(FLIMfitMex INCLUDE_MODULES ${QTLIBS})
add_custom_command(TARGET FLIMfitMex POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_directory $<TARGET_FILE_DIR:FLIMfitMex> ${MEX_OUT_DIR})