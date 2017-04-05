CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.18.29.tar.gz"
    SHA1 "ebea5d2fa4aa70de1234b05c4bf1b69705abb1ba"
	LOCAL
)

project(FLIMfit)

hunter_add_package(OpenCV)
hunter_add_package(Boost COMPONENTS system filesystem)

set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMreader/Source)
add_subdirectory(FLIMfitLibrary)
