function save_segmented_labelled_FOV_as_Omero_ROI_masks( session, segmmask, image, text_label ) % L - source

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

            iUpdate = session.getUpdateService();  

            % create and store Omero ROIs
            stats = regionprops(segmmask,'PixelList');
            for k=1:numel(stats)
                    X = stats(k).PixelList(:,1);
                    Y = stats(k).PixelList(:,2);
                    %
                    x0 = min(X);
                    y0 = min(Y);
                    W = max(X) - x0 + 1;
                    H = max(Y) - y0 + 1;
                    %
                    m = zeros(W,H);
                    for j = 1 : numel(X),
                        x = X(j) - x0 + 1;
                        y = Y(j) - y0 + 1;
                        m(x,y) = 1;                        
                    end
                    %
                    mask = createMask(x0,y0,m);
                    % mask.setTextValue(omero.rtypes.rstring(text_label));                    
                    setShapeCoordinates(mask, 0, 0, 0);
                    %
                    roi = omero.model.RoiI;
                    roi.setDescription(omero.rtypes.rstring(text_label));
                    roi.addShape(mask);                    
                    %
                    roi.setImage(omero.model.ImageI(image.getId.getValue, false));
                    roi = iUpdate.saveAndReturnObject(roi);
            end    
end

