CMAKE_MINIMUM_REQUIRED(VERSION 3.7)
set(CMAKE_CXX_STANDARD 14)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.19.75.tar.gz"
    SHA1 "35b76b78b85bcf1dce81e0cef32cc1f728170abf"
    LOCAL
)
project(FLIMfit)

hunter_add_package(Boost COMPONENTS system filesystem serialization date_time)
hunter_add_package(OpenCV)
hunter_add_package(dlib)
hunter_add_package(Qt COMPONENTS qtbase)

find_package(OpenCV CONFIG REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5PrintSupport)
find_package(dlib)


set(CMAKE_DEBUG_POSTFIX "")
set(FlimReaderMEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)
set(MEX_OUT_DIR ${CMAKE_SOURCE_DIR}/FLIMfitLibrary/Libraries/)

add_subdirectory(FLIMfitLibrary)
