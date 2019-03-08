@echo off

SETLOCAL

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2018b

SET TRIPLET=x64-windows-flimfit
SET PATH=%PATH%;%VCPKG_ROOT%\installed\%TRIPLET%\bin;%VCPKG_ROOT%\installed\%TRIPLET%\debug\bin
SET TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake

SET PROJECT_DIR=GeneratedProjects\MSVC15_64
IF "%1"=="--clean" (
   echo Cleaning CMake Project
   rmdir %PROJECT_DIR% /s /q
   mkdir %PROJECT_DIR%
)

echo Generating CMake Project in: %PROJECT_DIR%
cmake -G "Visual Studio 15 Win64" -H. -B%PROJECT_DIR% -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%" -DNO_CUDA=1 -DVCPKG_TARGET_TRIPLET=%TRIPLET%
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR%  --config RelWithDebInfo
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

echo Compiling front end
echo Please wait for MATLAB to load

SET REDIST_STR=%PROGRAMFILES(x86)%\Microsoft Visual Studio\2017\Community\VC\Redist\MSVC\14.11.25325
ECHO %REDIST_STR%\vcredist_x64.exe>FLIMfitLibrary\VisualStudioRedistributablePath.txt

"C:\Program Files\MATLAB\%MATLAB_VER%\bin\matlab.exe" -nosplash -nodesktop -wait -log compile_output.txt -r "cd('%CD%\FLIMfitFrontEnd'); compile(true); quit();"
