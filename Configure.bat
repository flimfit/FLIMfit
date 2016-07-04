@echo off

IF NOT DEFINED OME SET OME=5.2
IF NOT DEFINED BIO SET BIO=5.1
IF NOT DEFINED MSVC_VER SET MSVC_VER=14
IF NOT DEFINED BOOST_VER_MAJOR SET BOOST_VER_MAJOR=1
IF NOT DEFINED BOOST_VER_MINOR SET BOOST_VER_MINOR=59

:: Install Chocolatey
choco.exe 2> NUL
if ERRORLEVEL 9009 @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

:: Install cmake, gs and OMERO stuff
choco install cmake.portable -y

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
