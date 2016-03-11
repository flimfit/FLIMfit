function save_segmentation_OMERO(obj)

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
    session = d.omero_logon_manager.session;
    userid = d.omero_logon_manager.userid;
    logon_userid = session.getAdminService().getEventContext().userId;
    logon_user_name = char(session.getAdminService().getEventContext().userName);
    
    if ~isa(d,'OMERO_data_series')
        errordlg('images are not originated from OMERO, cannot continue..'), return, 
    end;

    size_filt_mask = size(obj.filtered_mask);
    if isempty(size_filt_mask) || ... 
            ( numel(size_filt_mask) == 2 && size_filt_mask(1) == 0 && size_filt_mask(2) == 0 )
        errordlg('nothing was segmented? cannot continue..'), return, 
    end;
        
    
    if ~d.file_names{1}.getDetails().getPermissions().canAnnotate()
        errordlg('No permission to Annotate images!');
        return;
    end
        
           
            
    data_time = datestr(now,'yyyy-mm-dd-T-HH-MM-SS');
    text_label = [logon_user_name filesep num2str(logon_userid) filesep num2str(userid) filesep data_time];    

    hw = waitbar(0, 'Appending ROIs to OMERO, please wait....');
    drawnow;
    
    sizet = d.n_t;
    zct = [d.ZCT{1}(1)-1 d.ZCT{2}(1)-1 d.ZCT{3}(1)-1];
    zct(3) = zct(3).*sizet; % first time-bin in the real-time point
    
    if d.load_multiple_planes ~= 0     % special case where multiple 3d FOVs are loaded as datasets from a single image
        load_multiple_planes = d.load_multiple_planes;
        image = d.file_names{1};
        for i=1:d.n_datasets
            L = obj.filtered_mask(:,:,i);
            if ~isempty(L)
                zct(load_multiple_planes) = d.ZCT{load_multiple_planes}(i) -1;
                zct(3) = zct(3).*sizet;
                save_segmented_labelled_FOV_as_Omero_ROI_masks( session, L, image, text_label, zct );   
            end
            waitbar(i/d.n_datasets,hw);
            drawnow;
        end
               
    else        % normal mode where 1 3d FOV is loaded per image
        
        for i=1:d.n_datasets
            
            L = obj.filtered_mask(:,:,i);
            if ~isempty(L)
                image = d.file_names{i};
                save_segmented_labelled_FOV_as_Omero_ROI_masks( session, L, image, text_label, zct );   
            end
            waitbar(i/d.n_datasets,hw);
            drawnow;
        end            
    end
    
    delete(hw);
    drawnow;

end