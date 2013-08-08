@echo off

REM %VS110COMNTOOLS%vsvars32.bat

echo Clean 32 bit CMake Project
rmdir GeneratedProjects\MCVC11_32 /s /q
mkdir GeneratedProjects\MCVC11_32
cd GeneratedProjects\MCVC11_32

echo Generate 32 bit CMake Project
cmake ..\..\ -G "Visual Studio 11" -T "v110_xp"

echo Build 32 bit Project
msbuild "FLIMfit.sln" /property:Configuration=Release
cd ..\..\
