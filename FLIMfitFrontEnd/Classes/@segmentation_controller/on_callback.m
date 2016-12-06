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

    mouse_down = false;

    if src == obj.tool_roi_paint_toggle
        
        set(obj.tool_roi_poly_toggle,'State','off');
        set(obj.tool_roi_rect_toggle,'State','off');
        set(obj.tool_roi_circle_toggle,'State','off');

        if (obj.paint_active)
            endPaint();
        end
        
        obj.paint_active = strcmp(get(obj.tool_roi_paint_toggle,'State'),'on');
        obj.waiting = false;

        mask_size = size(obj.mask);
        
        [X,Y] = meshgrid(1:mask_size(2),1:mask_size(1));
        last_pos = [];
        
        if obj.paint_active
            fh = obj.figure1;
            set(fh, 'WindowButtonMotionFcn', @mouseMove);
            set(fh, 'WindowButtonDownFcn', @mouseDown);
            set(fh, 'WindowButtonUpFcn', @mouseUp);
            obj.paint_mask = zeros(mask_size(1:2));
        end
        
    else
    
    
        if ~obj.waiting

            if obj.paint_active
                endPaint();
            end
            
            obj.waiting = true;

            complete_roi = true;

            switch src
                case obj.tool_roi_rect_toggle

                    set(obj.tool_roi_poly_toggle,'State','off');
                    set(obj.tool_roi_circle_toggle,'State','off');
                    set(obj.tool_roi_paint_toggle,'State','off');


                    try
                        roi_handle = imrect(obj.segmentation_axes);
                    catch
                        complete_roi = false;
                    end

                case obj.tool_roi_poly_toggle

                    set(obj.tool_roi_rect_toggle,'State','off');
                    set(obj.tool_roi_circle_toggle,'State','off');
                    set(obj.tool_roi_paint_toggle,'State','off');

                    try
                        roi_handle = impoly(obj.segmentation_axes);
                    catch
                        complete_roi = false;
                    end

                case obj.tool_roi_circle_toggle

                    set(obj.tool_roi_poly_toggle,'State','off');
                    set(obj.tool_roi_rect_toggle,'State','off');
                    set(obj.tool_roi_paint_toggle,'State','off');

                    try
                        roi_handle = imellipse(obj.segmentation_axes);
                    catch
                        complete_roi = false;
                    end
            end

            if complete_roi
                modifier = get(gcbf,'currentmodifier');
                erase_toggle = get(obj.tool_roi_erase_toggle,'State');
                erase = strcmp(erase_toggle,'on') || ~isempty(modifier);
                roi_mask = roi_handle.createMask(obj.segmentation_im);

                addRegion(roi_mask, erase);
                delete(roi_handle);
            end

            set(src,'State','off');
            obj.waiting = false;
        else
            set(src,'State','off');
        end
    end
    
    function mouseDown(~,~)
        mouse_down = true;
        set(obj.figure1, 'Pointer','crosshair');
        last_pos = [];
    end

    function mouseUp(~,~)
        mouse_down = false;
        set(obj.figure1, 'Pointer','arrow');
        
        erase = ~isempty(get(gcbf,'currentmodifier')) | strcmp(get(obj.tool_roi_erase_toggle,'State'),'on');
        
        addRegion(obj.paint_mask, erase);
        obj.paint_mask(:) = 0;
    end

    function mouseMove(~,~)
        
        if mouse_down
            
            r = obj.brush_width;

            axh = obj.segmentation_axes;
            C = get(axh, 'CurrentPoint');
            pos = [C(1,1), mod(C(1,2), size(obj.paint_mask,1)) + 1];

            all_pos = pos;
            if ~isempty(last_pos)
                distance = norm(last_pos-pos);
                n = ceil(distance / r) * 2;
                
                all_pos = [linspace(last_pos(1),pos(1),n)' linspace(last_pos(2),pos(2),n)'];
                end
                
            last_pos = pos;
            
            for i=1:size(all_pos,1)
                sel = (Y-all_pos(i,2)).^2 + (X-all_pos(i,1)).^2 < r^2;
                obj.paint_mask(sel) = 1;
            end
            
            set(obj.paint_im,'AlphaData', obj.paint_mask * 1.0);
            
            %displayMask();
        end
    end

    function endPaint()
        if obj.paint_active
           addRegion(obj.paint_mask, false);
        end
        
        
        obj.paint_active = false;
        
        fh = obj.figure1;
        set(fh, 'WindowButtonMotionFcn', []);
        set(fh, 'WindowButtonDownFcn', []);
        set(fh, 'WindowButtonUpFcn', []);
    end

    function addRegion(roi_mask, erase)
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
            %obj.filtered_mask(m) = 0;
        else
            obj.mask(m) = obj.n_regions;
            %obj.filtered_mask(m) = obj.n_regions;
        end

        if get(obj.replicate_mask_checkbox,'Value')
            obj.filter_masks(1:d.n_datasets);
        else
            obj.filter_masks(obj.data_series_list.selected);
        end
        
        
        obj.update_display();
    end

end