function load_background(obj, image)

    %> Load a background image from an OMERO image

   
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
    
   
    dims = obj.get_image_dimensions(image);
        
    chan_info = dims.chan_info;
    
    if ~isempty(dims.delays)
        errordlg('Unable to load. Time-resolved data!');
        return;
    end
        

    % Determine which channels we need to load (param 5 disallows the
    % selection of multiple planes )
    ZCT = obj.get_ZCT( dims, obj.polarisation_resolved ,chan_info, false);
    
    if isempty(ZCT)
        return;
    end;
        
    image_data = zeros(1, 1, dims.sizeXY(1), dims.sizeXY(2), 1);
    [success ,image_data] = obj.load_flim_cube(image_data,image,1, dims,ZCT);
    im = squeeze(image_data);
   
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
    im = medfilt2_noPPL(im,[extent extent],'symmetric');
    
    
    if any(size(im) ~= [obj.height obj.width])
        throw(MException('GlobalAnalysis:BackgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
    else
        obj.background_image = im;
        obj.background_type = 2;
    end


    obj.compute_tr_data();


end