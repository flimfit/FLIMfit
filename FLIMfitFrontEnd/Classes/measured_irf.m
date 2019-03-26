classdef measured_irf
   
    properties
        t;
        irf;
    end
    
    methods
        
        function obj = measured_irf(t,irf)
            obj.t = t;
            obj.irf = irf;
        end
       
        function ch_irf = get_channels(obj,ch)
            ch_irf = measured_irf(obj.t,obj.irf(:,ch));
        end
        
    end
    
end