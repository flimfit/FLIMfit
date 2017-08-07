#!/bin/bash

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2016b; echo "Setting MATLAB_VER=R2016b"; fi


export CC=/usr/local/bin/gcc-5
export CXX=/usr/local/bin/g++-5
export MACOSX_DEPLOYMENT_TARGET=10.9.5

echo "Cleaning CMake Project..."
cd GeneratedProjects
rm -rf Unix
mkdir -p Unix
cd Unix

echo "Generating CMake Project..."
cmake ../../ -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=RELEASE \
   -DFLIMreaderMEX_OUT_DIR=../../FLIMfitFrontEnd

echo "Building Project..."
cmake --build . --config Release

if ! cmake --build . --config Release; then
    echo 'Error building project'
    exit 1
fi

cd ../../

export PATH=/Applications/MATLAB_${MATLAB_VER}.app/bin:$PATH
# compile the Matlab code to generate the FLIMfit_MACI64.app
cd FLIMfitFrontEnd

if [ -z ${VERSION+x} ]; then export VERSION=$(git describe); fi
echo "VERSION = $VERSION"

cur_dir=$(grealpath .)
if ! matlab -nodisplay -nosplash -r "cd('${cur_dir}'); compile(true); exit"; then
    echo 'Error building frontend'
    exit 1
fi

cd ../FLIMfitStandalone/BuiltApps
zip -r FLIMfit_${VERSION}_MACI64.zip *.app/
cd ../..

echo "Build complete"