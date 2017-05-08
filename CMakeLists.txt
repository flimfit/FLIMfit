CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.18.43.tar.gz"
    SHA1 "d2c8c42cd07f7cefe18fd9a9b9c13114b1a15a27"
    LOCAL
)
project(FLIMfit)

hunter_add_package(OpenCV)
hunter_add_package(Boost COMPONENTS system filesystem serialization date_time)
hunter_add_package(Qt COMPONENTS qtbase)

find_package(OpenCV)
find_package(Qt5Widgets)
find_package(Qt5PrintSupport)

hunter_add_package(Boost COMPONENTS system filesystem)
hunter_add_package(dlib)

set(CMAKE_DEBUG_POSTFIX "")
set(FLIMreaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMfitLibrary)
