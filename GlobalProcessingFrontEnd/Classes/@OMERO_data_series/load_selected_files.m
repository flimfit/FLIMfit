function load_selected_files(obj, selected )

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
            return;
        end
    end
    
    if obj.use_popup && length(selected) > 1 
        wait_handle=waitbar(0,'Opening files...');
        using_popup = true;
    else
        using_popup = false;
        obj.verbose = true;
    end
    
    obj.clear_memory_mapping();

    obj.loaded = false(1, obj.n_datasets);
    num_sel = length(selected);

    for j=1:num_sel
        obj.loaded(selected(j)) = true;
    end
    
    
        if obj.use_memory_mapping
            
            obj.data_type = 'single';
            
            mapfile_name = global_tempname;
            mapfile = fopen(mapfile_name,'w');

            for j=1:num_sel

                imgId = obj.image_ids(selected(j));                        
                               
                myimages = getImages(obj.omero_data_manager.session,imgId); 
                image = myimages(1);
                
               
                try
                    [data,~] = obj.OMERO_fetch(image,obj.ZCT, obj.mdta);
                    
                catch
                    disp(['Warning: could not load ' char(image.getName().getValue() ) ', replacing with blank']);
                    data = [];
                end
                    
                
                if isempty(data) || size(data,1) ~= obj.n_t
                    data = zeros(obj.data_size(1:4)');
                end

                c1=fwrite(mapfile,data,'single');

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end

            fclose(mapfile);
            
            obj.init_memory_mapping(obj.data_size(1:4), num_sel, mapfile_name);    
            
        else    % no memeory mapping
           
            for j=1:num_sel
                
                imgId = obj.image_ids(selected(j));                        
                                
                myimages = getImages(obj.omero_data_manager.session,imgId); 
                image = myimages(1);

                try
                    [data,~] = obj.OMERO_fetch(image,obj.ZCT, obj.mdta);
                    if ~isempty(data) 
                        obj.data_series_mem(:,:,:,:,j ) = single(data);                                        
                    end;
                catch err
                                                           
                    rethrow(err);
                end              
              
                
                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end
            
            obj.active = 1;
            obj.cur_data = obj.data_series_mem(:,:,:,:,1);
            
        end

    
        
            
    if using_popup
        close(wait_handle)
    end
    
    obj.compute_tr_data(false);
    
    
end