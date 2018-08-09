#!/bin/bash

echo "Checking for homebrew install..."
(brew update | grep "command not found") \
	&& rruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
	|| echo "Homebrew installed"

echo "Ensure cmake, gcc and boost are installed..."
# Ensure gcc, ghostscript, cmake, LAPACK are installed using Homebrew
(brew list | grep gcc) && echo " installed" || brew install gcc
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript
(brew list | grep cmake) && echo " installed" || brew install cmake
(brew list | grep platypus) && echo " installed" || brew install platypus
(brew list | grep lapack) && echo " installed" || brew install lapack
(brew list | grep coreutils) && echo " installed" || brew install coreutils
(brew list | grep dlib) && echo " installed" || brew install dlib
(brew list | grep boost) && echo " installed" || brew install boost
brew update cmake