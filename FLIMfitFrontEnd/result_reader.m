classdef result_reader < handle
   
    properties
        filename
        n_image
    end
    
    methods
       
        function obj = result_reader(filename)
           obj.filename = filename; 
           info = h5info(filename,'/results');
           obj.n_image = numel(info.Groups);
        end
                
        function im = get_param(obj,image, param_name)
            im = h5read(obj.filename,['/results/image ' num2str(image) '/' param_name]);
        end
        
        function stats = get_stats(obj,stat_name)
            stats = h5read(obj.filename,['/stats/' stat_name]);
        end
        
        function metadata = get_metadata(obj)
            metadata = h5read(obj.filename,'/metadata');
        end
        
    end
    
end
