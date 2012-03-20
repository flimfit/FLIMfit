function mapfile = init_raw_data(file,t,data_size,n_datasets,metadata)
    
    [path name ext] = fileparts(file);

    dinfo = struct();
    dinfo.t = t;
    
    for i=1:n_datasets
        dinfo.names{i} = ['Data ' num2str(i)];
    end
    
    if nargin < 5
        metadata = struct();
    end
    
    dinfo.metadata = metadata;

    if ~isfield(dinfo.metadata,'FileName');
        dinfo.metadata.FileName = dinfo.names;
    end
    
    dinfo.channels = 1;
    dinfo.data_size = [data_size(1) 1 data_size(2) data_size(3)];
    dinfo.polarisation_resolved = false;
    dinfo.num_datasets = n_datasets;
    dinfo.mode = 'TCSPC';

    fname = [tempname '.mat'];
    save(fname,'dinfo');
    fid = fopen(fname,'r');
    byteData = fread(fid,inf,'uint8');
    fclose(fid);
    delete(fname);

    mapfile = fopen(file,'w');      

    fwrite(mapfile,length(byteData),'uint16');
    fwrite(mapfile,byteData,'uint8');
    
end