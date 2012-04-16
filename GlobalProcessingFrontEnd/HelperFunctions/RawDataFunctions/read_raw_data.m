function [data,t] = read_raw_data(file,index)

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
    t = dinfo.t;
    n_datasets = dinfo.num_datasets;
        
    if nargin < 2
        index = 1:n_datasets;
    end
    
    mapfile_offset = ser_len + 2;
    mapfile_name = file;
        
    mapfile_dataoffset = prod(sz) * 2;
    
    ds = prod(sz);
    
    total_sz = sz;
    total_sz(5) = length(index);
    data = zeros(total_sz);
    
    index = index - 1;
    
    for i=1:length(index)
       
        fseek(mapfile, index(i)*mapfile_dataoffset+mapfile_offset, 'bof');
        frame = fread(mapfile,ds,'uint16');
        frame = reshape(frame,sz);
        
        data(:,:,:,:,i) = frame;
        
    end
        
    fclose(mapfile);
    
end


