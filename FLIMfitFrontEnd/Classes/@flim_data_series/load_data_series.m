function load_data_series(obj,root_path,mode,polarisation_resolved,data_setting_file,selected,channel)   
    %> Load a series of FLIM data files
    
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
    
    if nargin < 7
        channel = [];
    end
    if nargin < 6
        selected = [];
    end
    if nargin < 5
        data_setting_file = [];
    end
    
    block = [];
    
    if ~exist(root_path,'dir')
        throw(MException('GlobalAnalysis:PathDoesNotExist','Path does not exist'));
    end
   
    root_path = ensure_trailing_slash(root_path);

    obj.root_path = root_path;
    obj.polarisation_resolved = polarisation_resolved;
    
    if strcmp(mode,'TCSPC')

        
        files = [dir([root_path '*.sdt']); dir([root_path '*.txt']); dir([root_path '*.ome.tif']); dir([root_path '*.msr']); dir([root_path '*.asc'])];            
        n_datasets = length(files);
        
        file_names = cell(1,n_datasets);
        for i=1:n_datasets
            file_names{i} = files(i).name;
        end
        file_names = sort_nat(file_names);   
        
        if isempty(selected)
            [obj.file_names, ~, obj.lazy_loading] = dataset_selection(file_names);
        elseif strcmp(selected,'all')
            obj.file_names = file_names;
            obj.lazy_loading = false;
        else
            obj.file_names = file_names(selected);
            obj.lazy_loading = false;
        end
        
        n_datasets = length(obj.file_names);

        for i=1:n_datasets
            obj.file_names{i} = [root_path obj.file_names{i}];
        end
        
        %------------------------------------
        % get dimensions from first file
        
        
        dims = obj.get_image_dimensions(obj.file_names{1});
    
        obj.modulo = dims.modulo;
    
        obj.mode = dims.FLIM_type;
    
        % Determine which channels we need to load 
        obj.ZCT = obj.get_ZCT( dims, polarisation_resolved );
        
        % NB we need to sort out blocks here ASAP
  
        obj.t = dims.delays;
        obj.channels = obj.ZCT{2};
    
       
        obj.n_datasets = n_datasets;
        
        %set names
        obj.names = cell(1,n_datasets);
        for j=1:n_datasets
            [~,name,~] = fileparts(obj.file_names{j});
            obj.names{j} = name;
        end
        
        psize = 1;
        if obj.polarisation_resolved
            psize = 2;
        end
        
        data_size = [length(dims.delays) psize dims.sizeXY obj.n_datasets) ];
        obj.data_size = data_size;
        
        
        
    else % widefield

        folder_names = get_folders_recursive(root_path);
            
        folder_names = sort_nat(folder_names);    
        
        
        if isempty(selected)
            [folder_names, ~, obj.lazy_loading] = dataset_selection(folder_names);
        elseif strcmp(selected,'all')
            obj.lazy_loading = false;
        else
            folder_names = folder_names(selected);
            obj.lazy_loading = false;
        end
        
        safe_folder_names = strrep(folder_names,filesep,' ');  
        
        n_datasets = length(folder_names);
        
        % Load first folder to get sizes etc.
        first_root = [root_path folder_names{1}];
        first_file = get_first_file(first_root);

        [~, first_file_name, ext] = fileparts(first_file);
        
        file_names = cell(length(folder_names),1);
        for i=1:length(folder_names)
            file_names{i} = [root_path folder_names{i} filesep first_file_name ext];
        end
        obj.file_names = file_names;
        
        [obj.t,data,obj.t_int] = load_flim_file(first_file); 
        data_size = size(data);

        % if only one channel reshape to include singleton dimension
        if length(data_size) == 3
            data_size = [data_size(1) 1 data_size(2:3)];
        end
        
        clear data;

        obj.data_size = data_size;
        obj.n_datasets = n_datasets;       

        %set names
        obj.names = cell(1,n_datasets);

        
        for j=1:n_datasets  
            obj.names{j} = safe_folder_names{j};
        end
    end    
   
    obj.metadata = extract_metadata(obj.names);
       
    if obj.lazy_loading
        obj.load_selected_files(1);
    else
        obj.load_selected_files(1:obj.n_datasets);
    end
    
    
    obj.init_dataset(data_setting_file);
    
end