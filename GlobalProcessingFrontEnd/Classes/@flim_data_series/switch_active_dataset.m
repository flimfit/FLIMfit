function switch_active_dataset(obj, dataset)
    %> Switch which dataset in the memory mapped file we're pointing at

    if dataset <= 0 || dataset > obj.n_datasets
        return
    end
    
    if obj.use_memory_mapping
        
        if obj.loaded(dataset)

            tr_idx = sum(obj.loaded(1:dataset));

            if obj.raw
                idx = dataset;
            else
                idx = tr_idx;
            end

            if ~isempty(obj.memmap)

                if ~is64
                    % Calculate size of single dataset
                    offset_step = obj.n_t * obj.n_chan * obj.height * obj.width;
                    tr_offset_step = length(obj.tr_t) * obj.n_chan * obj.height * obj.width;

                    if obj.raw
                        data_sz = 2; %uint16
                    else
                        data_sz = 8; %double
                    end

                    obj.memmap.offset = (idx-1) * offset_step * data_sz + obj.mapfile_offset;
                    obj.tr_memmap.offset = (tr_idx-1) * tr_offset_step * 8;

                    obj.data_series = obj.memmap.Data(1).data_series;
                    obj.tr_data_series = obj.tr_memmap.Data(1).data_series;
                else
                    obj.data_series = obj.memmap.Data(idx).data_series;
                    obj.tr_data_series = obj.tr_memmap.Data(tr_idx).data_series; 
                end

            end

        else

            obj.load_selected_files(dataset);

        end
        
    else
       
        obj.data_series = obj.data_series_mem(:,:,:,:,dataset);
        if dataset <= size(obj.tr_data_series_mem,5)
            obj.tr_data_series = obj.tr_data_series_mem(:,:,:,:,dataset);
        end
        
    end
        
end