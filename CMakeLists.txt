CMAKE_MINIMUM_REQUIRED(VERSION 3.7)
set(CMAKE_CXX_STANDARD 14)

option(BUILD_OPENCV "Build OpenCV (will produce static libs)" OFF)

if (BUILD_OPENCV)
   include("cmake/HunterGate.cmake")
   HunterGate(
      URL "https://github.com/ruslo/hunter/archive/v0.20.13.tar.gz"
      SHA1 "d92042d6e22522516183b86da10e56fb1af73f7a"
   )
endif ()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

project(FLIMfit)

if (BUILD_OPENCV)
   hunter_add_package(OpenCV)
   hunter_add_package(Tiff)
   # Prefer static libraries so we don't mess with Matlab 
   set(CMAKE_FIND_LIBRARY_SUFFIXES .a .tbd .dylib .so)
endif ()

find_package(Qt5 COMPONENTS Widgets PrintSupport REQUIRED)
set(CMAKE_AUTOMOC ON)

set(CMAKE_DEBUG_POSTFIX "")
set(FlimReaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitFrontEnd/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitFrontEnd/Libraries/)

add_subdirectory(FLIMfitLibrary)
