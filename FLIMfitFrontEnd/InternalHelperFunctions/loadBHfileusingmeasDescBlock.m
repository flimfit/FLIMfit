function [ImData Delays noOfChannels] = loadBHfileusingmeasDescBlock(filename, channel, blockk)


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
    
    
    
    if no_of_data_blocks > 1
        
        if blockk < 1 || blockk > no_of_data_blocks
            blockk = no_of_data_blocks;
        end
        %{
        blockk = uint32(0);
        dlgTitle = 'Multi-block file: Select block';
        prompt = {'Block '};
        defaultvalues = {'1'};
        numLines = 1;
        while (blockk < 1) || (blockk > no_of_data_blocks)
            inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
            blockk = uint32(str2num(inputdata{1}));
        end
        %}
    else
        blockk = 1;
        
    end
   %}
    
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
    
    a = [];
    datacount = 0;
    %Cliff%for i=1:no_of_meas_desc_blocks
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
        

        if meas_mode == 13
            % in mode 13, the channels are stored in different data blocks.
            % (This is true for data blocks of 32 MB length, but may not be
            % so for shorter data blocks.)
            if channel == i
                datacount = block_length/2;
                memmap = memmapfile(filename,'Offset',data_offs,'Format',{'uint16',[datacount 1],'data'});
                a = memmap.Data(1).data;
            end
        else
            if blockk == i
                datacount = block_length/2;
                memmap = memmapfile(filename,'Offset',data_offs,'Format',{'uint16',[datacount 1],'data'});
                a = memmap.Data(1).data;
            else
    %            datacount = datacount + block_length/2;
    %            a = [a; fread(fid, block_length/2, 'uint16')];
            end
        end
        
    end
    
    
     if channel < -1             % deliberately choosing a -ve channel of -2 or less indicates that no data is to be returned
        
         if meas_mode == 13
             noOfChannels = no_of_data_blocks;
             return;
         end
         
         
        if meas_mode == 0        % single point data     
            noOfChannels = 1;     
        else
            im_size = scanx * scany * adc_res;
            noOfChannels = floor(datacount/im_size);      
        end
        return;
    end
        
    
    if meas_mode == 0 || meas_mode == 1        % single point data     
        fseek (fid, data_offs, 'bof'); 
        %[ ImData,  successfullyRead] =fread(fid, adc_res, 'uint16');   % single curve
        
        imSize = adc_res;
        % find no of channels
        
        if datacount/imSize < 1
            scanx = 1;
            scany = 1;
            noOfChannels = datacount/adc_res;
        else
            noOfChannels = floor(datacount/imSize);
        end
        
        switch noOfChannels
            
            case 1
                
                ImData = a;
                
            otherwise
                
                chanLength = datacount/noOfChannels;
                
                if channel == -1
                    chann = uint32(0);
                    dlgTitle = 'Select channel';
                    prompt = {'Channel '};
                    defaultvalues = {'1'};
                    numLines = 1;
                    while (chann < 1) || (chann > noOfChannels)
                        inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                        chann = uint32(str2num(inputdata{1}));
                    end
                else
                    chann = channel;
                end

                for c=1:length(chann)
                    channelData = a(((chann(c) - 1)*chanLength)+1:chann(c)*chanLength);
                    chanImData = reshape(channelData, adc_res, 1, 1);
                    
                    ImData(:,c,:,:) = chanImData;
                end
                
        end
        
    else
        %datacount = block_length/2;    % 16 bit data
        %[a, successfullyRead] =fread(fid, datacount, 'uint16');
        
        %fclose(fid);
        %memmap = memmapfile(filename,'Offset',data_offs,'Format',{'uint16',[datacount 1],'data'});
        %a = memmap.Data(1).data;
        %successfullyRead = datacount;
        
        if meas_mode == 13
            % mode 13 corresponds to fifo image mode, with the data
            % converted to histogram format. The scan_x and scan_y
            % parameters saved in the measurement description block do not
            % correspond to the x and y resolution (I can't find them).
            % Instead they have to be read out from the setup string.
            scanx = ReadBHSetupValue(setup_string, 'SP_IMG_X,I,');
            scany = ReadBHSetupValue(setup_string, 'SP_IMG_Y,I,');
        end
        
        imSize = scanx * scany * adc_res;
        % find no of channels
        
        if datacount/imSize < 1
            scanx = 1;
            scany = 1;
            noOfChannels = datacount/adc_res;
        else
            noOfChannels = floor(datacount/imSize);
        end
            
        switch noOfChannels
            
        case 1

            chanLength = datacount;
            xdim = chanLength/(adc_res * scany);   %calculate the limited dimensiom
            ImData = reshape(a(1:chanLength), adc_res, xdim , chanLength/(adc_res * xdim));
            ImData = ImData(:,1:scanx,:);
            % clear ridiculously bright pixels at bottom (RH side?? ) of image
            if scanx > 1 && scany > 1
                ImData(:,end,:) = 0;
            end
            
            
%            s = size(ImData);
%            ImData = reshape(ImData,[s(1) 1 s(2) s(3)]);

        otherwise   


            chanLength = datacount/noOfChannels;
            xdim = chanLength/(adc_res * scany);   %calculate the limited dimensiom
            
            if noOfChannels == 0
                chann = 1;
               
            elseif channel == -1
                chann = uint32(0);
                dlgTitle = 'Select channel';
                prompt = {'Channel '};
                defaultvalues = {'1'};
                numLines = 1;
                while (chann < 1) || (chann > noOfChannels)
                    inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                    chann = uint32(str2num(inputdata{1}));
                end
            else
                chann = channel;
            end
                        
            for c=1:length(chann)
                channelData = a(((chann(c) - 1)*chanLength)+1:chann(c)*chanLength);
                chanImData = reshape(channelData, adc_res, xdim , chanLength/(adc_res * xdim));
                chanImData = chanImData(:,1:scanx,:);

                if scanx > 1 && scany > 1
                % clear ridiculously bright pixels at bottom (RH side?? ) of image
                    chanImData(:,end,:) = 0;
                end

                if c==2
                    chanImData = circshift(chanImData,[0,0,0]);
                end
                
                ImData(:,c,:,:) = chanImData;
            end
            
        end
        
    end
    

Delays= (0:timerange/adc_res:timerange-timerange/adc_res);


fclose(fid);

end

function return_number = ReadBHSetupValue(setup, search)

start_pos = strfind(setup, search) + size(search, 2);
end_pos = start_pos + ...
    strfind(setup(start_pos:(start_pos + 10)), ']') - 2;

return_number = str2num(setup(start_pos:end_pos));
end