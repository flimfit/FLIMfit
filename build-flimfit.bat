echo Compiling front end
echo Please wait for MATLAB to load

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2019b

"C:\Program Files\MATLAB\%MATLAB_VER%\bin\matlab.exe" -nosplash -nodesktop -wait -log compile_output.txt -r "cd('%CD%\FLIMfitFrontEnd'); compile(true); quit();"
