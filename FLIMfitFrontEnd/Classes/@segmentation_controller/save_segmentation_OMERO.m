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
    session = d.omero_data_manager.session;
    userid = d.omero_data_manager.userid;
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
        
            delete_previous_ROIs = false;

            choice = questdlg('Do you want to delete all previous ROIs, or append? (..attention..)', ' ', ...
                                    'Delete previous' , ...
                                    'Append to previous','Cancel','Cancel');              
            switch choice
                case 'Delete previous',
                    delete_previous_ROIs = true;
                case 'Append to previous', 
                case 'Cancel', 
                    return;
            end                        
            
    data_time = datestr(now,'yyyy-mm-dd-T-HH-MM-SS');
    text_label = [logon_user_name filesep num2str(logon_userid) filesep num2str(userid) filesep data_time];    

    hw = waitbar(0, 'Transferring ROIs to OMERO, please wait....');
    drawnow;
        
    for i=1:length(d.file_names)
       
        L = obj.filtered_mask(:,:,i);
        
        if ~isempty(L)
    
            image = d.file_names{i};
            if (delete_previous_ROIs) delete_FOV_shapes( session,image ), end;
            
            save_segmented_labelled_FOV_as_Omero_ROI_masks( session, L, image, text_label );            
        end
     
        waitbar(i/d.n_datasets,hw);
        drawnow;
                
    end
    
    delete(hw);
    drawnow;

end