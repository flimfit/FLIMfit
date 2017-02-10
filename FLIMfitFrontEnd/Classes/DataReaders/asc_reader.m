classdef asc_reader < base_data_reader
   
    properties
        im_data
    end
    
    methods
        
        function obj = asc_reader(filename)
            obj.filename = filename;

            data_unselected = dlmread(file);
            siz = size(data_unselected);

            % 1d or 2d data
            if length(siz) == 2  % if  data is 2D  not 3d
                if siz(2) < 3  % transpose data from column to row if it's x by 1 or x by 2
                    data_unselected = data_unselected';
                    siz = size(data_unselected);
                end

                if siz(1) == 2

                    % check if 1 is the delays
                    if max(data_unselected(1,:)) == data_unselected(1,end)
                        obj.delays = squeeze(data_unselected(1,:));
                        obj.im_data = squeeze(data_unselected(2,:));   % discard delays
                    else
                        obj.delays = squeeze(data_unselected(2,:));
                        obj.im_data = squeeze(data_unselected(1,:));
                    end
                    nbins = length(obj.im_data);
                    obj.im_data = reshape(obj.im_data,nbins,1,1);     
                end

                % 1d data
                if siz(2) == 1 || siz(1) == 1

                    % if up to 1024 data points then assume a single-point
                    % decay & 12.5ns

                    if length(data_unselected) <  1025
                        nbins = length(data_unselected);
                        obj.im_data = reshape(data_unselected,[nbins,1,1,1]);
                        obj.delays = (0:nbins-1)*12500.0/nbins;
                    else
                        % too long for a single-point decay so assume a square
                        % image res by res & assume 64 time bins 
                        % TODO : wtf?
                        res = sqrt(length(data_unselected)/64);
                        obj.im_data = reshape(data_unselected, [64, 1, res, res]);
                        obj.delays = (0:63)*12500.0/64;
                    end
                end

            else 
                throw(MException('FLIMfit:errorReadingFile','Could not read asc file'));
            end

            siz = size(data);
            if length(siz) == 2 % single pixel data 1xn or nx1
                obj.sizeXY = [1 1];
            else
                obj.sizeXY = siz(end-1:end);
            end
            obj.FLIM_type = 'TCSPC';  
            obj.sizeZCT = [1, 1, 1];
            
        end
        
        function data = read(obj, zct, channels)
            assert(all(channels == 1));
            assert(all(zct==1));
            data = obj.im_data;
        end
        
    end
    
    
    
end