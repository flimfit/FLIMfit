#!/bin/bash

if [ -z ${OME+x} ]; then export OME=5.1; echo "Setting OME=5.1"; fi

export CC=/usr/local/bin/gcc-4.9
export CXX=/usr/local/bin/g++-4.9

echo "Checking for homebrew install..."
(brew | grep "command not found") \
	&& rruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
	|| echo "Homebrew installed"

brew update
brew upgrade

echo "Ensure cmake, clang-omp and boost are installed..."
# Ensure gcc-4.9, ghostscript, cmake, LAPACK, boost are installed using Homebrew
(brew list | grep gcc49) || brew install homebrew/versions/gcc49
(brew list | grep boost) && echo " installed" || brew install boost
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript
(brew list | grep cmake) && echo " installed" || brew install cmake
(brew list | grep lapack) && echo " installed" || brew install homebrew/dupes/LAPACK

# Download OMERO Matlab plug-in
echo "Downloading OMERO/bioformats components..."
curl -OL http://downloads.openmicroscopy.org/latest/omero$OME/matlab.zip
unzip -o matlab.zip
mv OMERO.matlab*/* FLIMfitFrontEnd/OMEROMatlab/
rm -rf OMERO.matlab*
rm matlab*.zip

# remove sl4j-api.jar to avoid LOGGER clashes
rm FLIMfitFrontEnd/OMEROMatlab/libs/slf4j-log4j12.jar
rm FLIMfitFrontEnd/OMEROMatlab/libs/slf4j-api.jar
rm FLIMfitFrontEnd/OMEROMatlab/libs/log4j.jar


# Download bio-formats Matlab toolbox
curl -OL http://downloads.openmicroscopy.org/latest/bio-formats$OME/artifacts/bfmatlab.zip

unzip -o bfmatlab.zip
rm bfmatlab.zip
mv bfmatlab/* FLIMfitFrontEnd/BFMatlab/
rm -rf bfmatlab

# Download ini4j.jar
curl -OL http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-0.3.2.jar
mv ini4j-0.3.2.jar FLIMfitFrontEnd/OMEROMatlab/libs/ini4j.jar