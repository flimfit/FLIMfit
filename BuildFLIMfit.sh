#!/bin/bash

if [ -z ${MATLAB_VER+x} ]; then export MATLAB_VER=R2017b; echo "Setting MATLAB_VER=R2017b"; fi

# Build FlimReader Mex file
#--------------------------------------------
project_dir=GeneratedProjects/FlimReaderUnix

echo "Cleaning CMake Project..."
rm -rf ${project_dir}
mkdir -p ${project_dir}

cur_dir=$(grealpath .)

echo "Generating CMake Project..."
if ! cmake -HFLIMfitLibrary/FLIMreader -B${project_dir} -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
   -DFlimReaderMEX_OUT_DIR=${cur_dir}/FLIMfitLibrary/Libraries/; then 
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

export CC=/usr/local/bin/gcc-7
export CXX=/usr/local/bin/g++-7

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

exit 0;

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