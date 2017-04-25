CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.18.43.tar.gz"
    SHA1 "d2c8c42cd07f7cefe18fd9a9b9c13114b1a15a27"
    LOCAL
)
project(FLIMfit)

hunter_add_package(OpenCV)
hunter_add_package(Boost COMPONENTS system filesystem)
hunter_add_package(dlib)

set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMreader/Source)
add_subdirectory(FLIMfitLibrary)
