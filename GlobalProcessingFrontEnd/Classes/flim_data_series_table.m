classdef flim_data_series_table < handle & flim_data_series_observer
   
    properties
        data_series_uitable;
    end
    
    methods
    
        function obj = flim_data_series_table(handles)
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
            
            obj.data_update();
        end
                        
        function data_update(obj)
            
            if obj.data_series.init
                list_data = cell(obj.data_series.n_datasets,2);

                list_data(:,1) = obj.data_series.names;
                %list_data(:,2) = num2cell(logical(obj.data_series.background_loaded));

                set(obj.data_series_uitable,'Data',list_data);
            end
            
        end
        
    end
end