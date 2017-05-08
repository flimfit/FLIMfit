function load_background(obj, file_or_image, time_average)

    %> Load a background image from a file
    
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
    
    im = [];
    
    if ischar(file_or_image)  % file or dir
        file = file_or_image;
        [~,~,ext] = fileparts_inc_OME(file);
        if strcmp(ext,'.xml')
            obj.marshal_object(file);
            obj.compute_tr_data();
            return;
        end  
        if ~isempty(strfind(ext,'tif'))
            im = imread(file);
            im = double(im);
        end  
        
     else  % omero image
        file = char(file_or_image.getName().getValue());
        [~,~,ext] = fileparts_inc_OME(file);
    end
    
    
    if isempty(im)  % not a .tif
    
        [dims, reader_settings] = obj.get_image_dimensions(file_or_image);
        
        % Determine which plane we need to load (param 5 disallows the
        % selection of multiple planes )
        ZCT = obj.get_ZCT( dims, obj.polarisation_resolved ,dims.chan_info, false);
        
        if isempty(ZCT)
            return;
        end;
        
        if ~isempty(dims.delays)
            sizet = length(dims.delays);
            if ~time_average
                tpoint = [];
                while isempty(tpoint) ||  tpoint > sizet   ||  tpoint < 1
                    prompt = {sprintf(['Data contains ' num2str(sizet) ' time-points. Numbered 0-' num2str(sizet -1) '\n Please select one'])};
                    dlgTitle = 'Time-resolved data! ';
                    defaultvalues = {num2str(sizet -1)};
                    numLines = 1;
                    inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                    if isempty(inputdata)
                        return;
                    end
                    tpoint = str2double(inputdata) + 1;
                end
            end
        else
            if time_average
                errordlg('Please use "load background..."','Not time-resolved data!');
                return;
            end
            sizet = 1;
        end
        
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        
        image_data = zeros(sizet, 1, sizeX, sizeY, 1);
        [success , image_data] = obj.load_flim_cube(image_data, file_or_image, 1, 1, reader_settings, dims, ZCT);
        
        % average across t if 3D data
        if(sizet > 1)
            if time_average
                im = squeeze(mean(image_data,1));
            else
                im = squeeze(image_data(tpoint, :,:,:));
            end
        else
            im = squeeze(image_data);
        end
    end  % end 'not a 'tif'
    
    
     % correct for labview broken tiffs
     if all(im > 2^15)
         im = im - 2^15;
     end
  
     extent = 3;
     im = medfilt2(im,[extent extent],'symmetric');

     if any(size(im) ~= [obj.height obj.width])
         throw(MException('FLIMfit:backgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
     else
         obj.background_image = im;
         obj.background_type = 2;   % this runs obj.compute_tr_data()
     end

     
end