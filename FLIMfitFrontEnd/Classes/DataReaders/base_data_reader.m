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
        data_type = 'single';
        error_message;
    end
    
    methods(Abstract)
        data = read(obj, zct, channels);
    end
    
end

