#!/bin/bash

OME=5.1
MATLAB_VER=R2015b
PROJECT_TYPE=Unix

export CC=/usr/local/bin/gcc-4.9
export CXX=/usr/local/bin/g++-4.9

echo "Cleaning CMake Project..."
cd GeneratedProjects
rm -rf ${PROJECT_TYPE}
mkdir -p ${PROJECT_TYPE}
cd ${PROJECT_TYPE}

echo "Generating CMake Project..."
cmake ../../ -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=RELEASE \
   -DFLIMreaderMEX_OUT_DIR=../../FLIMfitFrontEnd \
   -DCMAKE_XCODE_ATTRIBUTE_GCC_VERSION=/usr/local/bin/clang-omp++

echo "Building Project..."
make

exit  

cd ../../

export PATH=/Applications/MATLAB_${MATLAB_VER}.app/bin:$PATH
# compile the Matlab code to generate the FLIMfit_MACI64.app
cd FLIMfitFrontEnd
OLDVER="$(cat GeneratedFiles/version.txt)"
VERSION=$(git describe)

matlab -nodisplay -nosplash -r "compile $VERSION; exit"


cd FLIMfitStandalone/FLIMfit_${OLDVER}_MACI64
zip -r FLIMfit_${VERSION}_OME_${OME}_b${BUILD_NUMBER}_MACI64.zip *.app/

zip clang_libs.zip ./FLIMfit\ ${VERSION}.app/Contents/Resources/*.dylib
