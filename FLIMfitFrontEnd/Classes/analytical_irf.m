classdef analytical_irf
    
    properties
        gaussian_parameters {mustBeGaussianParams(gaussian_parameters)} = struct('mu',{},'sigma',{},'offset',{});
        t
        irf
    end
    
    methods
        
        function obj = analytical_irf(gaussian_parameters)
            obj.gaussian_parameters = gaussian_parameters;
            
            mu = [obj.gaussian_parameters.mu];
            sigma = [obj.gaussian_parameters.sigma];
            min_t = 0;
            max_t = round(max(mu+6*sigma));
            obj.t = (min_t:1:max_t)';
            
            obj.irf = zeros(length(obj.t),length(mu));
            for i=1:length(mu)
                obj.irf(:,i) = normpdf(obj.t,mu(i),sigma(i));
            end
        end
        
        function irf = get_channel(obj, ch)
            irf = analytical_irf(obj.gaussian_parameters(ch));
        end
        
    end
end

 
function mustBeGaussianParams(p)
    if ~isstruct(p) || ~isfield(p,'mu') || ~isfield(p,'sigma')
        error('Gaussian parameters struct must have field mu and sigma')
    end
end
