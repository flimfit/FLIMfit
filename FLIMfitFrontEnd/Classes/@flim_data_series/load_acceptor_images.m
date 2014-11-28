function load_acceptor_images(obj,path)

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
    
    if isdir(path)
    
        path = ensure_trailing_slash(path);

        obj.acceptor = zeros([obj.height obj.width obj.n_datasets]);

        options = acceptor_options_dialog();
        
        ZCT{1} = 1;
        ZCT{2} = 2;
        ZCT{3} = 1;

        if ~isempty(options.background)
            
            % check dimensions of the first file
            file_name = options.background;
            dims = obj.get_image_dimensions(file_name);
            if length(dims.delays) > 1 
                errordlg('Not yet implemented for time-resolved data data');
                return;
            end
            
            bg_data  = zeros(1, 1,  obj.height, obj.width);
            [success, bg_data] = obj.load_flim_cube(bg_data, file_name,1,dims,ZCT);
            bg = squeeze(bg_data);
           
            % correct for labview broken tiffs
            if all(bg > 2^15)
                bg = bg - 2^15;
            end
        else
            bg = 0;
        end
        
        if length(obj.file_names) == 1 && obj.n_datasets > 1 
            errordlg(' Not yet implemented for multi-plane data');
            return;
        end
        
        file_names = [];
        
        % first check that we can find a matching name for each dataset
        for i=1:obj.n_datasets  
           
            items =  dir([path '*' obj.names{i} '*']);
         
            if numel(items) == 1
                item = items(1);
                if item.isdir  % assuming a dir containing a single .tif
                    tifname = dir([path item.name filesep  '*' '.tif']);
                    file_names{i} = [path item.name filesep tifname(1).name];
                else
                    disp('not a dir')
                end
            end
            
        end
        
        if length(file_names) ~= obj.n_datasets
            errordlg('Failed to match all names');
            return;
        else
            
            % check dimensions of the first file
            dims = obj.get_image_dimensions(file_names{1});
            if sum(dims.sizeZCT) > 3 
                errordlg('Not yet implemented for multi-plane data');
                return;
            end
                
        end
       
        obj.acceptor = zeros([obj.height obj.width obj.n_datasets]);
        
        
        sizet = length(dims.delays);
        acc_data = zeros(sizet, 1,  obj.height, obj.width);
        
        %h = waitbar(0,'Loading Acceptor Images...');
        for i=1:obj.n_datasets
            
            if sizet > 1
                % insert code to handle 3d images here
                
            else
                [success, acc_data] = obj.load_flim_cube(acc_data, file_names{i},1,dims,ZCT);
                im = squeeze(acc_data);
            end
                
            im = medfilt2_noPPL(im,[7 7]);

            if bg == 0
                im = im - min(im(:));
            else
                im = im - bg;
            end

            if options.align
                intensity = obj.integrated_intensity(i);
                im = align_images(im, intensity, true);
            end

            obj.acceptor(:,:,i) = im;
                        
            %waitbar(i/obj.n_datasets,h);
        end
        %close(h);
    else
        % import labelled tif stack  
        obj.acceptor = zeros([obj.height obj.width obj.n_datasets]);
        obj.acceptor = ReadSelectedFromTiffStack(path,obj.names,'Acceptor');
        obj.acceptor(isnan(obj.acceptor)) = 0;
        
    end
  
end