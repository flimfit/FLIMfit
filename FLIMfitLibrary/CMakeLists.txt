##=========================================================================
##  
##  FLIMfit
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

project(FLIMfit)
cmake_minimum_required(VERSION 3.0)

set(OUT_DIR ${CMAKE_BINARY_DIR}/../../Libraries)
set(CMAKE_PREFIX_PATH /usr/local/opt/qt5) # for brew install of qt5

find_package(Qt5Core REQUIRED)
find_package(OpenCV REQUIRED)
set(CMAKE_AUTOMOC ON)

find_package(Boost REQUIRED COMPONENTS system filesystem serialization)
include_directories(${Boost_INCLUDE_DIR})


# Enable OpenMP support, disable for XCode
#===================================================
if(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
   set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
   set(CMAKE_XCODE_ATTRIBUTE_ENABLE_OPENMP_SUPPORT "YES")
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wno-reorder")
#else(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
#   find_package("OpenMP")
#   if (OPENMP_FOUND)
#      option(USE_OMP "Use OpenMP" ON)
#      if (USE_OMP)
#         set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -DUSE_OMP")
#         message("Using OpenMP")
#      endif()
#   endif()
endif()


# Include optimisation flags in Visual Studio
#===================================================
if(MSVC)
   set(PLATFORM_FLAGS_ALL "/Oi /fp:fast")
   set(PLATFORM_FLAGS_RELEASE "/Ox /Ot /Ob2")
   set(PLATFORM_FLAGS_RELWITHDEBINFO "/Ox /Ot /Ob2")
   add_definitions(-D_CRT_SECURE_NO_WARNINGS)
   add_definitions(-D_MSVC)
   add_definitions(-DNOMINMAX)
endif(MSVC)

if(UNIX)
   set(PLATFORM_FLAGS_ALL "-msse3")
   set(PLATFORM_FLAGS_RELEASE "-O3 -ffast-math -ftree-vectorize")
   set(PLATFORM_FLAGS_DEBUG "-D_DEBUG")
endif(UNIX)

set(XDISPATCH_QT_SUPPORT OFF CACHE BOOL "Turn off xdispatch QT")

# Add platform specific flags
#===================================================
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PLATFORM_FLAGS_ALL}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${PLATFORM_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${PLATFORM_FLAGS_DEBUG}")

add_subdirectory("FLIMreader/Source")
add_subdirectory( "levmar-2.6ML" )
#add_subdirectory("xdispatch")
add_subdirectory("FLIMDecayModel")
add_subdirectory("DataFitter")
add_subdirectory("FLIMfit")
add_subdirectory("FLIMfitQT")
add_subdirectory("FLIMfitMex")
add_subdirectory("TestHarness")
