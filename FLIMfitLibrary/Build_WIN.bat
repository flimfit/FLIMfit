::@echo off
Setlocal EnableDelayedExpansion

IF NOT DEFINED MSVC_VER SET MSVC_VER=12

if %MSVC_VER%==11 SET MSVC_YEAR=2012
if %MSVC_VER%==12 SET MSVC_YEAR=2013
if %MSVC_VER%==14 SET MSVC_YEAR=2015

set GENERATOR="Visual Studio %MSVC_VER% %MSVC_YEAR% Win64"

echo Adding Visual Studio to path
call "!VS%MSVC_VER%0COMNTOOLS!\vsvars32.bat"


echo Cleaning CMake Project
SET PROJECT_DIR=GeneratedProjects\MCVC%MSVC_VER%_64
rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
cd %PROJECT_DIR%


echo Generating CMake Project in: %PROJECT_DIR%
echo Using Generator: %GENERATOR%
cmake ..\..\ -G %GENERATOR%


echo Build 64 bit Project in Release mode
msbuild "FLIMfit.sln" /property:Configuration=Release
cd "..\..\"


