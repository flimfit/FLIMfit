@echo off

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=2015a

echo Building libraries

cd FLIMfitLibrary
call Build_WIN.bat
cd ..

echo Compiling front end
echo Please wait for MATLAB to load

cd FLIMfitFrontEnd
::"%ProgramFiles%\MATLAB\R%MATLAB_VER%\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('compile.m');"

echo Finished build

cd ..