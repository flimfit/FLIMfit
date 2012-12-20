function [n_chan, chan_info] = get_channels(file)

    %> Determine what channels are available in a file

    if (nargin < 1)
        %selects the folder and a file
        %directory = uigetdir;
        [file,path] = uigetfile('*.*');

        % Check that user didn't cancel
        if (file == 0)
            return
        end

        [~,name,ext] = fileparts(file);
        file = [PathName file];
    else
        [PathName,name,ext] = fileparts(file);
    end


    %cd(PathName);
    switch ext

        % .tif files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case '.tif'
            n_chan = 1;
            chan_info = {'tif data'};

         % .png files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
         case '.png'

            n_chan = 1;
            chan_info = {'png data'};

         % .sdt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
         case '.sdt'

            fid=fopen(file);

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

            % read measurement decription block
            fseek (fid, meas_desc_block_offs, 'bof'); 
            time = fread (fid, 9, 'uint8=>char');
            dated = fread (fid, 11, 'uint8=>char');
            date = dated';
            mod_ser_no = fread (fid, 16, 'uint8=>char');
            meas_mode = fread(fid,1, 'uint16');
            % bunch of stuff I don't as yet understand
            dummy = fread(fid,5, 'float');
            syn_fd = fread(fid,1, 'uint16');
            dummy = fread(fid,2, 'float');
            tac_g = fread(fid,1, 'uint16');
            dummy = fread(fid,3, 'float');
            adc_res = fread(fid,1, 'uint16');        % adc resolution !!
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


           % read BHFileBlockHeader;
            fseek (fid, data_block_offs, 'bof');       
            block_no = fread(fid,1, 'uint16');   %number of the block in the file
            data_offs = fread(fid,1, 'uint32');  % offset of the data block from the beginning of the file
            next_block_offs=fread(fid,1, 'uint32');
            block_type = fread(fid,1, 'uint16');
            meas_desc_block_no = fread(fid,1, 'uint16');    % Number of the measurement description block 
                                                            % corresponding to this data block
            lblock_no = fread(fid,1, 'uint32');
            block_length = fread(fid,1, 'uint32');

            if meas_mode == 0        % single point data     
                n_chan = 1;
                chan_info = {'sdt data'};
            else
                datacount = block_length/2;    % 16 bit data
                im_size = scanx * scany * adc_res;
                n_chan = floor(datacount/im_size);
                chan_info = cell(1,n_chan);
                for i=1:n_chan
                    chan_info{i} = ['sdt channel ' num2str(i)];
                end
            end

            fclose(fid);

         % .asc files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
         case '.asc'

             n_chan = 1;
             chan_info = {'asc data'};


          % .txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case '.txt'
             tcspc = 1;

             fid = fopen(file);

             header_data = cell(0,0);
             textl = fgetl(fid);
             while ~isempty(textl)
                 first = sscanf(textl,'%f\t');
                 if isempty(first) % if it's not a number skip line
                     header_data{end+1} =  textl;
                     textl = fgetl(fid);
                 else 
                     textl = [];
                 end                 
             end
             
             n_header_lines = length(header_data);
             
             header_title = cell(1,n_header_lines);
             header_info = cell(1,n_header_lines);
             
             for i=1:n_header_lines
                 parts = regexp(header_data{i},'\s+','split');
                 header_title{i} = parts{1};
                 header_info{i} = parts(2:end);
                 n_chan = length(header_info{i})-1;
             end

             chan_info = cell(1,n_chan);
             
             for i=1:n_chan
                 for j=1:n_header_lines
                     chan_info{i} = [chan_info{i} header_info{j}{i} ', '];
                 end
                 chan_info{i} = chan_info{i}(1:(end-2));
             end



        case '.irf'        % Yet another F%^^ing format (for Labview this time)
            n_chan = 1;
            chan_info = {'irf data'};




        otherwise 

            errordlg('Not a .recognised file type!','File Error');
    end
    

end