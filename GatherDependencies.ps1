
$OME = $env:OME
$MSVC_VER = $env:MSVC_VER
$BOOST_VER_MAJOR = $env:BOOST_VER_MAJOR
$BOOST_VER_MINOR = $env:BOOST_VER_MINOR

if (!$OME) { $OME=5.2 }
if (!$BIO) { $BIO=5.2.0-m5 }
if (!$MSVC_VER) { $MSVC_VER=12 }
if (!$BOOST_VER_MAJOR) { $BOOST_VER_MAJOR=1 }
if (!$BOOST_VER_MINOR) { $BOOST_VER_MINOR=59 }


echo "OMERO version = " $OME
echo "Bio-Formats version = " $BIO



function Unzip
{
    param([string]$zipfile, [string]$outpath)
	$fc = New-Object -com Scripting.FileSystemObject
	$shell = New-Object -com Shell.Application
	$srcfolder = $shell.NameSpace($zipfile)
	$destfolder = $shell.NameSpace($outpath)
	$items = $srcfolder.Items()
	$destfolder.CopyHere($items);
}

function MoveSubFolderIntoFolder
{
	param([string]$path)
	$shell = New-Object -com Shell.Application
	$src = gci -path $path | Select-Object -Expand FullName
	$srcfolder = $shell.NameSpace($src)
	$destfolder = $shell.NameSpace($path)
	$items = $srcfolder.Items()
	$destfolder.MoveHere($items)
}

function DownloadZipIntoFolder
{
	param([string]$url, [string]$output_dir)
	$output_file = "$pwd\download.zip"
	echo "Downloading: $url ->" 
	echo "             $output_dir"
	Remove-Item -Recurse -Force "$output_dir*"
	((new-object net.webclient).DownloadFile($url, $output_file))
	Unzip $output_file $output_dir 
	MoveSubFolderIntoFolder $output_dir
	Remove-Item $output_file
}



$ome_url = 'http://downloads.openmicroscopy.org/latest/omero' + $OME + '/matlab.zip'
$bf_url = 'http://downloads.openmicroscopy.org/latest/bio-formats' + $BIO + '/artifacts/bfmatlab.zip'
$ini4j_url = 'http://artifacts.openmicroscopy.org/artifactory/maven/org/ini4j/ini4j/0.3.2/ini4j-0.3.2.jar'
$OMEuiUtils_url = 'https://bintray.com/artifact/download/joshmoore/maven/ome/OMEuiUtils/0.1.4/OMEuiUtils-0.1.4.jar'
$boost_url = 'http://sourceforge.net/projects/boost/files/boost-binaries/' + $BOOST_VER_MAJOR + '.' + $BOOST_VER_MINOR + '.0/boost_' + $BOOST_VER_MAJOR + '_' + $BOOST_VER_MINOR + '_0-msvc-' + $MSVC_VER + '.0-64.exe/download'
$cmake_url = 'https://cmake.org/files/v3.4/cmake-3.4.0-win32-x86.zip'
$gs_url = 'http://downloads.flimfit.org/gs/gs916w64.exe'

$omero_matlab_libs_dir = "$pwd\FLIMfitFrontEnd\OMEROMatlab\libs\"
$OMEuiUtils_dir = "$pwd\FLIMfitFrontEnd\OMEuiUtils"

$BFMatlab_dir = "$pwd\FLIMfitFrontEnd\BFMatlab"

echo "Downloading Ghostscript"
((new-object net.webclient).DownloadFile($gs_url, "$pwd\InstallerSupport\gs916w64.exe"))

DownloadZipIntoFolder $ome_url "$pwd\FLIMfitFrontEnd\OMEROMatlab\"

#echo remove sl4j-api.jar to avoid LOGGER clashes
Remove-Item "$omero_matlab_libs_dir\slf4j-log4j12.jar"
Remove-Item "$omero_matlab_libs_dir\slf4j-api.jar"
Remove-Item "$omero_matlab_libs_dir\log4j.jar"

DownloadZipIntoFolder $bf_url "$pwd\FLIMfitFrontEnd\BFMatlab\"

echo "Downloading ini4j.jar"
((new-object net.webclient).DownloadFile($ini4j_url, "$omero_matlab_libs_dir\ini4j.jar"))

echo "Downloading OMEuiUtils.jar"
((new-object net.webclient).DownloadFile($OMEuiUtils_url, "$OMEuiUtils_dir\OMEuiUtils.jar"))


echo "Setup Boost"
$BOOST_ROOT="c:\local\boost_$($BOOST_VER_MAJOR)_$($BOOST_VER_MINOR)_0\"
$BOOST_LIBRARYDIR = "$($BOOST_ROOT)lib64-msvc-$($MSVC_VER).0\"
[Environment]::SetEnvironmentVariable("BOOST_ROOT", $BOOST_ROOT, "User")
[Environment]::SetEnvironmentVariable("BOOST_LIBRARYDIR", $BOOST_LIBRARYDIR, "User")

echo "Check if boost is installed and install if not"
echo $BOOST_ROOT
echo $BOOST_LIBRARYDIR
if (Test-Path $BOOST_LIBRARYDIR)
{
	echo "    Boost already installed"
} 
else
{
	echo "    Downloading: $BOOST_URL"
	if (Test-Path boost-installer.exe)
	{
   	Remove-Item boost-installer.exe
   }
	$webclient = new-object net.webclient
	$webclient.DownloadFile($boost_url, "$pwd\boost-installer.exe")
	.\boost-installer.exe /silent
}



