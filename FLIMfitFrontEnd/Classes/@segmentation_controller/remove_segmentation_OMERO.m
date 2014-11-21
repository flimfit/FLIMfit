function remove_segmentation_OMERO(obj, delete_all )



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
    
    if nargin < 2 
        delete_all = false;
    end
        

    d = obj.data_series_controller.data_series;    
    
    if ~isa(d,'OMERO_data_series')
        errordlg('images are not originated from OMERO, cannot continue..'), return, 
    end;
    
    session = d.omero_data_manager.session;    
    
    segmentation_description = [];    
   
    
    choice = 1;
    
    iUpdate = session.getUpdateService();
    service = session.getRoiService();
    
    if delete_all
        prompt = {sprintf(['This will delete ALL ROIs attached to the selected images! \n' ...
            'This may render segmentations for overlapping sets of images unuseable! \n' ...
            'If in doubt please remove segmentations one by one. ' ' Continue?'])};
        button = questdlg(prompt, 'Delete ALL ROIs? - Use with care!','Yes','No','No');
        if ~strcmp(button,'Yes')
            return;
        end
           
        hw = waitbar(0, [' Deleting all  please wait.... ']);
    else
         ROI_descriptions_list = get_ROI_descriptions( session, d );
    
        if isempty(ROI_descriptions_list), errordlg('there are no segmentations for these images'), return, end;
        
        if numel(ROI_descriptions_list) > 0        
            [choice,ok] = listdlg('PromptString','Please choose the ROI group',...
                        'SelectionMode','single',...
                        'ListString',ROI_descriptions_list);
            if ~ok, return, end
            segmentation_description = ROI_descriptions_list{choice};       
        end
        hw = waitbar(0, [' Deleting segmentation  ' segmentation_description ' please wait.... ']);
    end
        
    drawnow;
    nfiles = length(d.file_names);
    
      
    for i=1:nfiles
        
        image = d.file_names{i};
        
        roiResult = service.findByImage(image.getId.getValue, []);
        rois = roiResult.rois;
        n = rois.size;
        for thisROI  = 1:n
            roi = rois.get(thisROI-1);
            numShapes = roi.sizeOfShapes; % an ROI can have multiple shapes.
            for ns = 1:numShapes
                shape = roi.getShape(ns-1); % the shape
                % remove the shape
                if delete_all || strcmp(char(roi.getDescription().getValue()),segmentation_description)
                    roi.removeShape(shape);
                end;
            end
            %Update the roi.
            roi = iUpdate.saveAndReturnObject(roi);
        end
        
        waitbar(i/nfiles,hw);
        drawnow;
    end
            
  
    delete(hw);
    drawnow;   
       
end