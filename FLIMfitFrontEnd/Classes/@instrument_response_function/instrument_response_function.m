classdef instrument_response_function < handle
    
    properties
        t_irf (:,1) double = [-1; 0; 1];
        irf double = [0; 1; 0];
        irf_name char;
        t0_image double;
        polarisation_resolved (1,1) logical = false; 
        n_chan (1,1) double = 1;
        data_t_min (1,1) double = 0; % first data point
        
        is_analytical (1,1) logical = false;
        gaussian_parameters {mustBeGaussianParams(gaussian_parameters)} = struct('mu',{},'sigma',{},'offset',{});
    end
    
    properties(SetObservable)
        t_irf_min (1,1) double = 0;
        t_irf_max (1,1) double = 0;

        irf_type = 0;
        irf_background (1,:) double = 0;
        afterpulsing_correction (1,1) logical = false;
        ref_lifetime (1,1) double = 80;
        
        g_factor (1,:) double = 1;
        pol_angle (1,1) double = 0;
        
        t0 (1,1) double = 0;
    end
        
    properties(Transient)
        has_image_irf = 0;
        image_irf;
        perp_shift = 0;
    end
    
    events
        updated;
    end
    
    methods
        function obj = instrument_response_function()
        end
        
        function init(obj)
            obj.t_irf_min = min(obj.t_irf);
            obj.t_irf_max = max(obj.t_irf);
            
            notify(obj,'updated');
        end
            
        
        function set.t_irf_max(obj,t_irf_max)
            obj.t_irf_max = t_irf_max;
            notify(obj,'updated');
        end
        
        function set.t_irf_min(obj,t_irf_min)
            obj.t_irf_min = t_irf_min;
            notify(obj,'updated');
        end      
        
        function set.irf_background(obj,irf_background)
            obj.irf_background = irf_background;
            notify(obj,'updated');
        end
        
        function set.ref_lifetime(obj,ref_lifetime)
            obj.ref_lifetime = ref_lifetime;
            notify(obj,'updated');
        end
        
        function set.irf_type(obj,irf_type)
            obj.irf_type = irf_type;
            notify(obj,'updated');
        end
        
        function set.g_factor(obj,g_factor)
            obj.g_factor = g_factor;
            notify(obj,'updated');
        end
        
        function set.t0(obj,t0)
            obj.t0 = t0;
            notify(obj,'updated');
        end
        
    end
end

 
function mustBeGaussianParams(p)
    if ~isstruct(p) || ~isfield(p,'mu') || ~isfield(p,'sigma')
        error('Gaussian parameters struct must have field mu and sigma')
    end
end

