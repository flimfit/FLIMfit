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
        
    fields = fieldnames(dinfo);
    for i=1:length(fields)
        eval(['obj.' fields{i} '= dinfo.' fields{i} ';']);
    end
            
    obj.raw = true;
    obj.lazy_loading = true;
    obj.mapfile_offset = ser_len + 2;
    obj.mapfile_name = file;
        
    obj.load_selected_files(1);
    
    obj.init_dataset([]);
end