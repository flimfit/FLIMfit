function uninstall()
%uninstall  remove the layout package from the MATLAB path
%
%   uninstall() removes the layout tools from the MATLAB path.
%
%   Examples:
%   >> uninstall()
%
%   See also: install

%   Copyright 2008-2010 The MathWorks Ltd.
%   $Revision: 231 $    
%   $Date: 2010-06-28 11:20:22 +0100 (Mon, 28 Jun 2010) $

thisdir = fileparts( mfilename( 'fullpath' ) );

rmpath( thisdir );
rmpath( fullfile( thisdir, 'layoutHelp' ) );
rmpath( fullfile( thisdir, 'Patch' ) );
savepath();