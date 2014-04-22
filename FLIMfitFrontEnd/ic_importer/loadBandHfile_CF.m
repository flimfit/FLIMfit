%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%        LoadBandHfile extract header information and data from a   %%
%%        Becker-Hickl TCSPC .sdt data file                          %%
%%                                                                   %%
%%        input: path2BandHfile == path to the BandH .sdt file       %%
%%               rep_rate (optional) == laser repetition rate        %%
%%                                                                   %%
%%        output: SPCdata == data blocks of the .sdt file            %%
%%                delays  == time axis for SPCdata                   %%
%%                                                                   %%
%%        author: Pieter De Beule                                    %%
%%        date: 02-12-05                                             %%
%%        contact: p.debeule@imperial.ac.uk;                         %%
%%                 pieter.debeule@tiscali.be                         %%
%%        version: 0.0.1                                             %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Modified extensively by Cliff

function [SPCdata] = loadBandHfile_CF(path2BandHfile, channel, shift)

% The functions used to access the .sdt files can be found in the Matlab
% Help under 'Low-Level File I/O'

BandH_file_id  =  fopen(path2BandHfile);

% We will sequentially read in the File Header, File Info, Setup,
% Measurement Description Blocks and Data Blocks section.  The data
% structure can be found in ref [1]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                        FILE HEADER                            %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

revision                          =  fread(BandH_file_id,1, 'uint16');
info_offset                       =  fread(BandH_file_id,1, 'uint32');
info_length                       =  fread(BandH_file_id,1, 'uint16');
setup_offs                        =  fread(BandH_file_id,1, 'uint32');
setup_length                      =  fread(BandH_file_id,1, 'uint16');
data_block_offset                 =  fread(BandH_file_id,1, 'uint32');
no_of_data_blocks                 =  fread(BandH_file_id,1, 'uint16');
data_block_length                 =  fread(BandH_file_id,1, 'uint32');
meas_desc_block_offset            =  fread(BandH_file_id,1, 'uint32');
no_of_meas_desc_blocks            =  fread(BandH_file_id,1, 'uint16');
meas_desc_block_lenght            =  fread(BandH_file_id,1, 'uint16');
header_valid                      =  fread(BandH_file_id,1, 'uint16');
reserved1                         =  fread(BandH_file_id,1, 'uint32');
reserved2                         =  fread(BandH_file_id,1, 'uint16');
chksum                            =  fread(BandH_file_id,1, 'uint16');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                        FILE INFO                              %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if fseek(BandH_file_id, info_offset, 'bof') == 0
    ;
else
    error = 'failed file seek';
end
file_info               =  fread(BandH_file_id,info_length,'uint8=>char');
%sprintf(file_info);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                          SETUP                                %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if fseek(BandH_file_id,setup_offs,'bof') == 0
    ;
else
    error = 'failed file seek';
end
setup                   =  fread(BandH_file_id,setup_length,'uint8=>char');
setup                   =  setup';
%varargout{1}            =  setup;

% now we extract the desired parameters out of the setup string:
% 1: acquistion mode
% mode_str                =  'SP_MODE,I,';
% mode_pos                =  findstr(mode_str,setup) + size(mode_str,2);
% temp                    =  findstr(']',setup(mode_pos:mode_pos+50));
% mode_close              =  temp(1);
% mode                    =  str2num(setup(mode_pos:mode_pos+mode_close-2));
mode = ReadBHSetupValue(setup, 'SP_MODE,I,');

% 2: number of time bins
% t_bins                  =  'SP_ADC_RE,I,';
% t_bins_pos              =  findstr(t_bins,setup) + size(t_bins,2);
% temp                    =  findstr(']',setup(t_bins_pos:t_bins_pos+50));
% t_bins_close            =  temp(1);
% t_bins                  =  str2num(setup(t_bins_pos:t_bins_pos+t_bins_close-2));
t_bins = ReadBHSetupValue(setup, 'SP_ADC_RE,I,');


switch mode
    case 0
        % 3: number of pages:
%         page_str        =  'SP_SCAN_RX,I,';
%         page_pos        =  findstr(page_str,setup) + size(page_str,2);
%         temp            =  findstr(']',setup(page_pos:page_pos+50));
%         page_close      =  temp(1);
%         page            =  str2num(setup(page_pos:page_pos+page_close-2));        
        page = ReadBHSetupValue(setup, 'SP_SCAN_RX,I,');
    case 2
        % 3: number of channels X and Y
%         X_chan_str      =  'SP_NCX,I,';
%         Y_chan_str      =  'SP_NCY,I,';
%         X_chan_pos      =  findstr(X_chan_str,setup) + size(X_chan_str,2);
%         Y_chan_pos      =  findstr(Y_chan_str,setup) + size(Y_chan_str,2);
%         temp1           =  findstr(']',setup(X_chan_pos:X_chan_pos+50));
%         temp2           =  findstr(']',setup(Y_chan_pos:Y_chan_pos+50));
%         X_chan_close    =  temp1(1);
%         Y_chan_close    =  temp2(1);
%         X_chan          =  str2num(setup(X_chan_pos:X_chan_pos+X_chan_close-2));
%         Y_chan          =  str2num(setup(Y_chan_pos:Y_chan_pos+Y_chan_close-2));
        X_chan = ReadBHSetupValue(setup, 'SP_NCX,I,');
        Y_chan = ReadBHSetupValue(setup, 'SP_NCY,I,');
    case 9
        % 3: number of steps/pages
%         page_str        =  'SP_SCAN_RX,I,';
%         page_pos        =  findstr(page_str,setup) + size(page_str,2);
%         temp            =  findstr(']',setup(page_pos:page_pos+50));
%         page_close      =  temp(1);
%         page            =  str2num(setup(page_pos:page_pos+page_close-2));
        page = ReadBHSetupValue(setup, 'SP_SCAN_RX,I,');
         % 4: X and Y resolution of the images
%         X_res           =  'SP_SCAN_X,I,';
%         Y_res           =  'SP_SCAN_Y,I,';
%         X_res_pos       =  findstr(X_res,setup) + size(X_res,2);
%         Y_res_pos       =  findstr(Y_res,setup) + size(Y_res,2);
%         temp1           =  findstr(']',setup(X_res_pos:X_res_pos+50));
%         temp2           =  findstr(']',setup(Y_res_pos:Y_res_pos+50));
%         X_res_close     =  temp1(1);
%         Y_res_close     =  temp2(1);
%         X_res           =  str2num(setup(X_res_pos:X_res_pos+X_res_close-2));
%         Y_res           =  str2num(setup(Y_res_pos:Y_res_pos+Y_res_close-2));
        X_res = ReadBHSetupValue(setup, 'SP_SCAN_X,I,');
        Y_res = ReadBHSetupValue(setup, 'SP_SCAN_Y,I,');
    case 13
        % 4: X and Y resolution of the images
%         X_res           =  'SP_IMG_X,I,';
%         Y_res           =  'SP_IMG_Y,I,';
%         X_res_pos       =  findstr(X_res,setup) + size(X_res,2);
%         Y_res_pos       =  findstr(Y_res,setup) + size(Y_res,2);
%         temp1           =  findstr(']',setup(X_res_pos:X_res_pos+50));
%         temp2           =  findstr(']',setup(Y_res_pos:Y_res_pos+50));
%         X_res_close     =  temp1(1);
%         Y_res_close     =  temp2(1);
%         X_res           =  str2num(setup(X_res_pos:X_res_pos+X_res_close-2));
%         Y_res           =  str2num(setup(Y_res_pos:Y_res_pos+Y_res_close-2));        
        X_res = ReadBHSetupValue(setup, 'SP_IMG_X,I,');
        Y_res = ReadBHSetupValue(setup, 'SP_IMG_Y,I,');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%               MEASUREMENT DESCRIPTION BLOCK                   %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                          DATA                                 %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if fseek(BandH_file_id,data_block_offset, 'bof') == 0
    ;
else
    error = 'failed file seek';
end
block_no                          =  fread(BandH_file_id,1, 'uint16');
data_offs                         =  fread(BandH_file_id,1, 'uint32');
next_block_offs                   =  fread(BandH_file_id,1, 'uint32');
block_type                        =  fread(BandH_file_id,1, 'uint16');
meas_desc_block_no                =  fread(BandH_file_id,1, 'uint16');
lblock_no                         =  fread(BandH_file_id,1, 'uint32');
block_length                      =  fread(BandH_file_id,1, 'uint32');

% Read the data (the data read out depends on the acquisition mode (mode)
if fseek(BandH_file_id,data_offs, 'bof') == 0
    ;
else
    error = 'failed file seek';
end

switch mode
    case 0
        data_size               = page*t_bins;
        SPCdata                 = reshape(fread(BandH_file_id, data_size, '*uint16'), t_bins, page)';
    case 2
        data_size              =  t_bins*X_chan*Y_chan;
        SPCdata                =  fread(BandH_file_id,data_size, '*uint16');
        SPCdata                =  reshape(SPCdata,t_bins,X_chan,Y_chan);
    case 9
        data_size              =  t_bins*X_res*X_res;
        SPCdata                =  zeros(page,t_bins,X_res,Y_res, 'uint16');
        for i=1:page   
            temp               =  fread(BandH_file_id,data_size, '*uint16');
            SPCdata(i,:,:,:)   =  reshape(temp,t_bins,X_res,Y_res);
        end     
        if page == 1
            SPCdata            =  reshape(SPCdata,t_bins,X_res,Y_res);
        end
        
    case 13
        data_size = t_bins*X_res*Y_res;
        %if data_size > hex2dec(8000);
        SPCdata = zeros(no_of_data_blocks, t_bins, X_res, Y_res, 'uint16');
        next_block_offs = data_block_offset;
        
        w = waitbar(0, 'Loading data, please wait');
        for i = 1:no_of_data_blocks
            fseek(BandH_file_id, next_block_offs + 2, 'bof');
            data_offs = fread(BandH_file_id, 1, 'uint32');
            next_block_offs = fread(BandH_file_id, 1, 'uint32');
            fseek(BandH_file_id, data_offs, 'bof');
            
            SPCdata(i, :, :, :) = reshape(fread(BandH_file_id, data_size, 'uint16=>uint16'), t_bins, X_res, Y_res);
                                    
            waitbar(i/no_of_data_blocks, w);
            drawnow;
        end
        delete(w);
        drawnow;
end

%SPCdata = uint16(SPCdata); 

fclose(BandH_file_id);


% [1] pag 188, SPC-830 manual: Time-Correlated Single Photon Counting
% Modules/ Multi SPC software

end


function return_number = ReadBHSetupValue(setup, search)

start_pos = strfind(setup, search) + size(search, 2);
end_pos = start_pos + ...
    strfind(setup(start_pos:(start_pos + 10)), ']') - 2;

return_number = str2num(setup(start_pos:end_pos));
end
