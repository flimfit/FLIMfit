##=========================================================================
##  
##  GlobalProcessing FLIM Analysis Package
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

project(FLIMfitLib)

set(OUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Libraries)
set(CMAKE_CXX_STANDARD 14)

CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
add_subdirectory("levmar-2.6ML")
add_subdirectory("Source")
add_subdirectory("FLIMreader")
#add_subdirectory("TestHarness")
