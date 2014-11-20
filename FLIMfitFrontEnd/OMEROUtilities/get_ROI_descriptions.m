function descs = get_ROI_descriptions( session,  d )

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

str = [];
thisFOVstr = [];
descs = [];


service = session.getRoiService();



sizet = d.n_t;
zct = [d.ZCT{1}(1)-1 d.ZCT{2}(1)-1 d.ZCT{3}(1)-1];
zct(3) = zct(3).*sizet; % first time-bin in the real-time point

% first list all the ROI descriptions with matching ZCT in the first image
image = d.file_names{1};        % default image

roiResult = service.findByImage(image.getId.getValue, []);
rois = roiResult.rois;
n = rois.size;

for thisROI  = 1:n
    roi = rois.get(thisROI-1);
    dsc = roi.getDescription();
    if ~isempty(dsc)
        numShapes = roi.sizeOfShapes; % an ROI can have multiple shapes.
        if numShapes > 0
            shape = roi.getShape(0); % first shape
            thiszct = [shape.getTheZ().getValue() shape.getTheC().getValue() shape.getTheT().getValue() ];
            if thiszct == zct
                dscr = char(dsc.getValue());
                str = [str {dscr}];
            end
        end
    end
end


if d.load_multiple_planes == 0        % normal case where 1 3D 'plane' per image
    
    % go through all the remaining images getting all the ROI descriptions
    str = unique(str);
    
    for i=2:d.n_datasets
        
        image = d.file_names{i};
        roiResult = service.findByImage(image.getId.getValue, []);
        rois = roiResult.rois;
        n = rois.size;
        
        for thisROI  = 1:n
            
            roi = rois.get(thisROI-1);
            dsc = roi.getDescription();
            if ~isempty(dsc)
                dscr = char(dsc.getValue());
                thisFOVstr = [thisFOVstr {dscr}];
            end
        end
        
        str = [ str unique(thisFOVstr) ];
        thisFOVstr = [];
        
        
    end
    
    
else     %  % special case where multiple ZC or T from one image
    
    % str contains those descrisptions that match the first FOV
    str = unique(str);
    load_multiple_planes = d.load_multiple_planes;
    
    % match all other FOVs
    
    for i=2:d.n_datasets
        
        zct(load_multiple_planes) = d.ZCT{load_multiple_planes}(i) -1;
        zct(3) = zct(3).*sizet;
        
        for thisROI  = 1:n
            roi = rois.get(thisROI-1);
            dsc = roi.getDescription();
            if ~isempty(dsc)
                numShapes = roi.sizeOfShapes; % an ROI can have multiple shapes.
                if numShapes > 0
                    shape = roi.getShape(0); % first shape
                    thiszct = [shape.getTheZ().getValue() shape.getTheC().getValue() shape.getTheT().getValue() ];
                    if thiszct == zct
                        dscr = char(dsc.getValue());
                        thisFOVstr = [thisFOVstr {dscr}];
                    end
                end
            end
        end
        str = [ str unique(thisFOVstr) ];
        thisFOVstr = [];
    end
    
    
end

if ~isempty(str)
    
    % str is a list of  the ROI decriptions that match each FOV
    t = tabulate(str);
    % return only  decriptions  that occur n_datasets times (ie match the
    % current FOV list)
    descs = str(cell2mat(t(:,2)) == d.n_datasets);
end


end

