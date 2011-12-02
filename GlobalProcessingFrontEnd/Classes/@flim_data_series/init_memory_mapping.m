function init_memory_mapping(obj, data_size, num_datasets, mapfile_name, tr_mapfile_name)
        
    data_preloaded = false;

    if obj.use_memory_mapping
    
        if nargin >= 5
            data_preloaded = true;
            obj.mapfile_name = mapfile_name;
            obj.tr_mapfile_name = tr_mapfile_name;
        elseif ~obj.raw
            obj.mapfile_name = global_tempname;
            obj.tr_mapfile_name = global_tempname;
        end

        if obj.raw

            req_len =  prod(data_size) * num_datasets;
            if obj.tr_mapfile_len < req_len
                tr_mapfile = fopen(obj.tr_mapfile_name,'a');
                zd = zeros(data_size');
                while obj.tr_mapfile_len < req_len
                    fwrite(tr_mapfile,zd,'double');
                    obj.tr_mapfile_len = obj.tr_mapfile_len + prod(data_size);
                end
                fclose(tr_mapfile);
            end


        elseif ~data_preloaded

            mapfile = fopen(obj.mapfile_name,'w');
            tr_mapfile = fopen(obj.tr_mapfile_name,'w');

            if obj.use_popup
                wait_handle=waitbar(0,'Initalising memory mapping...');
            end

            zs = data_size(1:end-1);
            if length(zs) < 2
                zs = [zs 1];
            end
            zd = zeros(zs,'double');
            n_4 = data_size(end);
            for i=1:num_datasets
                for j=1:n_4
                    if ~data_preloaded
                        fwrite(mapfile,zd,'double');
                        fwrite(tr_mapfile,zd,'double');
                    end
                end
                if obj.use_popup
                    waitbar(i/num_datasets,wait_handle)
                end
            end
            clear zd zi;
            fclose(mapfile);
            fclose(tr_mapfile);
            if obj.use_popup
                close(wait_handle);
            end    

        end

        if ~is64
            tr_repeat = 1;
            repeat = 1;
        else
            tr_repeat = num_datasets;
            if obj.raw
                repeat = obj.num_datasets;
            else
                repeat = num_datasets;
            end
        end

        if obj.raw
            format = 'uint16';
        else
            format = 'double';
        end

        %ds = data_size(data_size ~= 1);

        obj.memmap = memmapfile(obj.mapfile_name,'Writable',true,'Repeat',repeat,'Format',{format, data_size', 'data_series' },'Offset',obj.mapfile_offset);
        obj.tr_memmap = memmapfile(obj.tr_mapfile_name,'Writable',true,'Repeat',tr_repeat,'Format',{'double', data_size', 'data_series' });

        obj.data_series = obj.memmap.Data(1).data_series;
        obj.tr_data_series = obj.tr_memmap.Data(1).data_series;

    end
    
end