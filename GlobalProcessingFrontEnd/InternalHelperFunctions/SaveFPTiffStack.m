function SaveFPTiffStack(file,images,names,description)

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

    images = single(images);
    
    t = Tiff(file,'w');
    tagstruct.ImageLength = size(images,1);
    tagstruct.ImageWidth = size(images,2);
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
    tagstruct.BitsPerSample = 32;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.RowsPerStrip = 16;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    
    if nargin >= 4
        tagstruct.ImageDescription = description;
    end
   
%    global_tag = tagstruct;
%    global_tag.SubIFD = length(names);
        
%    t.setTag(global_tag);
    
    for i=1:10 %length(names)
    
        if (i > 1)
            t.writeDirectory();
        end

        
        local_tag = tagstruct;
        local_tag.DocumentName = names{i};
        
        t.setTag(local_tag);
        t.write(images(:,:,i))
               
    end
    
    t.close()

end