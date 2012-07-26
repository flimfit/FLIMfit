
cmake_minimum_required(VERSION 2.6)

project(TestHarness)

include_directories( ${FGP_INCLUDE_DIRS} )


# Set the source and header files
#===================================================
set(SOURCE
   TestHarness.cpp
)

#set(HEADERS
#  
#)

# Add _32/_64 appendix to library
#===================================================
if( CMAKE_SIZEOF_VOID_P EQUAL 8 )
   set( LIB_NAME "FLIMGlobalAnalysis_64" )
else( CMAKE_SIZEOF_VOID_P EQUAL 8 )
   set( LIB_NAME "FLIMGlobalAnalysis_32" ) 
endif( CMAKE_SIZEOF_VOID_P EQUAL 8 )

# Make sure we output directly into binary folder
#===================================================
set(OUT_DIR ${CMAKE_BINARY_DIR}/../../Libraries)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${OUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${OUT_DIR})

# Copy header to output directory
#===================================================
#file(COPY  ${CMAKE_SOURCE_DIR}/Source/FLIMGlobalAnalysis.h DESTINATION ${OUT_DIR})
#file(COPY  ${CMAKE_SOURCE_DIR}/Source/FlagDefinitions.h DESTINATION ${OUT_DIR})


add_executable(TestHarness ${SOURCE} ${HEADERS} )

target_link_libraries(TestHarness ${FGP_LIB})


