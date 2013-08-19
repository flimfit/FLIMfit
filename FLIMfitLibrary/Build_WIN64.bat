@echo off

REM %VS110COMNTOOLS%vsvars32.bat

echo Clean 64 bit CMake Project
rmdir GeneratedProjects\MSVC11_64 /s /q
mkdir GeneratedProjects\MSVC11_64
cd GeneratedProjects\MSVC11_64

echo Generate 64 bit CMake Project
cmake ..\..\ -G "Visual Studio 11 Win64" -T "v110_xp"

echo Build 64 bit Project
msbuild "FLIMfit.sln" /property:Configuration=Release
cd ..\..\


