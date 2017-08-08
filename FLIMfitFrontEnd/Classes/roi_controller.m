classdef roi_controller < flim_data_series_observer
    
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

       
    properties
        tool_roi_rect_toggle;
        tool_roi_poly_toggle;
        tool_roi_circle_toggle;
        
        roi_handle = [];

        point_mode = true;
        waiting = false;
        
        data_intensity_view;
        
        roi_callback_id;
        
        click_pos_txt = '';
    end
    
    properties(GetObservable = true)
        roi_mask;
    end
    
    events
        roi_updated;
    end
    
    methods
    
        function obj = roi_controller(toggles)
           
            obj = obj@flim_data_series_observer(toggles.data_series_controller);
                      
            assign_handles(obj,toggles);
            
            set(obj.tool_roi_rect_toggle,'State','off');
            set(obj.tool_roi_poly_toggle,'State','off');
            set(obj.tool_roi_circle_toggle,'State','off');
                       
            set(obj.tool_roi_rect_toggle,'OnCallback',@(evt,src) EC(@obj.on_callback,evt,src));
            set(obj.tool_roi_rect_toggle,'OffCallback',@(evt,src) EC(@obj.off_callback,evt,src));
            
            set(obj.tool_roi_poly_toggle,'OnCallback',@(evt,src) EC(@obj.on_callback,evt,src));
            set(obj.tool_roi_poly_toggle,'OffCallback',@(evt,src) EC(@obj.off_callback,evt,src));
            
            set(obj.tool_roi_circle_toggle,'OnCallback',@(evt,src) EC(@obj.on_callback,evt,src));
            set(obj.tool_roi_circle_toggle,'OffCallback',@(evt,src) EC(@obj.off_callback,evt,src));
            
            
            obj.data_intensity_view.set_click_callback(@obj.click_callback);
            
            
        end
        
        function roi_mask = get.roi_mask(obj)
            
            d = obj.data_series_controller.data_series;
            if isempty(obj.roi_mask) || size(obj.roi_mask,1) ~= d.height ...
                                    || size(obj.roi_mask,2) ~= d.width
                obj.roi_mask = [];
            end
           
            roi_mask = obj.roi_mask;
            
        end
        
        function data_update(obj)
           obj.update_mask();
           d = obj.data_series_controller.data_series;
          
           
           if d.width == 1 && d.height == 1
                obj.roi_mask = 1;
           end
           
           notify(obj,'roi_updated');
         
        end
        
        function on_callback(obj,src,~)

            if ~obj.waiting && obj.data_series.init
                
              
                obj.waiting = true;  
                obj.click_pos_txt = '';
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

                
                
                if ~isempty(obj.roi_handle)
                
                    addlistener(obj.roi_handle,'ObjectBeingDestroyed',@(~,~) EC(@obj.roi_being_destroyed));
                    obj.roi_callback_id = addNewPositionCallback(obj.roi_handle,@(~,~) EC(@obj.roi_change_callback));        
                    obj.update_mask();

                    notify(obj,'roi_updated');
                end

                obj.point_mode = true;
                
                obj.waiting = false;
                
                set(src,'State','off');
            else
                set(src,'State','off');
            end

        end
        
        function off_callback(obj,~,~)
           %set(src,'State','off');
           % if an roi is part complete then use robot framework to fire
           % esc to cancel
           if obj.waiting
               robot = java.awt.Robot;
               robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
               robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE); 
               pause(0.1);
               if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                delete(obj.roi_handle);
               end
               obj.waiting = false;
           end
        end
        
        function roi_change_callback(obj)
            obj.update_mask();
            notify(obj,'roi_updated');
        end

        function click_callback(obj,src,~)
            
            if obj.point_mode && ~isempty(obj.data_intensity_view.im)
                click_pos = get(src,'CurrentPoint');
                click_pos = click_pos(1,1:2);
                click_pos = floor(click_pos); 
                obj.click_pos_txt = ['X ' num2str(click_pos(1) - 1) '  Y ' num2str(click_pos(2) - 1) ];
                
                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end
                    
                obj.roi_handle = impoint(obj.data_intensity_view.intensity_axes,click_pos);
               
                addlistener(obj.roi_handle,'ObjectBeingDestroyed',@(~,~) EC(@obj.roi_being_destroyed));
                
                obj.update_mask();
                notify(obj,'roi_updated');
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
            
        function roi_being_destroyed(obj)
            obj.roi_handle = [];
            if ~isempty(obj.roi_callback_id)
                try
                removeNewPositionCallback(obj.roi_handle,obj.roi_callback_id);
                catch e
                end
            end
            obj.roi_callback_id = [];
        end
        
        
    end
    
    
end