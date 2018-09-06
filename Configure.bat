@echo off

IF DEFINED INSTALL_REQUIRED (
	:: Please install chocolatey first from : https://chocolatey.org/
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

:: vcpkg install opencv[core,tiff]:x64-windows-static boost:x64-windows-static dlib:x64-windows-static
