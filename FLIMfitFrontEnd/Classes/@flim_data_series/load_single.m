function load_single(obj,file,polarisation_resolved)
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
    
    
    if is64
        obj.use_memory_mapping = false;
    end
    
    if nargin < 3
        polarisation_resolved = false;
    end
    if nargin < 4
        data_setting_file = [];
    end
    if nargin < 5
        channel = [];
    end
    
    
    [path,name,ext] = fileparts(file);

  
    obj.root_path = ensure_trailing_slash(path); 
    obj.polarisation_resolved = polarisation_resolved;
    
    obj.n_datasets = 1;
    obj.file_names = {file};
    obj.lazy_loading = false;
    
    if strcmp(ext,'.raw')
        obj.load_raw_data(file);
        return;
    end
    
    
    if isempty(obj.names)
        % Set names from file names
        if strcmp(ext,'.tif') | strcmp(ext,'.tiff') & isempty(strfind(file,'ome.'))
            path_parts = split(filesep,path);
            names{1} = path_parts{end};
        else
            if isempty(obj.names)    
                names{1} = name;
            end
        end
        obj.names = names;
    end
    
    obj.load_multiple(polarisation_resolved, data_setting_file);
    
  
end