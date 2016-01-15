project(FLIMfit)

CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMfitLibrary)
add_subdirectory(FLIMreader/Source)
