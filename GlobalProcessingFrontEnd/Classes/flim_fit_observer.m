classdef flim_fit_observer < handle
   
    properties
        fit_controller;
        flim_fit_lh;
    end
    
    methods
        function obj = flim_fit_observer(fit_controller)
           obj.fit_controller = fit_controller; 
           
           obj.flim_fit_lh = addlistener(fit_controller,'fit_updated',@obj.fit_update_evt);
           obj.flim_fit_lh = addlistener(fit_controller,'fit_display_updated',@obj.fit_display_update_evt);
        end
        
        
        function fit_update_evt(obj,src,evtData)
            if isvalid(obj)
                obj.fit_update();
            end
        end

        function fit_display_update_evt(obj,src,evtData)
            if isvalid(obj)
                obj.fit_display_update();
            end
        end

        function fit_display_update(obj)
        end
        
    end
    
    methods(Abstract = true)
        fit_update(obj);
    end
end