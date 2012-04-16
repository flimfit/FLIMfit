function save_raw_data(obj,mapfile_name)
    
    if obj.use_popup
        wait_handle=waitbar(0,'Opening files...');
    end
    
    dinfo = struct();
    dinfo.t = obj.t;
    dinfo.names = obj.names;
    dinfo.metadata = obj.metadata;
    dinfo.channels = obj.channels;
    dinfo.data_size = obj.data_size;
    dinfo.polarisation_resolved = obj.polarisation_resolved;
    dinfo.num_datasets = obj.num_datasets;
    dinfo.mode = obj.mode;
        
    fname = [tempname '.mat'];
    save(fname,'dinfo');
    fid = fopen(fname,'r');
    byteData = fread(fid,inf,'uint8');
    fclose(fid);
    delete(fname);
              
    mapfile = fopen(mapfile_name,'w');      

    fwrite(mapfile,length(byteData),'uint16');
    fwrite(mapfile,byteData,'uint8');
    
    for j=1:obj.n_datasets

        file = obj.file_names{j};
        [~,data] = load_flim_file(file,obj.channels);
        
        if isempty(data) || size(data,1) ~= obj.n_t
            data = zeros([obj.n_t obj.n_chan obj.height obj.width]);
        end
        
        c1=fwrite(mapfile,data,'uint16');
      
        if obj.use_popup
            waitbar(j/obj.n_datasets,wait_handle)
        end
        
    end

    fclose(mapfile);
            
    if obj.use_popup
        close(wait_handle)
    end
    
        
end