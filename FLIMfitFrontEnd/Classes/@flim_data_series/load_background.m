function load_background(obj, file_or_image)

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
    
    if strcmp(class(file_or_image),'char')  % file or dir
        file = file_or_image;
        [~,~,ext] = fileparts_inc_OME(file);
        if strcmp(ext,'.xml')
            obj.marshal_object(file);
            obj.compute_tr_data();
            return;
        end   
     else  % omero image
        file = char(file_or_image.getName().getValue());
        [~,~,ext] = fileparts_inc_OME(file);
    end
    
     
    dims = obj.get_image_dimensions(file_or_image);
    
    % Determine which plane we need to load (param 5 disallows the
    % selection of multiple planes )
    ZCT = obj.get_ZCT( dims, obj.polarisation_resolved ,dims.chan_info, false);
    
    if isempty(ZCT)
        return;
    end;
    
    if ~isempty(dims.delays)
        sizet = length(dims.delays);
    else
        sizet = 1;
    end
    
    sizeX = dims.sizeXY(1);
    sizeY = dims.sizeXY(2);
    
    image_data = zeros(sizet, 1, sizeX, sizeY, 1);
    [success , image_data] = obj.load_flim_cube(image_data, file_or_image,1, dims, ZCT);
    
    % average across t if 3D data
    if(sizet > 1)
        im = squeeze(mean(image_data,1));
    else
        im = squeeze(image_data);
    end
    
    

     % correct for labview broken tiffs
     if all(im > 2^15)
         im = im - 2^15;
     end

     %{
     extent = 3;
     kernel1 = ones([extent 1]) / extent;
     kernel2 = ones([1 extent]) / extent;
     filtered = conv2nan(im,kernel1);
     im = conv2nan(filtered,kernel2);
     %}

     extent = 3;
     im = medfilt2(im,[extent extent],'symmetric');


     if any(size(im) ~= [obj.height obj.width])
         throw(MException('GlobalAnalysis:BackgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
     else
         obj.background_image = im;
         obj.background_type = 2;
     end

     
     obj.compute_tr_data();
    
end