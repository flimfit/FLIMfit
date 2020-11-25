@echo off

SETLOCAL

SET ROOT=%~dp0

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2019b
IF NOT DEFINED MSVC_VER SET MSVC_VER=16

if %MSVC_VER%==15 SET MSVC_YEAR=2017
if %MSVC_VER%==16 SET MSVC_YEAR=2019

IF NOT DEFINED TRIPLET SET TRIPLET=x64-windows-static

if %MSVC_VER%==15 (set GENERATOR="Visual Studio %MSVC_VER% Win64"
) else set GENERATOR="Visual Studio %MSVC_VER% %MSVC_YEAR%"



:: SET FEED_URL=https://pkgs.dev.azure.com/FLIMfit/FLIMfit/_packaging/vcpkg/nuget/v3/index.json
:: if NOT DEFINED VCPKG_BINARY_SOURCES SET VCPKG_BINARY_SOURCES=nuget,%FEED_URL%,read

:: Build main library
echo Cleaning CMake Project
SET PROJECT_DIR=GeneratedProjects\MSVC%MSVC_VER%_64

if "%1"=="--clean" rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
echo Generating CMake Project in: %PROJECT_DIR%, using %GENERATOR%
cmake -G %GENERATOR% -H. -B%PROJECT_DIR% -DVCPKG_TARGET_TRIPLET=%TRIPLET%
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%
echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR% --config Release
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

:: Build FlimReader mex file
echo Cleaning CMake Project
SET PROJECT_DIR=GeneratedProjects\MSVC%MSVC_VER%_64_FLIMreader
if "%1"=="--clean" rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
echo Generating CMake Project in: %PROJECT_DIR%, using %GENERATOR%
cmake -G %GENERATOR% -HFLIMfitLibrary\FLIMreader -B%PROJECT_DIR% -DNO_CUDA=1^
      -DVCPKG_TARGET_TRIPLET=%TRIPLET% -DMSVC_CRT_LINKAGE=static -DFlimReaderMEX_OUT_DIR="%CD%\FLIMfitFrontEnd\Libraries"^
      -DCMAKE_TOOLCHAIN_FILE=%ROOT%vcpkg/scripts/buildsystems/vcpkg.cmake
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%
echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR% --config Release
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%


echo Compiling front end
echo Please wait for MATLAB to load

"C:\Program Files\MATLAB\%MATLAB_VER%\bin\matlab.exe" -nosplash -nodesktop -wait^
   -log compile_output.txt -r "cd('%CD%\FLIMfitFrontEnd'); compile(true); quit();"
