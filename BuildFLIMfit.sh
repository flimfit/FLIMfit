#!/bin/bash

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2016b; echo "Setting MATLAB_VER=R2016b"; fi

triplet=x64-osx
toolchain_file=${VCPKG_ROOT}\scripts\buildsystems\vcpkg.cmake

# Build FlimReader Mex file
#--------------------------------------------
project_dir=GeneratedProjects/FlimReaderUnix

echo "Cleaning CMake Project..."
rm -rf ${project_dir}
mkdir -p ${project_dir}

cur_dir=$(grealpath .)

echo "Generating CMake Project..."
if ! cmake -HFLIMfitLibrary/FLIMreader -B${project_dir} -G "Unix Makefiles" \
   -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_TOOLCHAIN_FILE="${toolchain_file}" -DVCPKG_TARGET_TRIPLET=${triplet} \
   -DFlimReaderMEX_OUT_DIR=${cur_dir}/FLIMfitFrontEnd/Libraries/; then 
   echo 'Error generating project'
   exit 1
fi

echo "Building Project..."
if ! cmake --build ${project_dir}; then
    echo 'Error building project'
    exit 1
fi

# Build FLIMfit library
#--------------------------------------------

export CC=/usr/local/bin/gcc-8
export CXX=/usr/local/bin/g++-8

echo "Cleaning CMake Project..."
rm -rf GeneratedProjects/Unix
mkdir -p GeneratedProjects/Unix

cur_dir=$(grealpath .)

echo "Generating CMake Project..."
if ! cmake -H. -BGeneratedProjects/Unix -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=RELEASE; then 
   echo 'Error generating project'
   exit 1
fi

echo "Building Project..."
if ! cmake --build GeneratedProjects/Unix; then
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
