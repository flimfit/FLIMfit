#!/bin/bash

set OME = 5.1

echo "Checking for homebrew install..."
(brew | grep "command not found") \
	&& rruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
	|| echo "Homebrew installed"

brew update

echo "Ensure cmake, gcc 4.9 and boost are installed..."
# Ensure gcc4.9, boost is installed using Homebrew
(brew list | grep gcc49) && echo " installed" || brew tap homebrew/versions
(brew list | grep gcc49) || brew install gcc49
(brew list | grep boost) && echo " installed" || brew install boost
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript
(brew list | grep cmake) && echo " installed" || brew install cmake

# Download OMERO Matlab plug-in
curl -OL http://downloads.openmicroscopy.org/latest/omero$OME/matlab.zip
unzip matlab.zip
mv OMERO.matlab*/* FLIMfitFrontEnd/OMEROMatlab/
rmdir OMERO.matlab*
rm matlab*.zip

# remove sl4j-api.jar to avoid LOGGER clashes
rm FLIMfitFrontEnd/OMEROMatlab/libs/slf4j-log4j12.jar
rm FLIMfitFrontEnd/OMEROMatlab/libs/slf4j-api.jar
rm FLIMfitFrontEnd/OMEROMatlab/libs/log4j.jar


# Download bio-formats Matlab toolbox
curl -OL http://downloads.openmicroscopy.org/latest/bio-formats$OME/artifacts/bfmatlab.zip

unzip bfmatlab.zip
rm bfmatlab.zip
mv bfmatlab/* FLIMfitFrontEnd/BFMatlab/
rm -rf bfmatlab

# Download ini4j.jar
curl -OL http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-0.3.2.jar
mv ini4j-0.3.2.jar FLIMfitFrontEnd/OMEROMatlab/libs/ini4j.jar