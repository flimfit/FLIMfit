function load_data_series(obj,root_path,mode,polarisation_resolved)   
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
     
    root_path = ensure_trailing_slash(root_path);
    obj.root_path = root_path;
    obj.header_text = root_path;
    
    if ~strcmp(mode,'tif-stack')

        files = [dir([root_path '*.sdt']); 
                 dir([root_path '*.txt']); 
                 dir([root_path '*.tif']); 
                 dir([root_path '*.csv']); 
                 dir([root_path '*.tiff']); 
                 dir([root_path '*.msr']); 
                 dir([root_path '*.asc']); 
                 dir([root_path '*.bin']); 
                 dir([root_path '*.pt3']);
                 dir([root_path '*.ptu']);
                 dir([root_path '*.bin2']);
                 dir([root_path '*.ffd']);
                 dir([root_path '*.ffh']);
                 dir([root_path '*.spc'])]; 
                     
        file_names = {files.name};
        file_names = sort_nat(file_names);   
        [file_names, ~, lazy_loading] = dataset_selection(file_names);
        file_names = strcat(root_path, file_names);
        if isempty(file_names); return; end
        
    else % tif-stack

        folder_names = get_folders_recursive(root_path);
        folder_names = sort_nat(folder_names);            
        [folder_names, ~, obj.lazy_loading] = dataset_selection(folder_names);
        if isempty(folder_names); return; end
        
        first_root = [root_path folder_names{1}];
        first_file = get_first_file(first_root);
        [~, first_file_name, ext] = fileparts(first_file);
        
        file_names = strcat(root_path, folder_names, filesep, first_file_name, ext);
           
    end   
   
    obj.lazy_loading = lazy_loading;
    
    obj.load_files(file_names,'polarisation_resolved', polarisation_resolved, 'data_settings_files', data_setting_file)
    
end