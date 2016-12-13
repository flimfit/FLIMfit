classdef (Abstract) base_data_reader < handle
    
    properties
        filename;
        
        settings;
        
        chan_info;
        delays;
        t_int;
        
    	FLIM_type;
        sizeZCT;
        sizeXY;
        error_message;
    end
    
    methods(Abstract)
        data = read(obj, selected);
    end
    
end

