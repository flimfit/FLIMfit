#!/bin/bash

if [ -z ${OME+x} ]; then export OME=5.2; echo "Setting OME=5.1"; fi
if [ -z ${BIO+x} ]; then export BIO=5.1; echo "Setting BIO=5.1"; fi

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2015b; echo "Setting MATLAB_VER=R2015b"; fi

export CC=/usr/local/bin/gcc-5
export CXX=/usr/local/bin/g++-5

echo "Cleaning CMake Project..."
cd GeneratedProjects
rm -rf Unix
mkdir -p Unix
cd Unix

echo "Generating CMake Project..."
cmake ../../ -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=RELEASE \
   -DFLIMreaderMEX_OUT_DIR=../../FLIMfitFrontEnd

echo "Building Project..."
make

cd ../../

export PATH=/Applications/MATLAB_${MATLAB_VER}.app/bin:$PATH
# compile the Matlab code to generate the FLIMfit_MACI64.app
cd FLIMfitFrontEnd

if [ -z ${VERSION+x} ]; then export VERSION=$(git describe); fi
echo "VERSION = $VERSION"

build_name=FLIMfit_${VERSION}_OME_${OME}_b${BUILD_NUMBER}_MACI64

cur_dir=$(grealpath .)
matlab -nodisplay -nosplash -r "cd('${cur_dir}'); compile $VERSION; exit"

cd ../FLIMfitStandalone/BuiltApps
zip -r FLIMfit_${VERSION}_MACI64.zip *.app/
cd ../..

#zip gcc_libs.zip ./FLIMfit\ ${VERSION}.app/Contents/Resources/*.dylib

