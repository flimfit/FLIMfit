function fetch_TCSPC(obj, image_descriptor, polarisation_resolved, channel)
    %> Load a single FLIM dataset
    
    if nargin < 3
        polarisation_resolved = false;
    end
    if nargin < 4
        channel = [];
    end

    
    try
        [delays, data_cube, name] = OMERO_fetch(image_descriptor, channel);
    catch err
        
         rethrow(err);
    end
      
    
        
   if length(channel) > 1
        obj.load_multiple_channels = true;
   else
        obj.load_multiple_channels = false;
   end
    
    if size(delays) > 0
        
        obj.mode = 'TCSPC';
    
    
        obj.file_names = {'file'};
        obj.channels = 1;
        
        obj.names{1} = name;
   
        obj.metadata = extract_metadata(obj.names);
    
        
        obj.polarisation_resolved = polarisation_resolved;
   
        obj.t = delays;
    
        obj.data_size = size(data_cube);
    
        obj.use_memory_mapping = false;
    
        obj.data_series_mem = double(data_cube);
        obj.tr_data_series_mem = double(data_cube);
        
        if obj.load_multiple_channels
            obj.num_datasets = size(data_cube,5);
        else
            obj.num_datasets = 1;
    
        obj.loaded = ones([1 obj.num_datasets]);
    
        obj.switch_active_dataset(1);
     
        obj.init_dataset();
    end

end