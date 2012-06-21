function write_raw_data(file,t,data,t_irf,irf,ref)

    if nargin < 6
        ref = [];
    end
    if nargin < 5
        irf = [];
    end
    
    n_datasets = size(data,4);
    
    [path name ext] = fileparts(file);

    dinfo = struct();
    dinfo.t = t;
    
    for i=1:n_datasets
        dinfo.names{i} = ['Data ' num2str(i)];
    end
    
    dinfo.metadata = struct();
    dinfo.metadata.FileName = dinfo.names;
    dinfo.channels = 1;
    dinfo.data_size = [size(data,1) 1 size(data,2) size(data,3) 1];
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
    fwrite(mapfile,data,'uint16');
    fclose(mapfile);
    
    if ~isempty(irf)
        dlmwrite([path filesep 'irf.irf'],[t_irf' irf'],'\t');
    end
    if ~isempty(ref)
        dlmwrite([path filesep 'ref150.irf'],[t_irf' ref'],'\t');
    end
end