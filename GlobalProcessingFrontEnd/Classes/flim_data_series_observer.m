classdef flim_data_series_observer < handle
   
    properties
        data_series;
        data_series_controller;
        ds_lh = {};
    end
    
    methods
        function obj = flim_data_series_observer(data_series_controller)
           obj.data_series_controller = data_series_controller; 
           
           if ~isempty(data_series_controller)
               addlistener(data_series_controller,'data_series','PostSet',@obj.update_data_series);
               obj.data_series = data_series_controller.data_series;
           end
        end
        
        function update_data_series(obj,src,evtData)
            obj.data_series = evtData.AffectedObject.data_series;          
        end
        
        function set.data_series(obj, data_series)
            obj.data_series = data_series; 
            obj.ds_lh{end+1} = addlistener(obj.data_series,'data_updated',@obj.data_update_evt);
                obj.data_set();
            if obj.data_series.init
                obj.data_update();
            end
        end
        
        function data_update_evt(obj,src,evtData)
            if ~ishandle(obj.data_series) && obj.data_series.init
                obj.data_update();
            end
        end
        
        function data_set(obj) 
        end
        
        function delete(obj)

            for i=1:length(obj.ds_lh)
                if ishandle(obj.ds_lh{i})
                   delete(obj.ds_lh{i});
                end
            end
            obj.ds_lh = {};
        end
        
    end
    
    methods(Abstract = true)
        data_update(obj);
    end
end