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

project(TestHarness)

set(SOURCE
   TestDecayModelDerivatives.cpp
   TestHarness.cpp
   TestDecayResampler.cpp
   TestFittingCore.cpp
   FLIMSimulation.cpp
   FLIMSimulationTCSPC.cpp
   FLIMSimulationWF.cpp
)

set(HEADERS
   FLIMSimulation.h
   Attenuator.h
   QR_test.h
)

add_executable(TestHarness ${SOURCE} ${HEADERS})

target_link_libraries(TestHarness FLIMfitLib)


# Run tests after compile
#===================================================
#add_custom_command(TARGET TestHarness POST_BUILD
#				   COMMAND $<TARGET_FILE:TestHarness> --result_code=no --report_level=no)
target_link_libraries(TestHarness ${FGP_LIB} levmar ${LEVMAR_LIBRARIES})


