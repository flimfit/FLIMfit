@echo off

set MATLABVER=R2013a

REM cd FLIMfitLibrary
REM Build_Win64
REM Build_Win32
REM cd ..

cd FLIMfitFrontEnd
"C:\Program Files\MATLAB\%MATLABVER%\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('compile.m');exit;"
"C:\Program Files (x86)\MATLAB\%MATLABVER%\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('compile.m');exit;"