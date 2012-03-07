function set_tr_data_size(obj,tr_data_size)
    %> Set the size of the transformed data for memory mapped file

    obj.tr_data_size = tr_data_size;
   
    if obj.use_memory_mapping && ~isempty(obj.tr_memmap)
        clear obj.tr_memmap;
        obj.tr_memmap.Format = {'double', tr_data_size, 'data_series'};
        obj.tr_data_series = obj.tr_memmap.Data(1).data_series;
    end
    
end