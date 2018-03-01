#!/bin/bash

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2017b; echo "Setting MATLAB_VER=R2017b"; fi

export CC=/usr/local/bin/gcc-7
export CXX=/usr/local/bin/g++-7

export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++

echo "Cleaning CMake Project..."
#rm -rf GeneratedProjects/Unix
#mkdir -p GeneratedProjects/Unix

cur_dir=$(grealpath .)

echo "Generating CMake Project..."
if ! cmake -H. -BGeneratedProjects/Unix -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=RELEASE \
   -DFlimReaderMEX_OUT_DIR=${cur_dir}/FLIMfitLibrary/Libraries/; then 
   echo 'Error generating project'
   exit 1
fi

echo "Building Project..."
if ! cmake --build GeneratedProjects/Unix --config Release; then
    echo 'Error building project'
    exit 1
fi

export PATH=/Applications/MATLAB_${MATLAB_VER}.app/bin:$PATH
# compile the Matlab code to generate the FLIMfit_MACI64.app

if [ -z ${VERSION+x} ]; then export VERSION=$(git describe); fi
echo "VERSION = $VERSION"

rm -rf FLIMfitStandalone/BuiltApps/*.app

cur_dir=$(grealpath .)
if ! matlab -nodisplay -nosplash -r "cd('${cur_dir}/FLIMfitFrontEnd'); compile(true); exit"; then
    echo 'Error building frontend'
    exit 1
fi

cd FLIMfitStandalone/BuiltApps
zip -r FLIMfit_${VERSION}_MACI64.zip *.app/
cd ../..

echo "Build complete"