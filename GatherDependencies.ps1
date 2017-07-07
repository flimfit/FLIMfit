$OME = $env:OME
$BIO = $env:BIO

if (!$OME) { $OME=5.3 }
if (!$BIO) { $BIO=5.5 }

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
$OMEuiUtils_url = 'https://dl.bintray.com/imperial-photonics/omeUiUtils/OMEuiUtils-0.1.6.jar'
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
