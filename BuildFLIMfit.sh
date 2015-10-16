
OME=5.1
WORKSPACE=.
PROJECT_TYPE=xcode

# Make sure we compile with gcc-4.9
export CC=/usr/local/bin/clang-omp
export CXX=/usr/local/bin/clang-omp++

cd FLIMfitLibrary/GeneratedProjects

echo "Cleaning 64 bit CMake Project..."
rm -rf ${PROJECT_TYPE}
mkdir -p ${PROJECT_TYPE}
cd ${PROJECT_TYPE}

echo "Generating 64 bit CMake Project..."
cmake ../../ -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=RELEASE

echo "Building 64 bit Project..."
make

#THIRD 
