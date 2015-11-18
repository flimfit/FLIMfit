project(FLIMfit)

CMAKE_MINIMUM_REQUIRED(VERSION 3.2)

set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

message(FLIMreaderMEX_OUT_DIR)

add_subdirectory(FLIMfitLibrary)
add_subdirectory(FLIMreader/Source)
