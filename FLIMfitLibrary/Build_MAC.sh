#!/bin/bash

echo "Ensure homebrew is installed..."
(brew | grep "command not found") \
	&& ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)" \
	|| echo "homebrew installed"

echo "Ensure cmake, gcc 4.9 and boost are installed..."
# Ensure gcc47, boost is installed using Homebrew
(brew list | grep gcc49) && echo " installed" || brew tap homebrew/versions
(brew list | grep gcc49)  || brew install gcc49
(brew list | grep boost) && echo " installed" || brew install boost
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript
(brew list | grep cmake) && echo " installed" || brew install cmake

PROJECT_TYPE=xcode

export CC=/usr/local/bin/clang-omp
export CXX=/usr/local/bin/clang-omp++

cd GeneratedProjects

echo "Cleaning CMake Project..."
rm -rf ${PROJECT_TYPE}
mkdir -p ${PROJECT_TYPE}
cd ${PROJECT_TYPE}

echo "Generating CMake Project..."
cmake ../../ -G "Xcode" -DCMAKE_BUILD_TYPE=RELEASE

echo "Building Project..."
make

cd ../../