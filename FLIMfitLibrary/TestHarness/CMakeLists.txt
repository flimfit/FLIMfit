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

cmake_minimum_required(VERSION 3.5)

project(TestHarness)

include_directories( ${FGP_INCLUDE_DIRS} )

# Enable OpenMP support, disable for XCode
#===================================================
if(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
   set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
   set(CMAKE_XCODE_ATTRIBUTE_ENABLE_OPENMP_SUPPORT "YES")
else(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
   find_package("OpenMP")
   if (OPENMP_FOUND)
      option(USE_OMP "Use OpenMP" ON)
      if (USE_OMP)
         set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -DUSE_OMP")
         message("Using OpenMP")
      endif()
   endif()
endif()


# Set the source and header files
#===================================================
set(SOURCE
   TestHarness.cpp
   FLIMSimulation.cpp
)

set(HEADERS
   FLIMSimulation.h
   QR_test.h
)

add_executable(TestHarness ${SOURCE} ${HEADERS} )

#get_target_property(EXE_LOCATION TestHarness LOCATION)
#add_custom_command(TARGET TestHarness POST_BUILD COMMAND $<TARGET_FILE:TestHarness> ARGS --result_code=no --report_level=no --catch_system_errors=no)

target_link_libraries(TestHarness ${FGP_LIB} levmar ${LEVMAR_LIBRARIES})


