#!/bin/bash

OMERO_MATLAB_URL="http://cvs.openmicroscopy.org.uk/snapshots/omero/4.4.8/OMERO.matlab-4.4.8-ice33-b256.zip"
OMERO_INSTALL_DIR="FLIMfitFrontEnd/OMEROMatlab/"
		
echo "Checking for OMERO Matlab plug-in..."
if [ "$(ls -A $OMERO_INSTALL_DIR)" ]; then
	echo "OMERO plugin already installed..."
else
    echo "Downloading OMERO..."
    curl -L $OMERO_MATLAB_URL -o OMERO.matlab.zip
	omero_matlab_name=$(basename $OMERO_MATLAB_URL .zip)
	unzip OMERO.matlab*.zip -d $omero_matlab_name
	rm OMERO.matlab.zip
	mv $omero_matlab_name/* $OMERO_INSTALL_DIR
fi

echo "Checking for homebrew install..."
(brew | grep "command not found") \
	&& ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)" \
	|| echo "Homebrew installed"

echo "Ensure ghostscript is installed..."
(brew list | grep ghostscript) && echo " installed" || brew install ghostscript