##=========================================================================
##  
##  GlobalProcessing FLIM Analysis Package
##  (c) 2013 Sean Warren
##
##
##
##=========================================================================

cmake_minimum_required(VERSION 2.6)

project(TestHarness)

include_directories( ${FGP_INCLUDE_DIRS} )

# Include the BOOST header files
#===================================================
FIND_PACKAGE(Boost)
if(Boost_FOUND)
    INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIR})
endif()
include_directories( "../Boost" )


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




add_executable(TestHarness ${SOURCE} ${HEADERS} )

#get_target_property(EXE_LOCATION TestHarness LOCATION)
#add_custom_command(TARGET TestHarness POST_BUILD COMMAND $<TARGET_FILE:TestHarness> ARGS --result_code=no --report_level=no --catch_system_errors=no)

target_link_libraries(TestHarness ${FGP_LIB})


