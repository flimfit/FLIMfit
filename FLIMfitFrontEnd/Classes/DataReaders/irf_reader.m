classdef irf_reader < base_data_reader
   
    properties
        data
    end
    
    methods
        
        function obj = irf_reader(filename)
            obj.filename = filename;
 
            dat = load(obj.filename);
            
            obj.delays = dat(:,1);
            obj.data = data(:,2);
            obj.FLIM_type = 'TCSPC';  
            obj.sizeZCT = [1, 1, 1];
            obj.sizeXY = [1, 1];
        end
        
        function data = read(obj, selected)
            assert(selected == 1);
            data = obj.data;
        end
        
    end
   
end