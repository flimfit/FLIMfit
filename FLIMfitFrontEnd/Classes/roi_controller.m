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
            
            set(obj.tool_roi_rect_toggle,'Value',false);
            set(obj.tool_roi_poly_toggle,'Value',false);
            set(obj.tool_roi_circle_toggle,'Value',false);
                       
            set(obj.tool_roi_rect_toggle,'ValueChangedFcn',@(evt,src) EC(@obj.callback,evt,src));
            set(obj.tool_roi_poly_toggle,'ValueChangedFcn',@(evt,src) EC(@obj.callback,evt,src));
            set(obj.tool_roi_circle_toggle,'ValueChangedFcn',@(evt,src) EC(@obj.callback,evt,src));
            
            
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
        
        function callback(obj,src,evt)
            if evt.Value == 1
                obj.on_callback(src,evt);
            else
                obj.off_callback(src,evt);
            end
        end
        
        function on_callback(obj,src,evt)

            if ~obj.waiting && obj.data_series.init
                
              
                obj.waiting = true;  
                obj.click_pos_txt = '';
                obj.point_mode = false;
                
                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end
              
                other_tools = [obj.tool_roi_rect_toggle,obj.tool_roi_poly_toggle, obj.tool_roi_circle_toggle];
                other_tools = other_tools(other_tools ~= src);
                set(other_tools,'Value',false);
                
                switch src
                    case obj.tool_roi_rect_toggle
                        obj.roi_handle = drawrectangle(obj.data_intensity_view.intensity_axes);
                    case obj.tool_roi_poly_toggle
                        obj.roi_handle = drawpolygon(obj.data_intensity_view.intensity_axes);
                    case obj.tool_roi_circle_toggle
                        obj.roi_handle = drawellipse(obj.data_intensity_view.intensity_axes);
                end
                
                if ~isempty(obj.roi_handle)
                    addlistener(obj.roi_handle,'ObjectBeingDestroyed',@(~,~) EC(@obj.roi_being_destroyed));
                    obj.roi_callback_id = addlistener(obj.roi_handle,'ROIMoved',@(~,~) EC(@obj.roi_change_callback));        
                    obj.update_mask();

                    notify(obj,'roi_updated');
                end

                obj.point_mode = true;
                obj.waiting = false;
                
                set(src,'Value',false);
            else
                set(src,'Value',false);
            end

        end
        
        function off_callback(obj,~,~)
           %set(src,'Value','off');
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

        function click_callback(obj,src,evt)
            
            if obj.point_mode && ~isempty(obj.data_intensity_view.im)
                click_pos = evt.IntersectionPoint(1:2);
                click_pos = floor(click_pos); 
                obj.click_pos_txt = ['X ' num2str(click_pos(1) - 1) '  Y ' num2str(click_pos(2) - 1) ];
                
                if ~isempty(obj.roi_handle) && isvalid(obj.roi_handle)
                    delete(obj.roi_handle);
                end
                                    
                obj.roi_handle = drawpoint(obj.data_intensity_view.intensity_axes,'Position',click_pos);
               
                addlistener(obj.roi_handle,'ObjectBeingDestroyed',@(~,~) EC(@obj.roi_being_destroyed));
                
                obj.update_mask();
                notify(obj,'roi_updated');
            end
        end
        
        function update_mask(obj)
            if ~isempty(obj.roi_handle)
                if isa(obj.roi_handle,'images.roi.Point')
                    obj.roi_mask = false([obj.data_series.height obj.data_series.width]);
                    obj.roi_mask(obj.roi_handle.Position(2),obj.roi_handle.Position(1)) = true;
                else
                    obj.roi_mask = createMask(obj.roi_handle,obj.data_intensity_view.im);
                end
            end
        end
            
        function roi_being_destroyed(obj)
            obj.roi_handle = [];
            if ~isempty(obj.roi_callback_id)
                delete(obj.roi_callback_id);
            end
            obj.roi_callback_id = [];
        end
        
        
    end
    
    
end