folder = 'Y:\User Lab Data\Sean Warren\00 MicroscopyData\Imperial\Multiplexed\2011-10-26 AKT-PH\bg 5s\';

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


fdrs = dir(folder);

img = {};

for i=2:length(fdrs)
    
   if isdir([folder fdrs(i).name])
        f = [folder fdrs(i).name];
        images = dir([f '\*.tif']);
        for j=1:length(images)
           
            img{end+1} = imread([f filesep images(j).name]);
            
            img{end} = double(img{end} - 32768);
            
        end
   end
    
    
end

mn = 0;

for i=1:length(img)
    
    mn = mn + img{i};
    
end

mn = mn / length(img);
%%
%kernel = ones(3,3);
%kernel = kernel / sum(kernel(:));

mns = medfilt2_noPPL(mn,[3 3]);   

imagesc(mns)

SaveFPTiff(mns,[folder '\mean_bg.tif']);
    
