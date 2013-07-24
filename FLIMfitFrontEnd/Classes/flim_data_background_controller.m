classdef flim_data_background_controller < flim_data_series_observer
    
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
        background_subtract_checkbox;
        background_string_edit;
        background_update_button;
    end
    
    methods
        function obj = flim_data_background_controller(handles)
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
                        
            set(obj.background_subtract_checkbox,'Callback',@obj.check_callback);
            set(obj.background_update_button,'Callback',@obj.button_callback);
        end
        
        function button_callback(obj,src,evtData)
            background_string = get(obj.background_string_edit,'String');
            obj.data_series.load_background(background_string);
        end
        
        function check_callback(obj,src,evtData)
            obj.data_series.subtract_background = get(src,'Value');
        end
        
        function data_update(obj)
            set(obj.background_subtract_checkbox,'Value',obj.data_series.subtract_background);
        end
            
       
    end
    
end