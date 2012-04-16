function sz = get_raw_data_size(file)

    mapfile = fopen(file,'r');
    
    ser_len = fread(mapfile,1,'uint16');
    ser_info = fread(mapfile,ser_len,'uint8');

    fname = [global_tempname '.mat'];
    fid = fopen(fname,'w');
    fwrite(fid,ser_info,'uint8');
    load(fname);
    fclose(fid);
    delete(fname);
    
    sz = dinfo.data_size';
    n_datasets = dinfo.num_datasets;
        
    sz(5) = n_datasets;
        
    fclose(mapfile);
    
end


