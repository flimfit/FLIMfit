##=========================================================================
##  
##  GlobalProcessing FLIM Analysis Package
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

project(FLIMfit)

set(OUT_DIR ${CMAKE_BINARY_DIR}/../../Libraries)

CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
add_subdirectory( "levmar-2.6ML" )
add_subdirectory("Source")
add_subdirectory("TestHarness")