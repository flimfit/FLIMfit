#!/bin/bash

if [ -z ${OME+x} ]; then export OME=5.3; echo "Setting OME=5.3"; fi
if [ -z ${BIO+x} ]; then export BIO=5.5; echo "Setting BIO=5.5"; fi

export CC=/usr/local/bin/gcc-7
export CXX=/usr/local/bin/g++-7
export MACOSX_DEPLOYMENT_TARGET=10.9.5

echo "Checking for homebrew install..."
(brew update | grep "command not found") \
	&& rruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
	|| echo "Homebrew installed"

echo "Ensure cmake, gcc and boost are installed..."
# Ensure gcc, ghostscript, cmake, LAPACK are installed using Homebrew
(brew list | grep gcc) || brew install gcc --without-multilib
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript
(brew list | grep cmake) && echo " installed" || brew install cmake
(brew list | grep platypus) && echo " installed" || brew install platypus
(brew list | grep lapack) && echo " installed" || brew install lapack
(brew list | grep coreutils) && echo " installed" || brew install coreutils
brew upgrade cmake

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
curl -OL http://downloads.openmicroscopy.org/latest/bio-formats$BIO/artifacts/bfmatlab.zip

# Unpack the toolbox
unzip -o bfmatlab.zip
rm bfmatlab.zip

# Massage bioformats_package.jar to exclude the SLF4J bindings
# See: https://github.com/flimfit/FLIMfit/issues/299
zip -d bfmatlab/bioformats_package.jar 'org/slf4j/impl/*'

# Install toolbox files into FLIMfit
mv bfmatlab/* FLIMfitFrontEnd/BFMatlab/
rm -rf bfmatlab

# Download ini4j.jar
curl -OL http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-0.3.2.jar
mv ini4j-0.3.2.jar FLIMfitFrontEnd/OMEROMatlab/libs/ini4j.jar

# Download omeUiUtils
curl -OL https://dl.bintray.com/imperial-photonics/omeUiUtils/OMEuiUtils-0.1.6.jar
mv OMEuiUtils-0.1.5.jar FLIMfitFrontEnd/OMEuiUtils/OMEuiUtils.jar
