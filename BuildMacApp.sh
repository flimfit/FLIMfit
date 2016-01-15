
OME=5.1
MATLAB_VER=R2015b

export PATH=/Applications/MATLAB_${MATLAB_VER}.app/bin:$PATH
# compile the Matlab code to generate the FLIMfit_MACI64.app
cd FLIMfitFrontEnd
OLDVER="$(cat GeneratedFiles/version.txt)"
VERSION=$(git describe)

matlab -nodisplay -nosplash -r "compile $VERSION; exit"


cd FLIMfitStandalone/FLIMfit_${OLDVER}_MACI64
zip -r FLIMfit_${VERSION}_OME_${OME}_b${BUILD_NUMBER}_MACI64.zip *.app/

zip gcc_libs.zip ./FLIMfit\ ${VERSION}.app/Contents/Resources/*.dylib
