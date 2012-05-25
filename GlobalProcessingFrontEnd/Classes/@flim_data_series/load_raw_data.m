function load_raw_data(obj,file)

    mapfile = fopen(file,'r');
    
    ser_len = fread(mapfile,1,'uint16');
    ser_info = fread(mapfile,ser_len,'uint8');

    fname = [global_tempname '.mat'];
    fid = fopen(fname,'w');
    fwrite(fid,ser_info,'uint8');
    load(fname);
    fclose(fid);
    delete(fname);
    
    fclose(mapfile);
        
    obj.suspend_transformation = true;
    
    fields = fieldnames(dinfo);
    for i=1:length(fields)
        eval(['obj.' fields{i} '= dinfo.' fields{i} ';']);
    end
    
    obj.suspend_transformation = false;
            
    obj.raw = true;
    %obj.lazy_loading = true;
    obj.mapfile_offset = ser_len + 2;
    obj.mapfile_name = file;
        
    obj.load_selected_files(1:obj.n_datasets);
    
    if isempty(obj.root_path)
        obj.root_path = ensure_trailing_slash(fileparts(file));
    end
    
    obj.init_dataset([]);
end