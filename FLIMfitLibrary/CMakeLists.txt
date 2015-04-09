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

CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
add_subdirectory( "levmar-2.6ML" )
add_subdirectory("FLIMDecayModel")
add_subdirectory("DataFitter")
add_subdirectory("Source")
add_subdirectory("TestHarness")
add_subdirectory("FLIMreader/Source")
