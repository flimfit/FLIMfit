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
        
    if ~isempty(obj.loaded)
        already_loaded = true;
        for i=1:length(selected)
            if ~obj.loaded(selected(i))
                already_loaded = false;
            end
        end

        if already_loaded
            return
        end
    end
    
    if obj.use_popup && length(selected) > 1 && ~obj.raw
        wait_handle=waitbar(0,'Opening files...');
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
    
    if obj.hdf5
    
        %...
        
    elseif obj.raw
        
        obj.init_memory_mapping(obj.data_size(1:4), num_sel, obj.mapfile_name);
    
    else
        
         mem_size = obj.data_size(1:4);
     
        if obj.use_memory_mapping
            
          
            obj.data_series_mem = single(zeros([mem_size' 1]));
            
            obj.data_type = 'single';
            
            mapfile_name = global_tempname;
            mapfile = fopen(mapfile_name,'w');

            for j=1:num_sel
               
                if length(obj.file_names) > 1
                    filename = obj.file_names{selected(j)};
                else
                    filename = obj.file_names{1}; 
                end
               
                [success, obj.data_series_mem] = obj.load_flim_cube(obj.data_series_mem, filename,j,1);
                
                if ~success
                    disp(['Warning: unable to load dataset ' num2str(j), '. Data size mismatch! ']);
                end

                data = obj.data_series_mem(:,:,:,:,1);
              
                c1=fwrite(mapfile,data,'single');

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end

            fclose(mapfile);
            
            obj.init_memory_mapping(mem_size, num_sel, mapfile_name);    
        else
            
             obj.data_series_mem = single(zeros([mem_size' num_sel]));
           
            for j=1:num_sel

                if length(obj.file_names) > 1
                    filename = obj.file_names{selected(j)};
                else
                    filename = obj.file_names{1};  
                end
                
                [success, obj.data_series_mem] = obj.load_flim_cube(obj.data_series_mem, filename,j,j,obj.reader_settings);
                
               
                if ~success
                    disp(['Warning: unable to load dataset ' num2str(j), '. Data size mismatch! ']);
                end

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end
            
            obj.active = 1;
            obj.cur_data = obj.data_series_mem(:,:,:,:,1);
            
        end

    end
    
    
               
    if using_popup
        close(wait_handle)
    end
    
    obj.compute_tr_data(false);
    
    
end