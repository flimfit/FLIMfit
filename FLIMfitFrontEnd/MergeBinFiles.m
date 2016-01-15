function MergeBinFiles()

    files{1} = 'C:\Users\New\Downloads\16.11.15 bin files\VLDLR_mGFP parallel channel.bin';
    files{2} = 'C:\Users\New\Downloads\16.11.15 bin files\VLDLR_mGFP perpendicular channel.bin';

    output = 'C:\Users\New\Downloads\16.11.15 bin files\merge.bin2';
    
    n_chan = length(files);
    
    for i=1:n_chan
        fh(i) = fopen(files{i});
    end
    
    n_x = fread(fh(1),1,'uint32');
    n_y = fread(fh(1),1,'uint32');
    pix_res = fread(fh(1),1,'single');
    n_t = fread(fh(1),1,'uint32');
    time_res = fread(fh(1),1,'single');
    
    data = zeros([n_t n_chan n_x n_y], 'uint32');
    
    for i=1:n_chan
       fseek(fh(i), 20, 'bof');
       n_el = n_x * n_y * n_t;
       ch_data = fread(fh(i), n_el, 'uint32');
       ch_data = reshape(ch_data, [n_t n_x n_y]);
       data(:,i,:,:) = ch_data;
       fclose(fh(i));
    end

    oh = fopen(output,'w');
    fwrite(oh,n_x,'uint32');
    fwrite(oh,n_y,'uint32');
    fwrite(oh,pix_res,'single');
    fwrite(oh,n_chan,'uint32');
    fwrite(oh,n_t,'uint32');
    fwrite(oh,time_res,'single');
    fwrite(oh,data,'uint32');
    fclose(oh);
    
end