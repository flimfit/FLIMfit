@echo off

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2015b
IF NOT DEFINED MSVC_VER SET MSVC_VER=14
IF NOT DEFINED BOOST_ROOT SET BOOST_ROOT=c:\local\boost_%BOOST_VER_MAJOR%_%BOOST_VER_MINOR%_0\

SET BOOST_LIBRARYDIR=%BOOST_ROOT%lib64-msvc-%MSVC_VER%.0\
echo BOOST_LIBRARYDIR = %BOOST_LIBRARYDIR%

if %MSVC_VER%==11 SET MSVC_YEAR=2012
if %MSVC_VER%==12 SET MSVC_YEAR=2013
if %MSVC_VER%==14 SET MSVC_YEAR=2015

if NOT DEFINED VERSION FOR /F "delims=" %%i IN ('git describe') DO set VERSION=%%i

Setlocal EnableDelayedExpansion
SET VS_PATH="!VS%MSVC_VER%0COMNTOOLS!vsvars32.bat"
EndLocal & SET VS_PATH=%VS_PATH%

echo Adding Visual Studio to path
call %VS_PATH%

echo Cleaning CMake Project
SET PROJECT_DIR=GeneratedProjects\MSVC%MSVC_VER%_64
rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
cd %PROJECT_DIR%

set GENERATOR="Visual Studio %MSVC_VER% %MSVC_YEAR% Win64"
echo Generating CMake Project in: %PROJECT_DIR%
echo Using Generator: %GENERATOR%
cmake -G %GENERATOR% ..\..\


echo Building 64bit Project in Release mode
msbuild "FLIMfit.sln" /property:Configuration=Release
cd "..\..\"


echo Compiling front end
echo Please wait for MATLAB to load

cd FLIMfitFrontEnd
"C:\Program Files\MATLAB\%MATLAB_VER%\bin\matlab.exe" -nosplash -nodesktop -wait -log compile_output.txt -r "cd('%CD%'); compile %VERSION%; quit();"

cd ..
