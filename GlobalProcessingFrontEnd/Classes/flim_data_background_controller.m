classdef flim_data_background_controller < flim_data_series_observer
   
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