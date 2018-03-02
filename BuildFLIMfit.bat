@echo off

SETLOCAL

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2017b
IF NOT DEFINED MSVC_VER SET MSVC_VER=15

if %MSVC_VER%==11 SET MSVC_YEAR=2012
if %MSVC_VER%==12 SET MSVC_YEAR=2013
if %MSVC_VER%==14 SET MSVC_YEAR=2015
if %MSVC_VER%==15 SET MSVC_YEAR=2017

echo Setting up vcpkg paths
SET PATH=%PATH%;%VCPKG_ROOT%\installed\x64-windows\bin;%VCPKG_ROOT%\installed\x64-windows\debug\bin
SET TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
SET TOOLCHAIN_FILE=%TOOLCHAIN_FILE:\=/%

if %MSVC_VER%==15 (set GENERATOR="Visual Studio %MSVC_VER% Win64"
) else set GENERATOR="Visual Studio %MSVC_VER% %MSVC_YEAR% Win64"

:: Build main library
echo Cleaning CMake Project
SET PROJECT_DIR=GeneratedProjects\MSVC%MSVC_VER%_64
rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
echo Generating CMake Project in: %PROJECT_DIR%, using %GENERATOR%
cmake -G %GENERATOR% -H. -B%PROJECT_DIR% -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%"
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%
echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR% --config Release
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

:: Build FlimReader mex file
echo Cleaning CMake Project
SET PROJECT_DIR=GeneratedProjects\MSVC%MSVC_VER%_64_FLIMreader
rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
echo Generating CMake Project in: %PROJECT_DIR%, using %GENERATOR%
cmake -G %GENERATOR% -HFLIMfitLibrary\FLIMreader -B%PROJECT_DIR% -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%" -DFlimReaderMEX_OUT_DIR="%CD%\FLIMfitLibrary\Libraries\"
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%
echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR% --config Release
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%


echo Compiling front end
echo Please wait for MATLAB to load

"C:\Program Files\MATLAB\%MATLAB_VER%\bin\matlab.exe" -nosplash -nodesktop -wait -log compile_output.txt -r "cd('%CD%\FLIMfitFrontEnd'); compile(true); quit();"
