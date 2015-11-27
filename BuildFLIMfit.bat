set PATH=C:\CYGWIN64\BIN;%PATH%
echo "About to Download Boost Library"
rem Download Boost library
curl -L %BOOST_URL% -o boost.tar.gz
tar xvf boost.tar.gz
rem tar -zxvf boost.tar.gz --wildcards "*.hpp"
rem tar -zxvf boost.tar.gz --wildcards "*.h"
rem tar -zxvf boost.tar.gz --wildcards "*.ipp"
rm boost.tar.gz
sh -c "mv -v boost_*/boost FLIMfitLibrary/Boost/ && rm -rf boost_*"
rem Download OMERO Matlab plug-in
echo OME=%OME%
echo WS=%WORKSPACE%
set
echo "Downloading %OME% version of OMERO.matlab
curl -OL http://downloads.openmicroscopy.org/latest/omero%OME%/matlab.zip
unzip matlab.zip
rm matlab*.zip
sh -c "mv -v OMERO.matlab-*/* FLIMfitFrontEnd/OMEROMatlab/"
rm -rf OMERO.matlab*"
rem remove sl4j-api.jar to avoid LOGGER clashes
rm FLIMfitFrontEnd/OMEROMatlab/libs/slf4j-log4j12.jar
rm FLIMfitFrontEnd/OMEROMatlab/libs/slf4j-api.jar
rm FLIMfitFrontEnd/OMEROMatlab/libs/log4j.jar
rem Download bio-formats Matlab toolbox
echo "Downloading %OME% version of bfmatlab
curl -OL http://downloads.openmicroscopy.org/latest/bioformats%
OME%/artifacts/bfmatlab.zip
unzip bfmatlab.zip
rm bfmatlab.zip
sh -c "mv -v bfmatlab/* FLIMfitFrontEnd/BFMatlab/
rm -rf bfmatlab
rem Download ini4j.jar
curl -OL
http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-
0.3.2.jar
sh -c "mv ini4j-0.3.2.jar FLIMfitFrontEnd/OMEROMatlab/libs/ini4j.jar"
See the