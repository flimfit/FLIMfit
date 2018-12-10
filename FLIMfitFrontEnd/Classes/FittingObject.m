classdef FittingObject
   
    properties
        fitted_names;
        params;
    end
    
    methods
        
        function obj = FittingObject(params, fitted_names)
            has_field = cellfun(@(x) isfield(params,x), fitted_names);
            assert(all(has_field));
            
            obj.params = params;
            obj.fitted_names = fitted_names;
        end
        
        function x = get_initial(obj)
            x = [];
            for i=1:length(obj.fitted_names)
                x = [x; obj.params.(obj.fitted_names{i})(:)];
            end
        end
        
        function params = get(obj,x)
            params = obj.params;
            idx = 1;
            for i=1:length(obj.fitted_names)
                name = obj.fitted_names{i};
                n = numel(params.(name));
                p = x(idx:(idx+n-1));
                p = reshape(p,size(params.(name)));
                params.(name) = p;
                idx = idx + n;
            end
        end
        
    end
end