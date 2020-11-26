CMAKE_MINIMUM_REQUIRED(VERSION 3.12)
set(CMAKE_CXX_STANDARD 14)


set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake
    CACHE STRING "Vcpkg toolchain file")

project(FLIMfit)

include("cmake/ConfigureMSVCRuntime.cmake")
configure_msvc_runtime()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL Release)
set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release) 

find_package(Qt5 COMPONENTS Widgets PrintSupport REQUIRED)
set(CMAKE_AUTOMOC ON)

set(CMAKE_DEBUG_POSTFIX "")
set(FlimReaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitFrontEnd/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitFrontEnd/Libraries/)

add_subdirectory(FLIMfitLibrary)
