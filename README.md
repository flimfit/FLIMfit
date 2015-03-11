FLIMfit
=======

An open source package for rapid analysis of large FLIM datasets. For further information please see:

Warren SC, Margineanu A, Alibhai D, Kelly DJ, Talbot C, et al. (2013) Rapid Global Fitting of Large Fluorescence Lifetime Imaging Microscopy Datasets. PLoS ONE 8(8): e70687. <http://dx.plos.org/10.1371/journal.pone.007068>


Latest versions and binary executables
--------------------------------------

For the latest version, binary executables and further documentation please visit 
<http://www.openmicroscopy.org/site/products/partner/flimfit>

The binary executables do not require MATLAB. 

The source code repository is available at: <https://github.com/openmicroscopy/Imperial-FLIMfit/>


Support
------------------------------------------ 

If you have issues installing or running this software, please contact us via the  FLIMfit users mailing list
at  < http://lists.openmicroscopy.org.uk/mailman/listinfo/flimfit-users>


Compling and running FLIMfit
------------------------------------------ 

This software has been extensively tested on Windows 7 with Matlab 2014b using
Visual Studio 2012, It has been shown to compile under MacOS X with both XCode 4 and
Homebrew GCC4.7 and under Linux with GCC 4.7.

If you wish to compile the package from source please follow these instructions 
which assume a Windows platform.

Required Packages
--------------------
- CMake 2.8.10    	<http://www.cmake.org/>
- Visual Studio 2012	<http://www.microsoft.com/visualstudio/eng/downloads>
- MATLAB 2014b		<http://www.mathworks.co.uk/products/matlab/>
- Boost 1.5.1		<http://www.boost.org/users/history/version_1_51_0.html>

Compiling
-------------------
1. Download the boost library from the link above and either install the source 
   so it can be found by CMake or copy the 'boost' header folder into 
	
	GlobalProcessingLibrary\Boost\boost

   You do not need to compile Boost, only the headers are used

2. Use CMake to generate a Visual Studio Project in a folder such as:
	`GlobalProcessingLibrary\GeneratedProjects\MSVC11_64`

3. Compile the generated solution in Visual Studio


Running FLIMfit from MATLAB
------------------
1. In MATLAB, ensure you have setup the MATLAB compiler by typing `mex -setup` and following the instructions

1. Set your working directory to 
	GlobalProcessingFrontEnd\

2. Start the UI by typing
	FLIMfit <or FLIMfit(true) for the OMERO enabled version>

3. See the online instructions for usage