function load_background(obj, file)

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
    
    
    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.xml')
       
        obj.marshal_object(file);
    
    else
    
        if isdir(file)
        % load a series of images

            files = dir([file filesep '*.tif']);

            im = 0;
            for i=1:length(files)
                imi = imread([file filesep files(i).name]);
                im = im + double(imi);
            end
            im = im / length(files);

        else

            im = imread(file);      
            im = double(im);

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
        im = medfilt2_noPPL(im,[extent extent],'symmetric');


        if any(size(im) ~= [obj.height obj.width])
            throw(MException('GlobalAnalysis:BackgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
        else
            obj.background_image = im;
            obj.background_type = 2;
        end    
    end
    
    obj.compute_tr_data();
    
end