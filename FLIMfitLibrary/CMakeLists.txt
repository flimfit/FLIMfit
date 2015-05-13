##=========================================================================
##  
##  FLIMfit
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

project(FLIMfit)

set(OUT_DIR ${CMAKE_BINARY_DIR}/../../Libraries)
set(CMAKE_PREFIX_PATH /usr/local/opt/qt5) # for brew install of qt5

find_package(Qt5Core REQUIRED)
find_package(OpenCV REQUIRED)
set(CMAKE_AUTOMOC ON)

#set(Boost_USE_STATIC_LIBS ON)
#set(Boost_USE_MULTITHREADED ON)
find_package(Boost REQUIRED COMPONENTS system filesystem)
include_directories(${Boost_INCLUDE_DIR})
#add_definitions(-DBOOST_DATE_TIME_NO_LIB)


# Enable OpenMP support, disable for XCode
#===================================================
if(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
   set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
   set(CMAKE_XCODE_ATTRIBUTE_ENABLE_OPENMP_SUPPORT "YES")
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wno-reorder")
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

CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
add_subdirectory( "levmar-2.6ML" )
add_subdirectory("FLIMDecayModel")
add_subdirectory("DataFitter")
add_subdirectory("FLIMfit")
add_subdirectory("FLIMReader/Source/FLIMReader")
add_subdirectory("FLIMfitQT")
#add_subdirectory("FLIMfitMex")
add_subdirectory("TestHarness")
