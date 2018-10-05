##=========================================================================
##  
##  FLIMfit
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

project(FLIMfit)
cmake_minimum_required(VERSION 3.9)

find_package(OpenCV REQUIRED)


# Include optimisation flags in Visual Studio
#===================================================
if(MSVC)
   set(PLATFORM_FLAGS_ALL "/Oi /fp:fast /INCREMENTAL /Zi /arch:AVX")
   set(PLATFORM_FLAGS_RELEASE "/Ox /Ot /Ob2")
   set(PLATFORM_FLAGS_RELWITHDEBINFO "/Ox /Ot /Ob2")
   add_definitions(-D_CRT_SECURE_NO_WARNINGS)
   add_definitions(-D_MSVC)
   add_definitions(-DNOMINMAX)
endif(MSVC)

if(UNIX)
   set(PLATFORM_FLAGS_ALL "-mavx")
   set(PLATFORM_FLAGS_RELEASE "-O3 -ffast-math -ftree-vectorize")
   set(PLATFORM_FLAGS_DEBUG "-D_DEBUG")
endif(UNIX)

# Add platform specific flags
#===================================================
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PLATFORM_FLAGS_ALL}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${PLATFORM_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${PLATFORM_FLAGS_DEBUG}")

add_subdirectory("FLIMreader")
add_subdirectory("levmar-2.6ML")
add_subdirectory("FLIMDecayModel")
add_subdirectory("DataFitter")
add_subdirectory("FLIMfit")
#add_subdirectory("FLIMWidgets")
#add_subdirectory("FLIMfitQT")
add_subdirectory("FLIMfitMex")
add_subdirectory("TestHarness")
