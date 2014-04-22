@echo off

echo Clean 32 bit CMake Project
rmdir GeneratedProjects\MCVC11_32 /s /q
mkdir GeneratedProjects\MCVC11_32
cd GeneratedProjects\MCVC11_32

echo Generate 32 bit CMake Project
cmake ..\..\ -G "Visual Studio 11" -T "v110_xp"

echo Check if Visual Studio 2011 is on path
msbuild
if (%ERRORLEVEL% == 9009) then (
echo Adding Visual Studio 2011 to path (VS2011 or SDK must be installed!)
call "%VS110COMNTOOLS%\vsvars32.bat"
)

echo Build 32 bit Project
msbuild "FLIMfit.sln" /property:Configuration=Release
cd ..\..\
