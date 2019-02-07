function load_single(obj,files,polarisation_resolved)
    %> Load a single FLIM dataset
    
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
   
    if nargin < 3
        polarisation_resolved = false;
    end
    
    if ~iscell(files) % single file selected
        files = {files};
    end
    
    files = sort_nat(files);        
            
    [path,~,ext] = fileparts_inc_OME(files{1});    
    root_path = ensure_trailing_slash(path); 
    obj.root_path = root_path; 

    if strcmp(ext,'.raw')
        obj.load_raw_file(file);
        return;
    end

    % must be done after test for .raw as load_raw_data requires mem mapping
    if length(files) == 1
        obj.use_memory_mapping = false;
        obj.header_text = files{1};
    else
        obj.header_text = root_path;
    end
  
    if strcmp(ext,'.tif')
        if length(files) > 1
            errordlg('Please use "Load from Directory" option to load multiple .tiff stacks. ','Menu Error');
            return;
        end
    end
    
    obj.lazy_loading = false;  
    
    obj.load_files(files,'polarisation_resolved', polarisation_resolved);
    
end