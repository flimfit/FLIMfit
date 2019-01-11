function addpath_global_analysis()

% Copyright (C) 2013 Imperial College London.
% All rights reserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
% This software tool was developed with support from the UK 
% Engineering and Physical Sciences Council 
% through  a studentship from the Institute of Chemical Biology 
% and The Wellcome Trust through a grant entitled 
% "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

% Author : Sean Warren

    if ~isdeployed

        thisdir = [fileparts( mfilename( 'fullpath' ) ) filesep];
        if ~exist([thisdir 'matlab-ui-common' filesep 'icons.mat'],'file')
            disp('Warning: Submodules have not been checked out.');
            disp('Please run "git submodule update --recursive" on the commandline first');
        end
        
        addpath( thisdir,...
                [thisdir filesep 'Classes'],...
                [thisdir filesep 'Classes' filesep 'DataReaders'],...
                [thisdir filesep 'Classes' filesep 'menu_controllers'],...
                [thisdir filesep 'matlab-ui-common'],...
                [thisdir filesep 'matlab-ui-common' filesep 'phasor'],...
                [thisdir filesep 'matlab-ui-common' filesep 'FastHyDe'],...
                [thisdir filesep 'multid_segmentation'],...
                [thisdir filesep 'GUIDEInterfaces'],...
                [thisdir filesep 'GeneratedFiles'],...
                [thisdir filesep 'InternalHelperFunctions'],...
                [thisdir filesep 'InternalHelperFunctions' filesep 'RawDataFunctions'],...
                [thisdir filesep 'HelperFunctions'],...
                [thisdir filesep 'HelperFunctions' filesep 'xml_io_toos'],...
                [thisdir filesep 'HelperFunctions' filesep 'altmany-export_fig'],...
                [thisdir filesep 'OMEROUtilities'],...
                [thisdir filesep 'EstimationTools'],...
                [thisdir filesep 'Libraries'],...
                [thisdir filesep 'FLIMfitMex'],...
                [matlabroot filesep 'toolbox' filesep 'images' filesep 'images']);
        
        thirdpartydir = [thisdir 'ThirdParty'];
        if ~exist(thirdpartydir,'dir')
            mkdir(thirdpartydir)
        end
        get_bioformats(thirdpartydir,'5.9.2');
        get_omero(thirdpartydir,'5.4');
        get_gui_layout_toolbox();
        get_iterVSTpoisson();    

            
        nicyDirs = dir([thisdir 'ICY_Matlab']); 
        if length(nicyDirs) > 3
            addpath( ...
                [thisdir 'ICY_Matlab' filesep 'matlabcommunicator'],... 
                [thisdir 'ICY_Matlab' filesep 'matlabxserver']);  
        end
                                        
        
            
    end

end