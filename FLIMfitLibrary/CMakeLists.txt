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

CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
add_subdirectory( "levmar-2.6ML" )
add_subdirectory("Source")
add_subdirectory("FLIMreader")
#add_subdirectory("TestHarness")
