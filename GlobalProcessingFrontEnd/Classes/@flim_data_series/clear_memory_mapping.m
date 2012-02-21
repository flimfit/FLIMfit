function clear_memory_mapping(obj)

    if obj.use_memory_mapping
        obj.memmap = []; 
       
        if exist(obj.mapfile_name,'file') && ~obj.raw
            delete(obj.mapfile_name);
        end

    end
    
end