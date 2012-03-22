function load_selected_files(obj,selected)

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

                if obj.load_multiple_channels
                    filename = obj.file_names{1};
                    [~,data] = load_flim_file(filename,obj.channels(selected(j)));
                else
                    filename = obj.file_names{selected(j)};
                    [~,data] = load_flim_file(filename,obj.channels);
                end
                
                if isempty(data) || size(data,1) ~= obj.n_t
                    data = zeros([obj.n_t obj.n_chan obj.height obj.width]);
                end

                c1=fwrite(mapfile,data,'double');

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end

            fclose(mapfile);
            
            obj.init_memory_mapping(obj.data_size(1:4), num_sel, mapfile_name);    
        else
           
            for j=1:num_sel

                if obj.load_multiple_channels
                    filename = obj.file_names{1};
                    [~,data] = load_flim_file(filename,obj.channels(selected(j)));
                else
                    filename = obj.file_names{selected(j)};
                    [~,data] = load_flim_file(filename,obj.channels);
                end
                
                obj.data_series_mem(:,:,:,:,j) = double(data);
                

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