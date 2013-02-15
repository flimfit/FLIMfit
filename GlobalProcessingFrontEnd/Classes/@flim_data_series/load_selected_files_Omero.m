function load_selected_files_Omero(obj,session,image_ids,selected,channel, ZCT) % 

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


    if nargin < 2
        selected = 1:obj.num_datasets;
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
    
    if ~obj.raw
        if obj.use_memory_mapping
            
            mapfile_name = global_tempname;
            mapfile = fopen(mapfile_name,'w');

            for j=1:num_sel

                    image_descriptor{1} = session;
                    image_descriptor{2} = image_ids(selected(j));                        
                    try
                        [~,data,~] = OMERO_fetch(image_descriptor,channel,ZCT);
                    catch err
                        rethrow(err);
                    end                    
                                                    
                if isempty(data) || size(data,1) ~= obj.n_t
                    data = zeros([obj.n_t obj.n_chan obj.height obj.width]);
                end

                c1=fwrite(mapfile,data,'single');

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end

            fclose(mapfile);
            
            obj.init_memory_mapping(obj.data_size(1:4), num_sel, mapfile_name);    
            
        else % no memory mapping
           
            for j=1:num_sel
                    
                    image_descriptor{1} = session;
                    image_descriptor{2} = image_ids(selected(j));                        
                    try
                        [~,data,~] = OMERO_fetch(image_descriptor,channel,ZCT);
                    catch err
                        rethrow(err);
                    end                                        
                
                obj.data_series_mem(:,:,:,:,j) = single(data);                

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end
            
            obj.active = 1;
            obj.cur_data = obj.data_series_mem(:,:,:,:,1);
            
        end
    else
        obj.init_memory_mapping(obj.data_size(1:4), num_sel, obj.mapfile_name);
    end
        
            
    if using_popup
        close(wait_handle)
    end
    
    obj.compute_tr_data(false);
    
end