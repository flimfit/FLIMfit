#!/bin/bash

#
# Using the Mex files - make sure to remove Qt libs from Matlab_R20XXb/bin/maci64
# For llvm debugging, brew -unlink python
#

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2018b; echo "Setting MATLAB_VER=R2018b"; fi

export CXX=/usr/bin/clang++
export CC=/usr/bin/clang
export MKLROOT=/opt/intel/mkl

[ "$1" == "--clean" ] && rm -rf GeneratedProjects/Unix
if ! cmake -GNinja -H. -BGeneratedProjects/Unix; then
   echo 'Error configuring project'
   exit 1
fi

if ! cmake --build "GeneratedProjects/Unix" --config RelWithDebInfo; then
    echo 'Error building project'
    exit 1
fi

export PATH=/Applications/MATLAB_${MATLAB_VER}.app/bin:$PATH
# compile the Matlab code to generate the FLIMfit_MACI64.app
cd FLIMfitFrontEnd

if [ -z ${VERSION+x} ]; then export VERSION=$(git describe); fi
echo "VERSION = $VERSION"

rm -rf ../FLIMfitStandalone/BuiltApps/*.app

cur_dir=$(grealpath .)
if ! matlab -nodisplay -nosplash -r "cd('${cur_dir}'); compile(true); exit"; then
    echo 'Error building frontend'
    exit 1
fi

cd ../FLIMfitStandalone/BuiltApps
zip -r FLIMfit_${VERSION}_MACI64.zip *.app/
cd ../..

echo "Build complete"
