classdef roi_controller < flim_data_series_observer
       
    properties
        tool_roi_rect_toggle;
        tool_roi_poly_toggle;
        tool_roi_circle_toggle;
        
        roi_handle = [];

        point_mode = true;
        waiting = false;
        
        data_intensity_view;
        
        roi_callback_id;
    end
    
    properties(SetObservable = true)
        roi_mask;
    end
    
    methods
    
        function obj = roi_controller(toggles)
           
            obj = obj@flim_data_series_observer(toggles.data_series_controller);
                      
            assign_handles(obj,toggles);
            
            set(obj.tool_roi_rect_toggle,'State','off');
            set(obj.tool_roi_poly_toggle,'State','off');
            set(obj.tool_roi_circle_toggle,'State','off');
                       
            set(obj.tool_roi_rect_toggle,'OnCallback',@obj.on_callback);
            set(obj.tool_roi_rect_toggle,'OffCallback',@obj.off_callback);
            
            set(obj.tool_roi_poly_toggle,'OnCallback',@obj.on_callback);
            set(obj.tool_roi_poly_toggle,'OffCallback',@obj.off_callback);
            
            set(obj.tool_roi_circle_toggle,'OnCallback',@obj.on_callback);
            set(obj.tool_roi_circle_toggle,'OffCallback',@obj.off_callback);
            
            
            obj.data_intensity_view.set_click_callback(@obj.click_callback);
            
            
        end
        
        function data_update(obj)
           obj.update_mask();
           d = obj.data_series_controller.data_series;
           if d.width == 1 && d.height == 1
                obj.roi_mask = 1;
           end
           
           %if obj.roi_handle == []
           %     obj.roi_handle = impoint(obj.data_intensity_view.ax,0,0);
           %     addNewPositionCallback(obj.roi_handle,@obj.roi_change_callback);                    
           %     obj.update_mask();
           %end
        end
        
        function on_callback(obj,src,evtData)

            if ~obj.waiting && obj.data_series.init
                
                obj.waiting = true;
           
                obj.point_mode = false;

                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end

                switch src
                    case obj.tool_roi_rect_toggle

                        set(obj.tool_roi_poly_toggle,'State','off');
                        set(obj.tool_roi_circle_toggle,'State','off');

                        obj.roi_handle = imrect(obj.data_intensity_view.intensity_axes);

                    case obj.tool_roi_poly_toggle

                        set(obj.tool_roi_rect_toggle,'State','off');
                        set(obj.tool_roi_circle_toggle,'State','off');

                        obj.roi_handle = impoly(obj.data_intensity_view.intensity_axes);

                    case obj.tool_roi_circle_toggle

                        set(obj.tool_roi_poly_toggle,'State','off');
                        set(obj.tool_roi_rect_toggle,'State','off');

                        obj.roi_handle = imellipse(obj.data_intensity_view.intensity_axes);


                end

                addlistener(obj.roi_handle,'ObjectBeingDestroyed',@obj.roi_being_destroyed);
                obj.roi_callback_id = addNewPositionCallback(obj.roi_handle,@obj.roi_change_callback);        
                
                obj.update_mask();

                obj.point_mode = true;
                
                obj.waiting = false;
                
                set(src,'State','off');
            else
                set(src,'State','off');
            end

        end
        
        function off_callback(obj,src,evtData)
           %set(src,'State','off');
           if obj.waiting
               delete(obj.roi_handle);
               obj.waiting = false;
           end
        end
        
        function roi_change_callback(obj,src,evt)
            obj.update_mask();
        end

        function click_callback(obj,src,evtData)
            
            if obj.point_mode && ~isempty(obj.data_intensity_view.im)
                click_pos = get(src,'CurrentPoint');
                click_pos = click_pos(1,1:2);
                click_pos = floor(click_pos); 
                
                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end
                    
                obj.roi_handle = impoint(obj.data_intensity_view.intensity_axes,click_pos);
                
                addlistener(obj.roi_handle,'ObjectBeingDestroyed',@obj.roi_being_destroyed);
                
                obj.update_mask();
            end
        end
        
        function update_mask(obj)
            if ~isempty(obj.roi_handle)
                try
                obj.roi_mask = obj.roi_handle.createMask(obj.data_intensity_view.im);
                catch %#ok
                end
            end
        end
            
        function roi_being_destroyed(obj,~,~)
            obj.roi_handle = [];
            if ~isempty(obj.roi_callback_id);
                try
                removeNewPositionCallback(obj.roi_handle,obj.roi_callback_id);
                catch e
                end
            end
            obj.roi_callback_id = [];
        end
        
        
    end
    
    
end