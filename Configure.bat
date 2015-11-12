@echo off

IF NOT DEFINED OME SET OME=5.1
IF NOT DEFINED MSVC_VER SET MSVC_VER=12
IF NOT DEFINED BOOST_VER_MAJOR SET BOOST_VER_MAJOR=1
IF NOT DEFINED BOOST_VER_MINOR SET BOOST_VER_MINOR=59

:: Install Chocolatey
choco.exe 2> NUL
if ERRORLEVEL 9009 @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

:: Install cmake, gs and curl, 7zip to download Boost, OMERO stuff
choco install curl 7zip.commandline cmake.portable -y

:: The following packages must be installed as admin
IF NOT DEFINED NOADMIN (
	choco install innosetup -y
	choco install ghostscript.app -y -version 9.16

	:: Install Inno Downloader
	curl -LO http://www.sherlocksoftware.org/innotools/files/itd0.3.5.exe
	itd0.3.5.exe /silent
	del itd0.3.5.exe

	:: Check if requested version of Visual Studio is installed
	echo H: !VS%MSVC_VER%0COMNTOOLS!
	IF NOT DEFINED VS%MSVC_VER%0COMNTOOLS (
		IF MSVC_VER==14	( choco install visualstudio2015community -y  -packageParameters "--Features MDDCPlusPlus"
		) ELSE (
			IF MSVC_VER==12 ( choco install visualstudio2013community -y
			) ELSE (
				IF MSVC_VER==11 (choco install visualstudio2012wdx -y
				) ELSE ( 
					choco install visualstudio2015community -y  -packageParameters "--Features MDDCPlusPlus"
					SET MSVC_VER=14
				)
			)
		)
	)
	Endlocal & SET MSVC_VER=%MSVC_VER%

)


SET REDIST_STR=%PROGRAMFILES(x86)%\Microsoft Visual Studio %MSVC_VER%.0\VC\redist\*
FOR /D %%G in ("%REDIST_STR%") DO (
	@ECHO %%G\vcredist_x64.exe>FLIMfitLibrary\VisualStudioRedistributablePath.txt
	goto skip
)
:skip


:: Setup Boost
SET BOOST_URL=http://sourceforge.net/projects/boost/files/boost-binaries/%BOOST_VER_MAJOR%.%BOOST_VER_MINOR%.0/boost_%BOOST_VER_MAJOR%_%BOOST_VER_MINOR%_0-msvc-%MSVC_VER%.0-64.exe/download
SET BOOST_ROOT=c:\local\boost_%BOOST_VER_MAJOR%_%BOOST_VER_MINOR%_0\
SET BOOST_LIBRARYDIR=%BOOST_ROOT%lib64-msvc-%MSVC_VER%.0\
SETX BOOST_ROOT c:\local\boost_%BOOST_VER_MAJOR%_%BOOST_VER_MINOR%_0\
SETX BOOST_LIBRARYDIR %BOOST_ROOT%lib64-msvc-%MSVC_VER%.0\



:: Check if boost is installed and install if not
if exist %BOOST_LIBRARYDIR% (
	echo Boost already installed
) else (
	echo About to download and install Boost from: %BOOST_URL%
	curl -L %BOOST_URL% -oboost-installer.exe
	boost-installer.exe /silent
	del boost-installer.exe
)


SET OMERO_LIBS_FOLDER=FLIMfitFrontEnd\OMEROMatlab\libs\

echo Downloading %OME% version of OMERO.matlab
curl -OL http://downloads.openmicroscopy.org/latest/omero%OME%/matlab.zip
7z.exe x matlab.zip -aoa -oFLIMfitFrontEnd/OMEROMatlab/ 
del matlab.zip

for /f %%i in ('dir FLIMfitFrontEnd\OMEROMatlab\ /ad /b') do set OMERO_FOLDER=%%i
echo del matlab.zip
xcopy FLIMfitFrontEnd\OMEROMatlab\%OMERO_FOLDER%\* FLIMfitFrontEnd\OMEROMatlab\ /E /Y

echo remove sl4j-api.jar to avoid LOGGER clashes
del %OMERO_LIBS_FOLDER%\slf4j-log4j12.jar
del %OMERO_LIBS_FOLDER%\slf4j-api.jar
del %OMERO_LIBS_FOLDER%\log4j.jar


echo Downloading %OME% version of bfmatlab
curl -OL http://downloads.openmicroscopy.org/latest/bio-formats%OME%/artifacts/bfmatlab.zip
7z.exe x bfmatlab.zip -aoa -oFLIMfitFrontEnd/BFMatlab/
xcopy FLIMfitFrontEnd\BFMatlab\bfmatlab\* FLIMfitFrontEnd\BFMatlab\ /E /Y
del bfmatlab.zip

:: Download ini4j.jar
curl -L http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-0.3.2.jar -o%OMERO_LIBS_FOLDER%ini4j.jar

