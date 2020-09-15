##=========================================================================
##  
##  GlobalProcessing FLIM Analysis Package
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

cmake_minimum_required(VERSION 3.12)
project(FLIMfitLib)

set(OUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../FLIMfitFrontEnd/Libraries)
set(CMAKE_CXX_STANDARD 14)

add_subdirectory("levmar-2.6ML")
add_subdirectory("Source")
#add_subdirectory("TestHarness")

# Output Visual Studio Redistributable path for Matlab
if (WIN32)
    include(InstallRequiredSystemLibraries)
    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/VisualStudioRedistributablePath.txt" "${MSVC_REDIST_DIR}")
endif()