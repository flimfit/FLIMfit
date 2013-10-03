function remove_all_segmentations_OMERO(obj)

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

    disp('remove_all_segmentations_OMERO');
    
    d = obj.data_series_controller.data_series;
    session = d.omero_data_manager.session;
    
    if ~isa(d,'OMERO_data_series')
        errordlg('images are not originated from OMERO, cannot continue..'), return, 
    end;

    size_filt_mask = size(obj.filtered_mask);
    if isempty(size_filt_mask) || ... 
            ( numel(size_filt_mask) == 2 && size_filt_mask(1) == 0 && size_filt_mask(2) == 0 )
        errordlg('nothnig was segmented? cannot continue..'), return, 
    end;
    
    hw = waitbar(0, 'Deleting segmentations, please wait....');
    drawnow;
        
    for i=1:d.n_datasets       
        myimages = getImages(session,d.image_ids(i));             
        delete_FOV_shapes( d.omero_data_manager.session,myimages(1) );     
        %
        waitbar(i/d.n_datasets,hw);
        drawnow;                
    end
    
    delete(hw);
    drawnow;
    
end