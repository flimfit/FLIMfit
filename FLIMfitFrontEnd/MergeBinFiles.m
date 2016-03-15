function MergeBinFiles()

    [file1,path1] = uigetfile('*.bin','Choose parallel file');
    [file2,path2] = uigetfile('*.bin','Choose perp file',path1);

    files{1} = [path1 file1];
    files{2} = [path2 file2];
    
    output = [files{1} '2'];
    
    n_chan = length(files);
    
    for i=1:n_chan
        fh(i) = fopen(files{i});
    end
    
    n_x = fread(fh(1),1,'uint32');
    n_y = fread(fh(1),1,'uint32');
    pix_res = fread(fh(1),1,'single');
    n_t = fread(fh(1),1,'uint32');
    time_res = fread(fh(1),1,'single');
    
    downsampling = 6;
    n_t_final = n_t / downsampling;
    
    data = zeros([n_t_final n_chan n_x n_y], 'uint32');
    
    
    for i=1:n_chan
       fseek(fh(i), 20, 'bof');
       n_el = n_x * n_y * n_t;
       ch_data = fread(fh(i), n_el, 'uint32');
       ch_data = reshape(ch_data, [downsampling n_t_final n_x n_y]);
       ch_data = squeeze(sum(ch_data,1));
       data(:,i,:,:) = ch_data;
       fclose(fh(i));
    end

    oh = fopen(output,'w');
    fwrite(oh,n_x,'uint32');
    fwrite(oh,n_y,'uint32');
    fwrite(oh,pix_res,'single');
    fwrite(oh,n_chan,'uint32');
    fwrite(oh,n_t_final,'uint32');
    fwrite(oh,time_res * downsampling,'single');
    fwrite(oh,data,'uint32');
    fclose(oh);
    
end