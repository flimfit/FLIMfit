@echo off

SETLOCAL

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2016b

SET PATH=%PATH%;%VCPKG_ROOT%\installed\x64-windows\bin;%VCPKG_ROOT%\installed\x64-windows\debug\bin
SET TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
SET TOOLCHAIN_FILE=%TOOLCHAIN_FILE:\=/%

echo Cleaning CMake Project
<<<<<<< HEAD
SET PROJECT_DIR=GeneratedProjects\MSVC15_64
echo rmdir %PROJECT_DIR% /s /q
echo mkdir %PROJECT_DIR%

echo Generating CMake Project in: %PROJECT_DIR%
cmake -G "Visual Studio 15 Win64" -H. -B%PROJECT_DIR% -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%"
=======
SET PROJECT_DIR=GeneratedProjects\MSVC%MSVC_VER%_64
REM rmdir %PROJECT_DIR% /s /q
mkdir %PROJECT_DIR%
cd %PROJECT_DIR%

echo Setting up vcpkg paths
SET PATH=%PATH%;%VCPKG_ROOT%\installed\x64-windows\bin;%VCPKG_ROOT%\installed\x64-windows\debug\bin
SET TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
SET TOOLCHAIN_FILE=%TOOLCHAIN_FILE:\=/%

if %MSVC_VER%==15 (set GENERATOR="Visual Studio %MSVC_VER% Win64"
) else set GENERATOR="Visual Studio %MSVC_VER% %MSVC_YEAR% Win64"

echo Generating CMake Project in: %PROJECT_DIR%
echo Using Generator: %GENERATOR%
cmake -G %GENERATOR% ..\..\ -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%"
>>>>>>> origin/intensity-normalisation

echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR%  --config Release
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

echo Compiling front end
echo Please wait for MATLAB to load

SET REDIST_STR=%PROGRAMFILES(x86)%\Microsoft Visual Studio\2017\Community\VC\Redist\MSVC\14.11.25325
ECHO %REDIST_STR%\vcredist_x64.exe>FLIMfitLibrary\VisualStudioRedistributablePath.txt

"C:\Program Files\MATLAB\%MATLAB_VER%\bin\matlab.exe" -nosplash -nodesktop -wait -log compile_output.txt -r "cd('%CD%\FLIMfitFrontEnd'); compile(true); quit();"
