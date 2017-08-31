CMAKE_MINIMUM_REQUIRED(VERSION 3.7)
set(CMAKE_CXX_STANDARD 14)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.19.79.tar.gz"
    SHA1 "f4ac704bdf9f32b52f718b1ac520bb6aca2d9be4"
    LOCAL
)

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

hunter_add_package(Boost COMPONENTS system filesystem serialization date_time)
hunter_add_package(OpenCV)
hunter_add_package(dlib)

find_package(OpenCV CONFIG REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5PrintSupport)
find_package(dlib)


set(CMAKE_DEBUG_POSTFIX "")
set(FlimReaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMfitLibrary)
