function L = get_FOV_masks( session,image, description )

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

pixelsList = image.copyPixels();    
pixels = pixelsList.get(0);
            
imH = pixels.getSizeX().getValue();
imW = pixels.getSizeY().getValue();

segmmask_restored = zeros(imW,imH);

service = session.getRoiService();
roiResult = service.findByImage(image.getId.getValue, []);
rois = roiResult.rois;
n = rois.size;
for thisROI  = 1:n
    roi = rois.get(thisROI-1);
    
    if isempty(description) || strcmp(char(roi.getDescription().getValue()),description)
        
        numShapes = roi.sizeOfShapes; % an ROI can have multiple shapes.
        for ns = 1:numShapes
            shape = roi.getShape(ns-1); % the shape

             if (isa(shape, 'omero.model.Mask'))
                y0 = shape.getX().getValue - 1;
                x0 = shape.getY().getValue - 1;
                W = shape.getWidth().getValue;
                H = shape.getHeight().getValue;
                bytes = shape.getBytes();
                mask = reshape(bytes,[H,W]);

                for x=1:W
                    for y=1:H
                        if(0~=mask(y,x))
                            segmmask_restored(x0+x,y0+y) = 1;
                        end                    
                    end
                end

             end
        end
        
    end
end

L = bwlabel(segmmask_restored);
L = L(1:imW,1:imH); % ??

end

