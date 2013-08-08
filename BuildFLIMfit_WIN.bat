@echo off

set MATLABVER=R2013a

cd GlobalProcessingLibrary
Build_Win64
Build_Win32
cd ..

cd GlobalProcessingFrontEnd
"C:\Program Files\MATLAB\$MATLABVER$\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('compile.m');exit;"
"C:\Program Files (x86)\MATLAB\$MATLABVER$\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('compile.m');exit;"