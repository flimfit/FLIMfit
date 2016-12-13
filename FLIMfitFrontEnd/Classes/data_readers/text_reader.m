classdef text_reader < base_data_reader
   
    properties
        dlm;
    end
    
    methods
        
        function obj = text_reader(filename)
            obj.filename = filename;
            
            
            if strcmp(obj.ext,'.txt')
                obj.dlm = '\t';
            else
                obj.dlm = ',';
            end

            fid = fopen(file);
            header_data = cell(0,0);
            textl = fgetl(fid);

            if strcmp(textl,'TRFA_IC_1.0')
                fclose(fid_);
                throw(MException('FLIMfit:CannotOpenTRFA','Cannot open TRFA formatted files'));
            end

            while ~isempty(textl)
                first = sscanf(textl,['%f' obj.dlm]);
                if isempty(first) || isnan(first(1))
                    header_data{end+1} =  textl;
                    textl = fgetl(fid);
                else
                    textl = [];
                end
            end

            fclose(fid);

            n_header_lines = length(header_data);
            header_info = cell(1,n_header_lines);

            n_chan = zeros(1,n_header_lines);
            wave_no = [];

            for i=1:n_header_lines
              parts = regexp(header_data{i},[ '\s*' obj.dlm '\s*' ],'split');
              header_info{i} = parts(2:end);
              tag = parts{1};
              % find which line describes wavelength
              if strfind(lower(tag),'wave')
                  wave_no = i;
              end
              n_chan(i) = length(header_info{i});
            end
            n_chan = min(n_chan);

            chan_info = cell(1,n_chan);

            % by default use well for chan_info
            for i=1:n_chan
              chan_info{i} = header_info{1}{i};
            end

            % catch headerless or unreadable headers
            if isempty(n_chan) || n_chan < 1
              n_chan = 1;
              chan_info{1} = '1';
            end

            if n_chan > 1  && ~isempty(wave_no)  % no point in following code for a single channel
              % if all wells appear to be the same 
              % then use wavelength instead
              if strcmp(chan_info{1} ,chan_info{end})
                % check size matches
                if length(header_info{wave_no}) > 2  &&  length(header_info{wave_no}) == n_chan
                    for i=1:n_chan
                      chan_info{i} = header_info{wave_no}{i};
                    end
                end
              end
            end

            ir = dlmread(file,dlm,n_header_lines,0);
            obj.txtInfoRead = ir;    % save ir into class

            delays(1,:) = ir(:,1);

            delays = delays(~isnan(delays));

            % crude ns -> ps conversion
            if max(delays) < 1000
                delays = delays * 1000;
            end

            obj.delays = delays;
            obj.chan_info = chan_info;
            obj.FLIM_type = 'TCSPC';
            obj.sizeZCT = [1 n_chan 1];
            obj.sizeXY = [1 1];

        end
        
        function data = read(obj, selected)
        
            ir = [];
            
            % if this is the same file from which we got the image
            % dimensions
            if ~isempty(obj.file_names)  && ~isempty(obj.txtInfoRead)
                if strcmp(file,obj.file_names(1) )
                    ir = obj.txtInfoRead;
                end
            end
            
            if isempty(ir)
                % decode the header & load the data
                header_data = obj.parse_csv_txt_header(file);
                if isempty(header_data)
                    n_header_lines = 0;
                else
                    n_header_lines = length(header_data);
                end
                ir = dlmread(file,obj.dlm,n_header_lines,0);
               
            end
            
            data = ir(:,selected);
                        
        end
        
    end
    
    
    
end