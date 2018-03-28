CMAKE_MINIMUM_REQUIRED(VERSION 3.7)
set(CMAKE_CXX_STANDARD 14)

set(TARGET_SDKROOT "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk")

# check to see if SDK exists and use it if so
if(APPLE)
if(EXISTS ${TARGET_SDKROOT})
    set(CMAKE_OSX_SYSROOT ${TARGET_SDKROOT})
else()
    message(WARNING "Could not find macOS 10.10 SDK, falling back on default")
endif()
endif()

project(FLIMfit)

find_package(Qt5Widgets REQUIRED)
find_package(Qt5PrintSupport)


set(CMAKE_DEBUG_POSTFIX "")
set(FlimReaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMfitLibrary)
