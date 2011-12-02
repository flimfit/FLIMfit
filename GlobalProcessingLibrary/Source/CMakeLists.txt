
cmake_minimum_required(VERSION 2.8)

project(FLIMGlobalAnalysis)

# Include the BOOST header files
#===================================================
include_directories( "../Boost" )

# Set the source and header files
#===================================================
set(SOURCE
	fcommon.cpp
	FitStatus.cpp
	IRFConvolution.cpp
	ModelADA.cpp
	FLIMGlobalAnalysis.cpp
	FLIMGlobalFitController.cpp
	FLIMGlobalFitController_ProcessRegion.cpp
	VarPro.cpp
	VarPro_dpa.cpp
	VarProGrid.cpp
	tinythread.cpp
)

set(HEADERS
	f2c.h	
	FitStatus.h
	IRFConvolution.h
	ModelADA.h
	FLIMGlobalAnalysis.h
	FLIMGlobalFitController.h
	ModelADA.h
	tinythread.h
)

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

if(MSVC | APPLE)
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG   ${OUT_DIR})
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OUT_DIR})

	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${OUT_DIR})
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OUT_DIR})
else(MSVC | APPLE)
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUT_DIR})
endif(MSVC | APPLE)

# Copy header to output directory
#===================================================
file(COPY  ${CMAKE_SOURCE_DIR}/FLIMGlobalAnalysis.h DESTINATION ${OUT_DIR})

# Make library
#===================================================
add_library(${LIB_NAME} SHARED ${SOURCE} ${HEADERS} )

# Make sure we don't have 'lib' prefix on UNIX
#===================================================
set_target_properties(${LIB_NAME} PROPERTIES PREFIX "")



