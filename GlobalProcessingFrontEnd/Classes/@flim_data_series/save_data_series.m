function save_data_series(obj,file)
    %> Save data series to HDF file

    hdf_root = 'GlobalFLIMDataSeries/';
    
    % Check if file exists, if so append it to the data
    if ~exist(file,'file')
        
        % Create file
        fcpl = H5P.create('H5P_FILE_CREATE');
        fapl = H5P.create('H5P_FILE_ACCESS');
        fid = H5F.create(file,'H5F_ACC_TRUNC',fcpl,fapl);
        H5F.close(fid); 
        
        hdf5write(file,[hdf_root 't'],obj.t,'WriteMode','append');
        hdf5write(file,[hdf_root 'width'],obj.width,'WriteMode','append');
        hdf5write(file,[hdf_root 'height'],obj.height,'WriteMode','append');
        hdf5write(file,[hdf_root 'mode'],obj.mode,'WriteMode','append');

    else
            
        width = hdf5read(file,[hdf_root 'width']);
        height = hdf5read(file,[hdf_root 'height']);
        t = hdf5read(file,[hdf_root 't']);
            
        % Check if we can append data
        if width ~= obj.width || height ~= obj.height || ~all(t == obj.t)
            msgbox('Could not append data to that datafile');
            return;
        end
        
    end

    % Add data to file
    for i=1:obj.num_datasets
        dataset = [hdf_root 'FLIMData/' obj.names{i} ];
        obj.switch_active_dataset(i);
        hdf5write(file,dataset,obj.cur_data,'WriteMode','append');
    end


end