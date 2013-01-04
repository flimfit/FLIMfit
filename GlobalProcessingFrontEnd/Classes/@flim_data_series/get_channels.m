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

            %setting 3rd arg to false indicates that no data is to be
            %returned
            dummy_channel = 1; %any no 
            [ImData Delays, chan_info] =loadBHfileusingmeasDescBlock(file, dummy_channel, false);

            n_chan = length(chan_info);


         % .asc files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
         case '.asc'

             n_chan = 1;
             chan_info = {'asc data'};


          % .txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case '.txt'
             tcspc = 1;

             fid = fopen(file);

             header_lines = 0;
             textl = fgetl(fid);
             while ~isempty(textl)
                 first = sscanf(textl,'%f\t');
                 if isempty(first) % if it's not a number skip line
                     %header_title{end+1} = sscanf(textl,'%s');
                     header_lines = header_lines + 1;
                     textl = fgetl(fid);
                 else 
                     textl = [];
                 end                 
             end


             ir = dlmread(file,'\t',header_lines,0);
             n_col = size(ir,2);

             if n_col == 1
                 n_chan = 1;
                 chan_info = {'txt data'};
             else
                 n_chan = n_col - 1;
                 header_rows = isnan(ir(:,1));
                 header = ir(header_rows,2:end);
                 chan_info = cell(n_chan,1);

                 for i=1:n_chan;
                     chan_info{i} = mat2str(header(:,i)');
                 end

             end

        case '.irf'        % Yet another F%^^ing format (for Labview this time)
            n_chan = 1;
            chan_info = {'irf data'};




        otherwise 

            errordlg('Not a .recognised file type!','File Error');
    end
    

end