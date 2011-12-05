function clear_memory_mapping(obj)

    if obj.use_memory_mapping
        obj.memmap = []; 
        obj.tr_memmap = [];

        if exist(obj.mapfile_name,'file') && ~obj.raw
            delete(obj.mapfile_name);
        end

        if exist(obj.tr_mapfile_name,'file')
            delete(obj.tr_mapfile_name);
        end
    end
    
end