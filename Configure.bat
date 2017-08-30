@echo off

IF NOT DEFINED MSVC_VER SET MSVC_VER=15

:: Install Chocolatey
choco.exe 2> NUL
if ERRORLEVEL 9009 @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

:: Install cmake, gs and OMERO stuff

:: The following packages must be installed as admin
IF NOT DEFINED NOADMIN (
   choco install cmake.install
	choco install innosetup -y
	choco install ghostscript.app -y -version 9.16

	:: Install Inno Downloader
	curl -LO http://www.sherlocksoftware.org/innotools/files/itd0.3.5.exe
	itd0.3.5.exe /silent
	del itd0.3.5.exe
	)
	Endlocal & SET MSVC_VER=%MSVC_VER%

)

SET REDIST_STR=%PROGRAMFILES(x86)%\Microsoft Visual Studio %MSVC_VER%.0\VC\redist\*
FOR /D %%G in ("%REDIST_STR%") DO (
	@ECHO %%G\vcredist_x64.exe>FLIMfitLibrary\VisualStudioRedistributablePath.txt
	goto skip
)
:skip
