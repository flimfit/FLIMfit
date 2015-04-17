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

project(FLIMfitMex)

# Include the BOOST header files
#===================================================
FIND_PACKAGE(Boost)
if(Boost_FOUND)
    INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIR})
endif()
include_directories( "../Boost" )

# MATLAB stuff
#====================================
set(MATLAB_EXTERN_DIR "E:/Program Files/extern/")
set(MATLAB_LIB_DIR ${MATLAB_EXTERN_DIR}lib/win64/microsoft/)
set(MATLAB_INCLUDE_DIR ${MATLAB_EXTERN_DIR}include)
set(MATLAB_LIBRARIES ${MATLAB_LIB_DIR}libmat.lib ${MATLAB_LIB_DIR}libmex.lib ${MATLAB_LIB_DIR}libmx.lib)

include_directories(${MATLAB_INCLUDE_DIR} ${LEVMAR_INCLUDE_DIRS} ../FLIMDecayModel ../DataFitter ../FLIMfit)


add_definitions(-DBOOST_DATE_TIME_NO_LIB)
add_definitions(-DMATLAB_MEX_FILE)

add_library(ff_FLIMData MODULE MexUtils.h FLIMDataMex.cpp)
target_link_libraries(ff_FLIMData FLIMfit DataFitter FLIMDecayModel ${MATLAB_LIBRARIES})

add_library(ff_Controller MODULE MexUtils.h ControllerMex.cpp)
target_link_libraries(ff_Controller FLIMfit DataFitter FLIMDecayModel levmar ${MATLAB_LIBRARIES})

add_library(ff_FitResults MODULE MexUtils.h FitResultsMex.cpp)
target_link_libraries(ff_FitResults FLIMfit DataFitter FLIMDecayModel ${MATLAB_LIBRARIES})

add_library(ff_DecayModel MODULE MexUtils.h DecayModelMex.cpp)
target_link_libraries(ff_DecayModel FLIMDecayModel ${MATLAB_LIBRARIES})


set_target_properties(ff_FLIMData PROPERTIES LINK_FLAGS "/export:mexFunction" )
set_target_properties(ff_FLIMData PROPERTIES SUFFIX ".mexw64")
add_custom_command(TARGET ff_FLIMData POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_FLIMData> ${OUT_DIR})

set_target_properties(ff_FitResults PROPERTIES LINK_FLAGS "/export:mexFunction" )
set_target_properties(ff_FitResults PROPERTIES SUFFIX ".mexw64")
add_custom_command(TARGET ff_FitResults POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_FitResults> ${OUT_DIR})

set_target_properties(ff_Controller PROPERTIES LINK_FLAGS "/export:mexFunction" )
set_target_properties(ff_Controller PROPERTIES SUFFIX ".mexw64")
add_custom_command(TARGET ff_Controller POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_Controller> ${OUT_DIR})

set_target_properties(ff_DecayModel PROPERTIES LINK_FLAGS "/export:mexFunction" )
set_target_properties(ff_DecayModel PROPERTIES SUFFIX ".mexw64")
add_custom_command(TARGET ff_DecayModel POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ff_DecayModel> ${OUT_DIR})

