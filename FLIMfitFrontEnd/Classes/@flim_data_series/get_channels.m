function [n_chan, chan_info, tcspc] = get_channels(file)

    %> Determine what channels are available in a file
    
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
            tcspc = 0;
            n_chan = 1;
            chan_info = {'tif data'};

         % .png files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
         case '.png'
            tcspc = 0;
            n_chan = 1;
            chan_info = {'png data'};

         % .sdt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
         case '.sdt'
            %passing -2 for the channel stops data being returned
            [ImData, Delays, n_chan] = loadBHfileusingmeasDescBlock(file, -2);

            if n_chan == 1

                chan_info = {'sdt data'};
            else
                
                chan_info = cell(1,n_chan);
                for i=1:n_chan
                    chan_info{i} = ['sdt channel ' num2str(i)];
                end
            end

            

         % .asc files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
         case '.asc'

             n_chan = 1;
             chan_info = {'asc data'};

         % .bin files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
         case '.bin'
             tcspc = 1;
             n_chan = 1;
             chan_info = {'bin data'};             

          % .txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case '.txt'
             tcspc = 1;

             fid = fopen(file);

             header_data = cell(0,0);
             textl = fgetl(fid);
             while ~isempty(textl)
                 first = sscanf(textl,'%f\t');
                 if strncmp(textl,'TRFA',4) || isempty(strtrim(textl))
                     textl = fgetl(fid);
                 elseif isempty(first) || isnan(first(1)) % if it's not a number skip line
                     header_data{end+1} =  textl;
                     textl = fgetl(fid);
                 else 
                     textl = [];
                 end                 
             end
             
             n_header_lines = length(header_data);
             
             header_title = cell(1,n_header_lines);
             header_info = cell(1,n_header_lines);
             
             n_chan = 0;
             for i=1:n_header_lines
                 parts = regexp(header_data{i},'\s*\t\s*','split');
                 header_title{i} = parts{1};
                 header_info{i} = parts(2:end);
                 n_chan = max(length(header_info{i}),n_chan);
             end

             chan_info = cell(1,n_chan);
             
             for i=1:n_chan
                 chan_info{i} = header_info{1}{i};
                 %for j=1:n_header_lines
                 %    chan_info{i} = [chan_info{i} header_info{j}{i} ', '];
                 %end
                 %chan_info{i} = chan_info{i}(1:(end-2));
             end



        case '.irf'        % Yet another F%^^ing format (for Labview this time)
            n_chan = 1;
            chan_info = {'irf data'};
            tcspc = 0;




        otherwise 
            
            errordlg('Not a .recognised file type!','File Error');
    end
    

end