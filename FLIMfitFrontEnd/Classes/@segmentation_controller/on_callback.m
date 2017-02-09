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
               obj.tool_roi_circle_toggle
               obj.tool_roi_paint_toggle];
    toggle_type = {'rect','poly','ellipse',obj.brush_width};
    toggle_fcn = {@flex_roi,@flex_roi,@flex_roi,@paint_roi};
           
    sz = size(obj.mask);
    sz = sz(1:2);
    
    if strcmp(src.State,'on')
        set(toggles(toggles ~= src),'State','off');

        toggle_fcn = toggle_fcn{toggles == src};
        obj.flex_h = toggle_fcn(obj.figure1,obj.segmentation_axes,toggle_type{toggles == src},sz,@roiCallback);
        obj.toggle_active = src;
    else
        if obj.toggle_active == src && ~isempty(obj.flex_h)
            delete(obj.flex_h)
        end
    end
    
    function roiCallback(roi_mask)
        modifier = get(gcbf,'currentmodifier');
        erase_toggle = get(obj.tool_roi_erase_toggle,'State');
        erase = strcmp(erase_toggle,'on') || ~isempty(modifier);

        obj.n_regions = obj.n_regions + 1;

        d = obj.data_series;

        if ~isempty(d.acceptor)
            roi_mask = roi_mask(1:d.height,1:d.width);
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
            obj.mask(m) = obj.n_regions;
        end

        if get(obj.replicate_mask_checkbox,'Value')
            obj.filter_masks(1:d.n_datasets);
        else
            obj.filter_masks(obj.data_series_list.selected);
        end
        
        obj.update_display();
        
        delete(obj.flex_h);
        obj.flex_h = [];

        set(src,'State','off');
    end

end