function load_segmentation_OMERO(obj)

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
    ROI_descriptions_list = get_ROI_descriptions( session, d.file_names  );
    
    if isempty(ROI_descriptions_list), errordlg('there are no segmentations for these images'), return, end;
    
    if numel(ROI_descriptions_list) > 1        
        [choice,ok] = listdlg('PromptString','Please choose the ROI group',...
                        'SelectionMode','single',...
                        'ListString',ROI_descriptions_list);
        if ~ok, return, end
        segmentation_description = ROI_descriptions_list{choice};
    end
    
    str = {'Replace' 'AND' 'OR' 'NAND' 'Acceptor'};
    [choice,ok] = listdlg('PromptString','How would you like to combine the selected files with the current mask?',...
                    'SelectionMode','single',...
                    'ListString',str);    
    if ~ok, return, end
    
    new_sz = [d.height*d.width d.n_datasets];
    
    if isempty(obj.mask)
        new_mask = zeros(new_sz);
    else
        new_mask = reshape(obj.mask,new_sz);
    end
    
    h = waitbar(0,'Loading segmentation images');
        
    for i=1:length(d.file_names)

        image = d.file_names{i};
        mask = get_FOV_masks(session, image, segmentation_description);
        
        mask(mask>255)=0;
        mask = uint8(mask);

        switch choice
            case 1
                new_mask(:,i) = mask(:);
            case 2
                mask = mask == 0;
                new_mask(mask(:),i) = 0;
            case 3
                mask = mask > 0;
                new_mask(mask(:),i) = 1;
            case 4
                mask = mask > 0;
                new_mask(mask(:),i) = 0;  
            case 5
                old_mask = reshape(new_mask(:,i),[d.height d.width]);
                [z,n]=bwlabel(old_mask>0,4);
                for j=1:n
                   
                    m = (z == j);
                    acc = sum(mask(m));
                    don = sum(m(:));
                    if acc/don < 0.3
                        z(m) = 0;
                    end
                    
                end
                
                z = z > 0;
                new_mask(:,i) = z(:);
                
        end
          
        waitbar(i/d.n_datasets,h);
    end
    
    close(h);
    
    obj.mask = reshape(new_mask,[d.height d.width d.n_datasets]);
    obj.filtered_mask = obj.mask;
    
    obj.update_display();    

end