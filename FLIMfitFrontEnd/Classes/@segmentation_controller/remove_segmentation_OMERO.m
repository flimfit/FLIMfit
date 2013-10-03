function remove_segmentation_OMERO(obj)

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

 d = obj.data_series_controller.data_series;    
    
    if ~isa(d,'OMERO_data_series')
        errordlg('images are not originated from OMERO, cannot continue..'), return, 
    end;
    
    session = d.omero_data_manager.session;    
    
    segmentation_description = [];    
    ROI_descriptions_list = get_ROI_descriptions( session, d.image_ids  );
    
    if isempty(ROI_descriptions_list), errordlg('there are no segmentations for these images'), return, end;
    
    if numel(ROI_descriptions_list) > 1        
        [choice,ok] = listdlg('PromptString','Please choose the ROI group',...
                        'SelectionMode','single',...
                        'ListString',ROI_descriptions_list);
        if ~ok, return, end
        segmentation_description = ROI_descriptions_list{choice};        
        if isempty(segmentation_description), return, end; %?
    end
    %
    
    iUpdate = session.getUpdateService();
    service = session.getRoiService();

    hw = waitbar(0, ['Deleting segmentation "' segmentation_description '", please wait....']);
    drawnow;
        
    for i=1:d.n_datasets
       
            myimages = getImages(session,d.image_ids(i));             
            image = myimages(1);

            roiResult = service.findByImage(image.getId.getValue, []);
            rois = roiResult.rois;
            n = rois.size;
            for thisROI  = 1:n
                roi = rois.get(thisROI-1);
                numShapes = roi.sizeOfShapes; % an ROI can have multiple shapes.
                for ns = 1:numShapes
                    shape = roi.getShape(ns-1); % the shape
                    % remove the shape
                    if  strcmp(char(roi.getDescription().getValue()),segmentation_description)
                        roi.removeShape(shape);
                    end;
                end
                %Update the roi.
                roi = iUpdate.saveAndReturnObject(roi);
            end    
        %
        waitbar(i/d.n_datasets,hw);
        drawnow;
        %
    end        
    %
    delete(hw);
    drawnow;   
    %    
end