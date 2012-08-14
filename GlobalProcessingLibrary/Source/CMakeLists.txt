
cmake_minimum_required(VERSION 2.6)

project(FLIMGlobalAnalysis)

# Include the BOOST header files
#===================================================
FIND_PACKAGE(Boost)
if(Boost_FOUND)
    INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIR})
endif()
include_directories( "../Boost" )

# enable openmp support in xcode
#===================================================
if(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
#   set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
#   set(CMAKE_XCODE_ATTRIBUTE_ENABLE_OPENMP_SUPPORT "YES")
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNO_OMP")
else(APPLE AND ${CMAKE_GENERATOR} MATCHES "Xcode")
   find_package("OpenMP")
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()


include_directories( ${LEVMAR_INCLUDE_DIRS} )


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
   FLIMGlobalFitController_GetImageResults.cpp
   FLIMGlobalFitController_Model.cpp
   FLIMGlobalFitController_ADA.cpp
   FLIMData.cpp
   VariableProjector.cpp
   MaximumLikelihoodFitter.cpp
   AbstractFitter.cpp
   tinythread.cpp
   lmstr.c
   lmstx.c
   cminpack_support.c
   util.cpp
)

set(HEADERS   
   FitStatus.h
   IRFConvolution.h
   ModelADA.h
   FLIMGlobalAnalysis.h
   FLIMGlobalFitController.h
   FLIMData.h
   ModelADA.h
   VariableProjector.h
   AbstractFitter.h
   MaximumLikelihoodFitter.h
   tinythread.h
   FlagDefinitions.h
   cminpack.h
   util.h
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

#set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUT_DIR})
#set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG   ${OUT_DIR})
#set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OUT_DIR})
#set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${OUT_DIR})
#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${OUT_DIR})
#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OUT_DIR})
#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${OUT_DIR})


# Copy header to output directory
#===================================================
#file(COPY  ${CMAKE_SOURCE_DIR}/Source/FLIMGlobalAnalysis.h DESTINATION ${OUT_DIR})
#file(COPY  ${CMAKE_SOURCE_DIR}/Source/FlagDefinitions.h DESTINATION ${OUT_DIR})

# Include optimisation flags in Visual Studio
#===================================================
if(MSVC)
   set(PLATFORM_FLAGS_ALL "/Oi /fp:fast")
   set(PLATFORM_FLAGS_RELEASE "/Ox /Ot /Ob2")
   set(PLATFORM_FLAGS_DEBUG "/ZI")
endif(MSVC)

if(UNIX)
   set(PLATFORM_FLAGS_ALL "-msse3")
   set(PLATFORM_FLAGS_RELEASE "-O3 -ffast-math -ftree-vectorize")
   set(PLATFORM_FLAGS_DEBUG "")
endif(UNIX)

# Add platform specific flags
#===================================================
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PLATFORM_FLAGS_ALL}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${PLATFORM_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${PLATFORM_FLAGS_DEBUG}")


# Make library
#===================================================
add_library(${LIB_NAME} SHARED ${SOURCE} ${HEADERS} )

target_link_libraries(${LIB_NAME} levmar)

# Make sure we don't have 'lib' prefix on UNIX
#===================================================
set_target_properties(${LIB_NAME} PROPERTIES PREFIX "")

get_target_property(LIB_LOCATION ${LIB_NAME} LOCATION)
add_custom_command(TARGET ${LIB_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${LIB_LOCATION} ${OUT_DIR}
                                                 COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/Source/FLIMGlobalAnalysis.h" ${OUT_DIR}
                                                 COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/Source/FlagDefinitions.h" ${OUT_DIR})

set( FGP_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "Include dir for GlobalProcessing." FORCE )
set( FGP_LIB ${LIB_NAME} CACHE STRING "Include dir for GlobalProcessing." FORCE )
set( FGP_LIB_DIR ${OUT_DIR} CACHE STRING "Include dir for GlobalProcessing." FORCE )

