@echo off

SET BOOST_URL=http://sourceforge.net/projects/boost/files/boost-binaries/1.59.0/boost_1_59_0-msvc-12.0-64.exe/download
SET OME=5.1

rem Install Chocolatey
choco.exe 2> NUL
if ERRORLEVEL 9009 @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

choco install curl 7zip -y

if exist c:\local\boost_1_59_0\lib64-msvc-12.0\ (
	echo Boost already installed
) else (
	echo About to download and install Boost

	rem Download and install Boost library
	curl -L %BOOST_URL% -o boost-installer.exe
	boost-installer.exe /silent
	del boost-installer.exe
)

echo Downloading %OME% version of OMERO.matlab
echo curl -OL http://downloads.openmicroscopy.org/latest/omero%OME%/matlab.zip
"%ProgramFiles%\7-Zip\7z.exe" x matlab.zip -aoa -oFLIMfitFrontEnd/OMEROMatlab/ 

for /f %%i in ('dir FLIMfitFrontEnd\OMEROMatlab\ /ad /b') do set OMERO_FOLDER=%%i
echo del matlab.zip
xcopy FLIMfitFrontEnd\OMEROMatlab\%OMERO_FOLDER%\* FLIMfitFrontEnd\OMEROMatlab\ /E /Y

echo remove sl4j-api.jar to avoid LOGGER clashes
del FLIMfitFrontEnd\OMEROMatlab\libs\slf4j-log4j12.jar
del FLIMfitFrontEnd\OMEROMatlab\libs\slf4j-api.jar
del FLIMfitFrontEnd\OMEROMatlab\libs\log4j.jar

echo "Downloading %OME% version of bfmatlab
echo curl -OL http://downloads.openmicroscopy.org/latest/bio-formats%OME%/artifacts/bfmatlab.zip
"%ProgramFiles%\7-Zip\7z.exe" x bfmatlab.zip -aoa -oFLIMfitFrontEnd/BFMatlab/
xcopy FLIMfitFrontEnd\BFMatlab\bfmatlab\* FLIMfitFrontEnd\BFMatlab\ /E /Y

rem Download ini4j.jar
curl -L http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-0.3.2.jar -oFLIMfitFrontEnd/OMEROMatlab/libs/ini4j-0.3.2.jar
