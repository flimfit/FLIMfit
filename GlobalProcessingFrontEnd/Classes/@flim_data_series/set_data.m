function set_data(obj,t,data,polarisation_resolved)
    %> Set data from memory

    obj.root_path = '';
    obj.mode = '';
    
    if nargin < 4
        obj.polarisation_resolved = false;
    else
        obj.polarisation_resolved = polarisation_resolved;
    end
    
    data = obj.ensure_correct_dimensionality(data);
    
    obj.data_size = size(data);
    obj.t = t;
    
    if ndims(data) > 4
        obj.num_datasets = size(data,5);
    else
        obj.num_datasets = 1;
    end
    
    % Set names
    %--------------------------------------
    
    nstr = 1:obj.num_datasets;
    nstr = num2cell(nstr);
    nstr = cellfun(@(x)num2str(x),nstr,'UniformOutput',false);
    obj.names = nstr;   
    
    % Write to mem map file
    %--------------------------------------
    
    mapfile_name = global_tempname;
    tr_mapfile_name = global_tempname;
        
    mapfile = fopen(mapfile_name,'w');
    tr_mapfile = fopen(tr_mapfile_name,'w');
    
    fwrite(mapfile,data,'double');
    fwrite(tr_mapfile,data,'double');
 
    fclose(mapfile);
    fclose(tr_mapfile);
    
    % Initialise
    %--------------------------------------
 
    obj.init_memory_mapping(obj.data_size, obj.num_datasets, mapfile_name, tr_mapfile_name);   
    obj.init_dataset();
    
end