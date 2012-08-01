function switch_active_dataset(obj, dataset, no_smoothing)
    %> Switch which dataset in the memory mapped file we're pointing at

    if nargin < 3
        no_smoothing = false;
    end
    
    if (dataset == obj.active && (no_smoothing || obj.cur_smoothed)) ...
            || dataset <= 0 || dataset > obj.n_datasets
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
                    offset_step = 4 * obj.n_t * obj.n_chan * obj.height * obj.width;
                    obj.memmap.offset = (idx-1) * offset_step + obj.mapfile_offset;
                    
                    obj.cur_data = obj.memmap.Data(1).data_series;
                else
                    obj.cur_data = obj.memmap.Data(idx).data_series;
                end

            end

        else

            obj.load_selected_files(dataset);

        end
        
    else
       
        obj.cur_data = obj.data_series_mem(:,:,:,:,dataset);
               
    end
 
    obj.active = dataset;
    
    obj.compute_tr_data(false,no_smoothing);
        
end