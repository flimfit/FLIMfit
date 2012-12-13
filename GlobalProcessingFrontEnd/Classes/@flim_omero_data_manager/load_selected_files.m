function load_selected_files(obj,data_series,image_ids,selected,channel, ZCT,mdta) % 

    if nargin < 2
        selected = 1:data_series.num_datasets;
    end
        
    if ~isempty(data_series.loaded)
        already_loaded = true;
        for i=1:length(selected)
            if ~data_series.loaded(selected(i))
                already_loaded = false;
            end
        end

        if already_loaded
            return
        end
    end
    
    if data_series.use_popup && length(selected) > 1 && ~data_series.raw
        wait_handle=waitbar(0,'Opening files...');
        using_popup = true;
    else
        using_popup = false;
    end
    
    data_series.clear_memory_mapping();

    data_series.loaded = false(1, data_series.n_datasets);
    num_sel = length(selected);

    for j=1:num_sel
        data_series.loaded(selected(j)) = true;
    end
    
    if ~data_series.raw
        if data_series.use_memory_mapping
            
            mapfile_name = global_tempname;
            mapfile = fopen(mapfile_name,'w');

            for j=1:num_sel
                    
                    imgId = image_ids(selected(j));                        
                    image = get_Object_by_Id(obj.session,imgId);
                    try
                        [~,data,~] = obj.OMERO_fetch(image,channel,ZCT,mdta);
                    catch err
                        rethrow(err);
                    end                    
                                                    
                if isempty(data) || size(data,1) ~= data_series.n_t
                    data = zeros([data_series.n_t data_series.n_chan data_series.height data_series.width]);
                end

                c1=fwrite(mapfile,data,'single');

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end

            fclose(mapfile);
            
            data_series.init_memory_mapping(data_series.data_size(1:4), num_sel, mapfile_name);    
            
        else % no memory mapping
           
            for j=1:num_sel
                    
                    imgId = image_ids(selected(j));                        
                    image = get_Object_by_Id(obj.session,imgId);
                    try
                        [~,data,~] = obj.OMERO_fetch(image,channel,ZCT,mdta);
                        if ~isempty(data) 
                            data_series.data_series_mem(:,:,:,:,j) = single(data);                                        
                        end;
                    catch err
                        if using_popup, 
                            close(wait_handle), 
                        end;                        
                        rethrow(err);
                    end                                        
                
                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end
            
            data_series.active = 1;
            data_series.cur_data = data_series.data_series_mem(:,:,:,:,1);
            
        end
    else
        data_series.init_memory_mapping(data_series.data_size(1:4), num_sel, data_series.mapfile_name);
    end
        
            
    if using_popup
        close(wait_handle)
    end
    
    data_series.compute_tr_data(false);
    
end