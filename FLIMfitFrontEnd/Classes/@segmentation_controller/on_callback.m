function on_callback(obj,src,evtData)

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


    if ~obj.waiting

        obj.waiting = true;

        failed = false;
        
        switch src
            case obj.tool_roi_rect_toggle

                set(obj.tool_roi_poly_toggle,'State','off');
                set(obj.tool_roi_circle_toggle,'State','off');

                try
                    roi_handle = imrect(obj.segmentation_axes);
                catch
                    failed = true;
                end
                
            case obj.tool_roi_poly_toggle

                set(obj.tool_roi_rect_toggle,'State','off');
                set(obj.tool_roi_circle_toggle,'State','off');
                
                try
                    roi_handle = impoly(obj.segmentation_axes);
                catch
                    failed = true;
                end

            case obj.tool_roi_circle_toggle

                set(obj.tool_roi_poly_toggle,'State','off');
                set(obj.tool_roi_rect_toggle,'State','off');

                try
                    roi_handle = imellipse(obj.segmentation_axes);
                catch
                    failed = true;
                end
        end

        if ~failed
            obj.n_regions = obj.n_regions + 1;

            d = obj.data_series;
            
            modifier = get(gcbf,'currentmodifier');
            erase_toggle = get(obj.tool_roi_erase_toggle,'State');
            
            roi_mask = roi_handle.createMask(obj.segmentation_im);
            
            if ~isempty(d.acceptor)
                roi_mask = roi_mask(1:d.height,1:d.width);
            end

            
            if get(obj.replicate_mask_checkbox,'Value')
                m = repmat(roi_mask,[1 1 d.n_datasets]);
            else
                m = false([d.height d.width d.n_datasets]);
                m(:,:,obj.data_series_list.selected) = roi_mask;
            end

            if strcmp(erase_toggle,'on') || ~isempty(modifier)
                obj.mask(m) = 0;
                %obj.filtered_mask(m) = 0;
            else
                obj.mask(m) = obj.n_regions;
                %obj.filtered_mask(m) = obj.n_regions;
            end
                
            delete(roi_handle);
            if get(obj.replicate_mask_checkbox,'Value')
                obj.filter_masks(1:d.n_datasets);
            else
                obj.filter_masks(obj.data_series_list.selected);
            end
            obj.update_display();
        end
        
        set(src,'State','off');
        obj.waiting = false;
    else
        set(src,'State','off');
    end

end