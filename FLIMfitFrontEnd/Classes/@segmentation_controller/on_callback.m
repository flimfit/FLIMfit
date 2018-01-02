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
    

    toggles = [obj.tool_roi_rect_toggle 
               obj.tool_roi_poly_toggle
               obj.tool_roi_freehand_toggle
               obj.tool_roi_circle_toggle
               obj.tool_roi_paint_toggle];
    toggle_type = {'rect','poly','freehand','ellipse',obj.brush_width};
    toggle_fcn = {@flex_roi,@flex_roi,@flex_roi,@flex_roi,@paint_roi};
           
    sz = size(obj.mask);
    sz = sz(1:2);
    
    if ~isempty(obj.data_series.acceptor)
        sz(2) = sz(2) * 2;
    end
    
    toggle_type = toggle_type{toggles == src};
    toggle_fcn = toggle_fcn{toggles == src};
    
    if ~isempty(obj.flex_h)
        delete(obj.flex_h)
    end
    
    if strcmp(src.State,'on')
        set(toggles(toggles ~= src),'State','off');
        obj.flex_h = toggle_fcn(obj.figure1,obj.segmentation_axes,toggle_type,sz,@roiCallback);
        obj.toggle_active = src;
    end
    
    function roiCallback(roi_mask,first_pos)
        modifier = get(gcbf,'currentmodifier');
        erase_toggle = get(obj.tool_roi_erase_toggle,'State');
        erase = strcmp(erase_toggle,'on') || ~isempty(modifier);

        d = obj.data_series;
        obj.n_regions = obj.n_regions + 1;

        % if we're painting and started on an area, continue that region
        new_area = obj.n_regions;
        if isnumeric(toggle_type) % paint
            first_pos = round(first_pos);
            
            if all(first_pos > 0) & all(first_pos <= [d.height d.width]) 
                old = obj.mask(first_pos(2),first_pos(1),obj.data_series_list.selected);
                if old > 0
                    new_area = old;
                end
            end
        end
        

        if ~isempty(d.acceptor)
            roi_mask = roi_mask(1:d.height,1:d.width) + roi_mask(1:d.height,(1:d.width) + d.width);
        end

        if get(obj.replicate_mask_checkbox,'Value')
            m = repmat(roi_mask,[1 1 d.n_datasets]);
        else
            m = false([d.height d.width d.n_datasets]);
            m(:,:,obj.data_series_list.selected) = roi_mask;
        end

        if erase
            obj.mask(m) = 0;
        else
            obj.mask(m) = new_area;
        end

        if get(obj.replicate_mask_checkbox,'Value')
            obj.filter_masks(1:d.n_datasets);
        else
            obj.filter_masks(obj.data_series_list.selected);
        end
        
        obj.update_display();
        
        delete(obj.flex_h);
        obj.flex_h = [];

        obj.on_callback(src); % repeat segmentation
    end

end