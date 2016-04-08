project(FLIMfit)

CMAKE_MINIMUM_REQUIRED(VERSION 3.0)


if(WIN32)
   set( Boost_USE_STATIC_LIBS ON )
endif()

set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMfitLibrary)
