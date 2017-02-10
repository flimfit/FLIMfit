function load_selected_files(obj,selected)

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

    if nargin < 2
        selected = 1:obj.n_datasets;
    end
    
    last_filename = '';
    reader = [];
    
    if numel(selected) == numel(obj.loaded) && all(selected == obj.loaded)
        return
    end
    
    if obj.use_popup && ~obj.raw
        wait_handle = waitbar(0,'Opening files...');
        using_popup = true;
    else
        using_popup = false;
    end
    
    obj.clear_memory_mapping();
    
    obj.loaded = false(1, obj.n_datasets);
    num_sel = length(selected);
    
    for j=1:num_sel
        obj.loaded(selected(j)) = true;
    end
    
    if obj.raw
        
        obj.init_memory_mapping(obj.data_size(1:4), num_sel, obj.mapfile_name);
        
    else
        
        mem_size = obj.data_size(1:4)';
        images_per_file = size(obj.ZCT,1);
        
        if obj.use_memory_mapping
                        
            mapfile_name = global_tempname;
            mapfile = fopen(mapfile_name,'w');
                        
            for j=1:num_sel
                data = read(j);
                fwrite(mapfile,data,obj.data_type);
            end
            
            fclose(mapfile);
            obj.init_memory_mapping(mem_size, num_sel, mapfile_name);

        else
            
            obj.data_series_mem = zeros([mem_size num_sel],obj.data_type);
            
            for j=1:num_sel
                obj.data_series_mem(:,:,:,:,j) = read(j);                
            end
            
            obj.active = 1;
            obj.cur_data = obj.data_series_mem(:,:,:,:,1);
            
        end
        
    end
    
    if using_popup
        close(wait_handle)
    end
    
    obj.compute_tr_data(false);
    
    function data = read(j)
        s = selected(j) - 1;
        file_idx = floor(s / images_per_file) + 1;
        zct_idx = mod(s, images_per_file) + 1;

        filename = obj.file_names{file_idx};
        
        if ~strcmp(last_filename,filename) % cache the reader
            delete(reader);
            reader = get_flim_reader(filename,obj.reader_settings);
            last_filename = filename;
        end
        
        data = reader.read(obj.ZCT(zct_idx,:),obj.channels);

        if ~all(size(data) == mem_size)
            data = zeros(mem_size,obj.data_type);
            disp(['Warning: unable to load ' filename, '. Data size/type mismatch!']);
        end
        
        if using_popup
            waitbar(j./num_sel,wait_handle)
        end
    end
    
end