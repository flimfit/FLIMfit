function h5_writetable(filename,dataset,tbl)

    fields = tbl.Properties.VariableNames;
    for i=1:length(fields) 
        d = tbl.(fields{i});
        if iscell(d) 
            if all(cellfun(@isnumeric,d))
                d = cell2mat(d);
            else
                d(cellfun(@isempty,d)) = {''};
            end
        end
        dat.(fields{i}) = d;
        [type(i),sz(i)] = get_data_type(d);
    end

    memtype = H5T.create('H5T_COMPOUND', sum(sz));
    filetype = H5T.create('H5T_COMPOUND', sum(sz));

    offset  = 0;
    for i=1:length(fields)
        H5T.insert(memtype,fields{i},offset,type(i)); 
        H5T.insert(filetype,fields{i},offset,type(i));
        offset = offset + sz(i);    
    end

    function [type,sz] = get_data_type(dat)
        switch class(dat)
            case 'double'
                datatype = 'H5T_NATIVE_DOUBLE';
            case 'single'
                datatype = 'H5T_NATIVE_FLOAT';
            case 'uint64'
                datatype = 'H5T_NATIVE_UINT64';
            case 'int64'
                datatype = 'H5T_NATIVE_INT64';
            case 'uint32'
                datatype = 'H5T_NATIVE_UINT';
            case 'int32'
                datatype = 'H5T_NATIVE_INT';
            case 'uint16'
                datatype = 'H5T_NATIVE_USHORT';
            case 'int16'
                datatype = 'H5T_NATIVE_SHORT';
            case 'uint8'
                datatype = 'H5T_NATIVE_UCHAR';
            case 'int8'
                datatype = 'H5T_NATIVE_CHAR';
            otherwise
                datatype = 'H5T_C_S1';
        end
        type = H5T.copy(datatype);
        if strcmp(datatype,'H5T_C_S1')
            H5T.set_size (type, 'H5T_VARIABLE');
        end
        sz = H5T.get_size(type);
    end

    if exist(filename,'file')
        file = H5F.open(filename,'H5F_ACC_RDWR','H5P_DEFAULT');
    else
        file = H5F.create(filename,'H5F_ACC_TRUNC','H5P_DEFAULT', 'H5P_DEFAULT');
    end

    % Create dataspace.  Setting maximum size to [] sets the maximum
    % size to be the current size.
    num_rows = height(tbl);
    space = H5S.create_simple(1, num_rows, []);

    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl,1);

    dcpl = H5P.create('H5P_DATASET_CREATE');
    dapl = 'H5P_DEFAULT';

    % Create the dataset and write the compound data to it.
    dset = H5D.create(file, dataset, filetype, space, lcpl, dcpl, dapl);
    H5D.write(dset, memtype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', dat);

    % Close and release resources.
    H5D.close(dset);
    H5S.close(space);
    H5T.close(filetype);
    H5F.close(file);
    H5P.close(lcpl);
    H5P.close(dcpl);

end