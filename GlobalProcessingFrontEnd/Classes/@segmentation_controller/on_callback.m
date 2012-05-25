function on_callback(obj,src,evtData)

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

            modifier = get(gcbf,'currentmodifier');
            erase_toggle = get(obj.tool_roi_erase_toggle,'State');
            
            roi_mask = roi_handle.createMask(obj.segmentation_im);

            d = obj.data_series;
            if get(obj.replicate_mask_checkbox,'Value')
                m = repmat(roi_mask,[1 1 d.n_datasets]);
            else
                m = false([d.height d.width d.n_datasets]);
                m(:,:,obj.data_series_list.selected) = roi_mask;
            end

            if strcmp(erase_toggle,'on') || ~isempty(modifier)
                obj.mask(m) = 0;
            else
                obj.mask(m) = obj.n_regions;
            end
                
            delete(roi_handle);

            obj.update_display();
        end
        
        set(src,'State','off');
        obj.waiting = false;
    else
        set(src,'State','off');
    end

end