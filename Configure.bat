@echo off

:: Install cmake, gs and OMERO stuff
IF NOT DEFINED NOADMIN (

	:: Install Chocolatey
	choco.exe -v 2> NUL	
	if ERRORLEVEL 9009 @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
	SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

   :: The following packages must be installed as admin
   choco install curl -y
   choco install cmake.portable -y
	choco install innosetup -y
	choco install ghostscript.app -y -version 9.16

	:: Install Inno Downloader
	curl -LO https://bitbucket.org/mitrich_k/inno-download-plugin/downloads/idpsetup-1.5.1.exe
	idpsetup-1.5.1.exe /silent
	del idpsetup-1.5.1.exe
)

