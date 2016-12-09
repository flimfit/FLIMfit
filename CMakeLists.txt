CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.14.29.tar.gz"
    SHA1 "9c29c30fff99b7c1479b2e9d4926dcc3f8d364e0"
    LOCAL
)

project(FLIMfit)

hunter_add_package(OpenCV)
hunter_add_package(Boost COMPONENTS system filesystem)

set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMreader/Source)
add_subdirectory(FLIMfitLibrary)
