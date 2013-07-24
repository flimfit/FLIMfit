==========================================

  FLIMfit 4.5.8

  (c) Imperial College London, 2013

==========================================

LATEST VERSIONS AND BINARY EXECUTABLE
------------------------------------------

For the lastest version and binary executables , please visit 
http://www.openmicroscopy.org/site/products/partner/flimfit

The binary executables do not require MATLAB. 

The source code repository is available at:
https://github.com/openmicroscopy/Imperial-FLIMfit/


SUPPORT
------------------------------------------ 

If you have issues installing or running this software, please contact 
    Sean Warren at sean.warren09@imperial.ac.uk
    or FLIMfit@imperial.ac.uk


COMPILING AND RUNNING FLIMfit
------------------------------------------ 

This software has been extensively tested on Windows 7 with Matlab 2013a using
Visual Studio 2012. It has been shown to compile under MacOS X with both XCode 4 and
macports GCC4.7 and under Linux with GCC 4.7, however testing on these platforms has been limited.  

If you wish to compile the package from source please follow these instructions 
which assume a Windows platform.

Required Packages
--------------------
- CMake 2.8.10			http://www.cmake.org/
- Visual Studio 2012		http://www.microsoft.com/visualstudio/eng/downloads	
- MATLAB 2013a			http://www.mathworks.co.uk/products/matlab/
- Boost 1.5.1			http://www.boost.org/users/history/version_1_51_0.html		

Compiling
-------------------
1. Download the boost library from the link above and either install the source 
   so it can be found by CMake or copy the 'boost' header folder into 
	
	GlobalProcessingLibrary\Boost\boost

   You do not need to compile Boost, only the headers arae used

2. Use CMake to generate a Visual Studio Project in a folder such as:
	GlobalProcessingLibrary\GeneratedProjects\MSVC11_64

3. Compile the generated solution in Visual Studio


Running FLIMFit from MATLAB
------------------
1. In MATLAB, ensure you have setup the MATLAVB compiler by typing
	mex -setup
   and following the instructions

1. Set your working directory to 
	GlobalProcessingFrontEnd\

2. Start the UI by typing
	FLIMfit <or FLIMfit(true) for the OMERO enabled version>

3. See the online instructions for usage
