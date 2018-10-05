#!/bin/bash

echo "Checking for homebrew install..."
(brew | grep "command not found") \
	&& rruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
	|| echo "Homebrew installed"

echo "Ensure cmake, gcc and boost are installed..."
# Ensure gcc, ghostscript, cmake, LAPACK are installed using Homebrew
(brew list | grep gcc) && echo " installed" || brew install gcc
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript
(brew list | grep cmake) && echo " installed" || brew install cmake
(brew list | grep platypus) && echo " installed" || brew install platypus
(brew list | grep coreutils) && echo " installed" || brew install coreutils
(brew list | grep dlib) && echo " installed" || brew install --build-from-source dlib
(brew list | grep boost) && echo " installed" || brew install boost
(brew list | grep opencv) && echo " installed" || brew install opencv
(brew list | grep libiomp) && echo " installed" || brew install libiomp
