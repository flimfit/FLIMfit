function [ImData Delays noOfChannels] = BHSwapBlocks(filename)


% [ImData Delays noOfChannels]=loadBHFile (filename)
%
%   Reads a ".sdt" files as recorded with B&H
%   ImData is a 3dmatrix where the first index is the time-bin, 
%   the second is the y coordinate and the third the x coordinate

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren

%   

    if nargin < 2
        channel = -1;
    end
    if nargin < 3
        blockk = -1;
    end


    ImData = [];
    Delays = [];


    timerange=12500;        % default timeRange in ps

    fid=fopen(filename);

    whole_file = fread(fid);
    fseek(fid,0,'bof');
  
    fread(fid,1, 'uint16');         % revision

    %Reads the file header
    info_offs=fread(fid,1, 'uint32'); 
    info_length=fread(fid,1, 'uint16');
    setup_offs=fread(fid,1, 'uint32');
    setup_length=fread(fid,1, 'uint16');
    data_block_offs = fread(fid,1, 'uint32');
    no_of_data_blocks = fread(fid,1, 'uint16');
    data_block_length = fread(fid,1, 'uint32');  %length of longest block in file
    meas_desc_block_offs = fread(fid,1, 'uint32'); 
    no_of_meas_desc_blocks = fread(fid,1, 'uint16');
    
    % read setup string:
    fseek(fid, setup_offs, 'bof');
    setup_string = fread(fid, setup_length, 'uint8=>char')';
   
    
    % read measurement decription block
    fseek (fid, meas_desc_block_offs, 'bof'); 
    time = fread (fid, 9, 'uint8=>char');
    dated = fread (fid, 11, 'uint8=>char');
    date = dated';
    mod_ser_no = fread (fid, 16, 'uint8=>char');
    meas_mode = fread(fid,1, 'uint16');
    % bunch of stuff I don't as yet understand
    dummy = fread(fid,5, 'float');      % 5 floats cfd_ll, cfd_lh, cfd_zc, cfd_hf & syn_zc
    syn_fd = fread(fid,1, 'uint16');
    syn_hf = fread(fid,1, 'float');
    tac_r = fread(fid,1, 'float');
    tac_g = fread(fid,1, 'uint16');
    dummy = fread(fid,3, 'float');
    adc_res = fread(fid,1, 'uint16');       % adc resolution !!
    eal_de = fread(fid,1, 'uint16'); 
    ncx = fread(fid,1, 'uint16'); 
    ncy = fread(fid,1, 'uint16');
    page = fread(fid,1, 'uint16');
    dummy = fread(fid,2, 'float');  %col_t, rep_t
    stopt = fread(fid,1, 'uint16');
    overfl = fread (fid, 1, 'uint8=>char');
    dummy = fread(fid,2, 'uint16');     %use_motor , steps
    offset = fread(fid,1, 'float');  
    dummy = fread(fid,3, 'uint16');     % dither , inc , mem_bank
    mod_type = fread (fid, 16, 'uint8=>char');
    syn_th = fread(fid,1, 'float');
    dummy = fread(fid,6, 'uint16'); % dead_time_comp ...accumulate
    dummy = fread(fid,4, 'uint32'); % flbck_y ...bord_l
    pix_time = fread(fid,1, 'float');
    dummy = fread(fid,2, 'uint16'); % pix_clck, trigger
    scanx = fread(fid,1, 'int32');
    scany = fread(fid,1, 'int32');
    
    % calculate timeRange
    timerange = tac_r/double(tac_g);     % calculated timeRange in s
    timerange = (timerange .* 1e12);        % convert to ps
    
   
   
   % read BHFileBlockHeader;
    next_block_offs = data_block_offs;
    
    datacount = 0;
    for i=1:no_of_data_blocks
        fseek (fid, next_block_offs, 'bof');       
        block_no = fread(fid,1, 'uint16');   %number of the block in the file
        data_offs = fread(fid,1, 'uint32');  % offset of the data block from the beginning of the file
        next_block_offs=fread(fid,1, 'uint32');
        block_type = fread(fid,1, 'uint16');
        meas_desc_block_no = fread(fid,1, 'uint16');    % Number of the measurement description block 
                                                        % corresponding to this data block
        lblock_no = fread(fid,1, 'uint32');
        block_length = fread(fid,1, 'uint32');
        
        datacount = block_length/2;
                
        memmap = memmapfile(filename,'Offset',data_offs,'Format',{'uint16',[datacount 1],'data'});
        a = memmap.Data(1).data;

        block_data_off{i} = data_offs;
        block_datacount{i} = block_length;
        block_data{i} = whole_file((data_offs+1):(data_offs+block_length));
        
    end

    fclose(fid);
    
    whole_file((block_data_off{1}+1):(block_data_off{1}+block_datacount{1})) = block_data{2};
    whole_file((block_data_off{2}+1):(block_data_off{2}+block_datacount{2})) = block_data{1};

    [path,name,ext] = fileparts(filename);
    
    fid = fopen([path '\' name '-swap' ext],'w');
    fwrite(fid,whole_file);
    fclose(fid);
    
end