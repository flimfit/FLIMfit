classdef tif_reader < base_data_reader
   
    properties
        data
    end
    
    methods
        
        function obj = irf_reader(filename)
            obj.filename = filename;

            path = fileparts(obj.file_name);
            dirStruct = [dir([path filesep '*.tif']) dir([path filesep '*.tiff'])];
            files = {dirStruct.name};
            [obj.delays,obj.t_int] = get_delays_from_tif_stack(files);
            
            if sum(isnan(obj.delays)) > 0
                throw(MException('FLIMfit:errorReadingFile','Unrecognised file-name convention');
            end
            
            first = [path filesep files{1}];
            info = imfinfo(first);
                        
            %NB dimensions reversed to retain compatibility with earlier code
            obj.sizeXY = [ info.Height info.Width ];
            obj.FLIM_type = 'Gated';  
            obj.sizeZCT = [1 1 1];
        end
        
        function target = read(obj, selected)
            
            path = fileparts(obj.filename);
            dirStruct = [dir([path filesep '*.tif']) dir([path filesep '*.tiff'])];
            files = {dirStruct.name};
            [~,~,files] = get_delays_from_tif_stack(files);
            
            
            if length(files) ~= length(obj.delays)
                throw(MException('FLIMfit:errorReadingTif','Unexpected number of images'));
            end
            
            if verbose
                w = waitbar(0, 'Loading FLIMage....');
                drawnow;
            end
            
            for p = 1:length(obj.delays)
                filename = [path filesep files{p}];
                plane = imread(filename,'tif');
                target(p,1,:,:) = plane;
                if verbose
                    waitbar(sizet/p,w);
                    drawnow;
                end
            end
                            
            if min(target(:,1,:,:,write_selected)) > 32500
                target(:,1,:,:,write_selected) = target(:,1,:,:,write_selected) - 32768;    % clear the sign bit which is set by labview
            end
            
            if verbose
                delete(w);
                drawnow;
            end
            
        end
        
    end
   
end


