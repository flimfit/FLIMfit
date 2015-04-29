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
    
    in = [];
    
    if strcmp(class(file_or_image),'char')  % file or dir
        file = file_or_image;
        [~,~,ext] = fileparts_inc_OME(file);
        if strcmp(ext,'.tif')      % Historical only! A single 2D .tif. Not the time-series in this case
             im = imread(file_or_image);
             im = double(im);
        end
    end
    
    if isempty(im)
         throw(MException('GlobalAnalysis:File selected is not a .tif','Error loading background, invalid file selected'));
        return;
    else
    
    
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