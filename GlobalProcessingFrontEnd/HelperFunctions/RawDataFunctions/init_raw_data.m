function mapfile = init_raw_data(file,t,data_size,n_datasets,metadata,t_irf,irf,mode,pol,t_int)
    
    [path name ext] = fileparts(file);

    dinfo = struct();
    dinfo.t = t;
    
    for i=1:n_datasets
        dinfo.names{i} = ['Data ' num2str(i)];
    end
    
    if nargin < 5
        metadata = struct();
    end
    
    if nargin < 8
        mode = 'TCSPC';
    end
    
    if nargin < 9
        pol = false;
    end
    
    if nargin < 10
        t_int = ones(size(t));
    end
    
    if pol
        n_chan = 2;
    else
        n_chan = 1;
    end
    
    
    dinfo.metadata = metadata;

    if ~isfield(dinfo.metadata,'FileName');
        dinfo.metadata.FileName = dinfo.names;
    end
    
    dinfo.channels = n_chan;
    dinfo.data_size = [data_size(1) n_chan data_size(2) data_size(3)];
    dinfo.polarisation_resolved = pol;
    dinfo.num_datasets = n_datasets;
    dinfo.mode = mode;
    dinfo.t_int = t_int;

    if nargin > 6
        dinfo.irf = irf;
        dinfo.t_irf = t_irf;
    end
    
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