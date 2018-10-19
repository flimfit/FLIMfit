CMAKE_MINIMUM_REQUIRED(VERSION 3.7)
set(CMAKE_CXX_STANDARD 14)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

project(FLIMfit)

if (APPLE)   
      # Prefer static libraries so we don't mess with Matlab 
      set(CMAKE_FIND_LIBRARY_SUFFIXES .a .tbd .dylib .so)
endif ()

find_package(Qt5 COMPONENTS Widgets PrintSupport REQUIRED)
set(CMAKE_AUTOMOC ON)

set(CMAKE_DEBUG_POSTFIX "")
set(FlimReaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitFrontEnd/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitFrontEnd/Libraries/)

add_subdirectory(FLIMfitLibrary)
