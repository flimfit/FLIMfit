cmake_minimum_required(VERSION 3.12)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake
    CACHE STRING "Vcpkg toolchain file")

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
add_subdirectory(FLIMfitLibrary)