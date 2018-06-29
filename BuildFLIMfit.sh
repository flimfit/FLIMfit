#!/bin/bash

#
# Using the Mex files - make sure to remove Qt libs from Matlab_R20XXb/bin/maci64
# For llvm debugging, brew -unlink python
#

if [ -z ${OME+x} ]; then export OME=5.2; echo "Setting OME=5.2"; fi
if [ -z ${BIO+x} ]; then export BIO=5.2; echo "Setting BIO=5.2"; fi

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2017b; echo "Setting MATLAB_VER=R2017b"; fi

export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++
export LDFLAGS="-L/usr/local/opt/llvm/lib -Wl,-rpath,/usr/local/opt/llvm/lib"

export PATH="/usr/local/opt/qt5/bin:$PATH"

rm -rf GeneratedProjects/Unix
if ! cmake -G"Unix Makefiles" -H. -BGeneratedProjects/Unix -DTOOLCHAIN_FILE=${TOOLCHAIN_FILE} -DBUILD_OPENCV:bool=TRUE; then
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

rm ../FLIMfitStandalone/BuiltApps/*.app

cur_dir=$(grealpath .)
if ! matlab -nodisplay -nosplash -r "cd('${cur_dir}'); compile(true); exit"; then
    echo 'Error building frontend'
    exit 1
fi

cd ../FLIMfitStandalone/BuiltApps
zip -r FLIMfit_${VERSION}_MACI64.zip *.app/
cd ../..

echo "Build complete"