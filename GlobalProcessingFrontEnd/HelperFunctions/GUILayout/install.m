function install()
%install  add the layout package to the MATLAB path
%
%   install() adds the necessary folders to the MATLAB path for the layout
%   tools to be used from anywhere.
%
%   Examples:
%   >> install()
%
%   See also: uninstall

%   Copyright 2008-2010 The MathWorks Ltd.
%   $Revision: 269 $
%   $Date: 2010-07-07 08:50:47 +0100 (Wed, 07 Jul 2010) $

% Check the version
minVersionDate = '25-Jan-2010';
matlabVersion = ver( 'MATLAB' );
if datenum( matlabVersion.Date ) < datenum( minVersionDate )
    warning( 'Layouts:VersionTooOld', 'This toolbox has been built and tested on MATLAB release R2010a and above. You appear to be using an older version and will almost certainly experience problems or even MATLAB crashes.' )
end

% Add the folders to the path
thisdir = fileparts( mfilename( 'fullpath' ) );

dirs = {
    thisdir
    fullfile( thisdir, 'Patch' )
    fullfile( thisdir, 'layoutHelp' )
    };

for dd=1:numel( dirs )
    addpath( dirs{dd} );
    fprintf( '+ Folder added to path: %s\n', dirs{dd} );
end

% Save the changes to make the installation permanent
if savepath()==0
    % Success
    fprintf( '+ Path saved\n' );
else
    % Failure
    fprintf( '- Failed to save path, you will need to re-install when MATLAB is restarted\n' );
end