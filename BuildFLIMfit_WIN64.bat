@echo off

set MATLABVER=R2013a

echo Building libraries

cd FLIMfitLibrary
call Build_Win64.bat
cd ..

echo Compiling front end
echo Please wait for MATLAB to load

cd FLIMfitFrontEnd
"C:\Program Files\MATLAB\%MATLABVER%\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('compile.m');"

echo Finished build

cd ..