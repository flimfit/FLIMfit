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
    if nargin < 4
        data_setting_file = [];
    end
    if nargin < 5
        channel = [];
    end
    
    if ~iscell(files)            % single file selected
        file = files;
        nfiles = 1;
    else
        file = [files{1} files{2}];
        nfiles = length(files) -1; 
    end
    
    obj.header_text = file;
    [path,name,ext] = fileparts_inc_OME(file);    
    
    if strcmp(ext,'.raw')
        obj.load_raw_data(file);
        return;
    end
    
    % must be done after test for .raw as load_raw_data requires mem mapping
    if is64
        obj.use_memory_mapping = false;
    end
    
    root_path = ensure_trailing_slash(path); 
    obj.root_path = root_path; 
    obj.polarisation_resolved = polarisation_resolved;
    
    if strcmp(ext,'.tif')
        if nfiles > 1
            errordlg('Please use "Load from Directory" option to load multiple .tiff stacks. ','Menu Error');
            return;
        end
    end
    
    if nfiles > 1
        obj.header_text = root_path;
        for f = 1:nfiles
            file_names{f} = [obj.root_path files{f + 1}];
        end
        file_names = sort_nat(file_names);
    else
        file_names = {file};
        obj.header_text = file;
    end
    
    
    obj.n_datasets = nfiles;
   
    obj.lazy_loading = false;
    
    if isempty(obj.names)
        names = [];
        for i = 1:nfiles
            % Set names from file names
            if strcmp(ext,'.tif')
                path_parts = split(filesep,path);
                names{i} = path_parts{end};
            else
                [~,name,~] = fileparts_inc_OME(file_names{i});
                names{i} = [name];
            end
        end
        obj.names = names;
    end
    
    obj.file_names = file_names;
    
    obj.load_multiple(polarisation_resolved, data_setting_file);
    
  
end