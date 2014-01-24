function load_single(obj,file,polarisation_resolved,data_setting_file,channel)
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
    
    [path,name,ext] = fileparts(file);

    if strcmp(ext,'.raw')
        obj.load_raw_data(file);
        return;
    end
    
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
    
    obj.root_path = ensure_trailing_slash(path);  
    obj.file_names = {file};
    
    
    dims = obj.get_image_dimensions(obj.file_names{1});
    
    if isempty(dims.delays)
        return;
    end;
    
    obj.modulo = dims.modulo;
    obj.mode = dims.FLIM_type;
    chan_info = dims.chan_info;
    
    % Determine which channels we need to load 
    ZCT = obj.get_ZCT( dims, polarisation_resolved ,chan_info);
    
    if isempty(ZCT)
        return;
    end;
    
    obj.ZCT = ZCT;
    
    % for the time being assume only 1 dimension can be > 1 
    % otherwise this will go horribly wrong !
    allowed = [ 1 1 1];   % allowed max no of planes in each dimension ZCT
    if polarisation_resolved
        allowed = [ 1 2 1 ];
    end
    prefix = [ 'Z' 'C' 'T'];
    
    
    for dim = 1:3
        D = obj.ZCT{dim};
        if length(D) > allowed(dim)
            if isempty(chan_info{1})
                for d = 1:length(D)
                    obj.names{d} = [ prefix(dim) ' '  num2str(D(d)) ];
                end
            else
                for d = 1:length(D)
                    obj.names{d} = [ prefix(dim) ' '  num2str(D(d)) '-' chan_info{d}];
                end
            end
        end
    end
    
        
        
       
    obj.t = dims.delays;
    obj.channels = obj.ZCT{2};
    

    if isempty(obj.names)
        % Set names from file names
        if strcmp(ext,'.tif') | strcmp(ext,'.tiff') & isempty(strfind(file,'ome.'))
            path_parts = split(filesep,path);
            obj.names{1} = path_parts{end};
        else
            if isempty(obj.names)    
                obj.names{1} = name;
            end
        end
    end
    
    
    obj.n_datasets = length(obj.names);
    obj.polarisation_resolved = polarisation_resolved;
    psize = 1;
    if obj.polarisation_resolved
        obj.data_size = [length(dims.delays) 2 dims.sizeXY obj.n_datasets ];
    else
        obj.data_size = [length(dims.delays) 1 dims.sizeXY obj.n_datasets ];
    end
    
  
    obj.metadata = extract_metadata(obj.names);
    obj.load_selected_files();  
    obj.init_dataset(data_setting_file);

end