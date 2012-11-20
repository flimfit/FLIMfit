classdef flim_fitting_params < handle
   
    properties(SetObservable)
        n_exp = 1;
        n_fix = 0;
        
        data_type = 0;
        global_fitting = 0;
        global_variable = 0;
        global_algorithm = 1;
        fit_t0 = false;
        fit_offset = 0;
        fit_scatter = 0;
        fit_beta = 1;
        fit_tvb = 0;
        
        t0 = 0;
        offset = 0;
        scatter = 0;
        tvb = 0;
       
        
        pulsetrain_correction = true;
        fit_reference = false;
        
        fitting_algorithm = 0;
        
        tau_guess = [2000];
        
        tau_min = [0];
        tau_max = [100000];
        
        use_phase_plane_estimation = false;
        auto_estimate_tau = true;
        
        fixed_beta = false;
        global_beta_group = [0];

        n_fret = 0;
        n_fret_fix = 0;
        inc_donor = 0;
        fret_guess = [];
        
        polarisation_resolved = false;
        
        n_theta = 2;
        n_theta_fix = 0;
        inc_rinf = 0;
        
        theta_guess = [15000 1000];
        
        calculate_errs = false;
        split_fit = false;
        use_memory_mapping = false;
        
        use_autosampling = true;
        
        image_irf_mode = 0;
        
        
        n_thread = 8;
    end
   
    methods
        
        function obj = flim_fitting_params()
            import java.lang.*;
            r=Runtime.getRuntime;
            obj.n_thread = r.availableProcessors;
                        
        end
        
        function save_fitting_params(obj,file)
            serialise_object(obj,file);
        end
        
        function set.fit_beta(obj,fit_beta)
            if obj.polarisation_resolved && fit_beta == 1
                fit_beta = 2;
            end
            obj.fit_beta = fit_beta;
            if fit_beta ~= 1
                if length(obj.fixed_beta) ~= obj.n_exp
                    obj.fixed_beta = ones(obj.n_exp,1) / obj.n_exp;
                end
            end
        end
                
        function set.n_exp(obj,n_exp)
            if obj.n_fix > n_exp
                obj.n_fix = n_exp;
            end
            obj.n_exp = n_exp;
              
            if length(obj.tau_guess) < n_exp
                
                padding = ones(n_exp,1) * 2000;
                padding_max = ones(n_exp,1) * 100000;
                padding(1:length(obj.tau_guess)) = obj.tau_guess;
                
                obj.tau_guess = padding;
                obj.tau_max = padding_max;
                obj.tau_min = zeros(size(padding));
                obj.global_beta_group = zeros(n_exp,1);
                
            elseif size(obj.tau_guess,1) > n_exp
                
                obj.tau_guess = obj.tau_guess(1:n_exp);
                obj.tau_min = obj.tau_min(1:n_exp);
                obj.tau_max = obj.tau_max(1:n_exp);
                obj.global_beta_group = zeros(n_exp,1);
                
            end
            
            if obj.n_exp == 1
                obj.fixed_beta = 1;
            end
            
            % Sort variable tau's
            tau_var = obj.tau_guess(obj.n_fix+1:end);
            tau_var = sort(tau_var,'descend');
            
            obj.tau_guess(obj.n_fix+1:end) = tau_var;
            
            if obj.fit_beta ~= 1
                if length(obj.fixed_beta) ~= obj.n_exp
                    obj.fixed_beta = ones(obj.n_exp,1) / obj.n_exp;
                end
            else
                fixed_beta = [];
            end
            
        end
        
        function set.n_fix(obj,n_fix)
            if n_fix > obj.n_exp
                obj.n_fix = obj.n_exp;
            else
                obj.n_fix = n_fix;
            end
        end
        
        function set.n_fret(obj,n_fret)      
            obj.n_fret = n_fret;
            
            if length(obj.fret_guess) > n_fret
                obj.fret_guess = obj.fret_guess(1:n_fret);
            elseif length(obj.fret_guess) < n_fret
                padding = 0.5*ones(n_fret-length(obj.fret_guess),1);
                obj.fret_guess = [obj.fret_guess ; padding];
            end      
            
            if obj.n_fret_fix > n_fret
                obj.n_fret_fix = n_fret;
            end
        end
        
        function set.n_fret_fix(obj,n_fret_fix)
            if n_fret_fix > obj.n_fret
                n_fret_fix = obj.n_fret;
            end
            obj.n_fret_fix = n_fret_fix;
        end
        
        function set.n_theta(obj,n_theta)      
            obj.n_theta = n_theta;
            
            if length(obj.theta_guess) > n_theta
                obj.theta_guess = obj.theta_guess(1:n_theta);
            elseif length(obj.theta_guess) < n_theta
                padding = ones(n_theta-length(obj.theta_guess),1) * 1000;
                obj.theta_guess = [obj.theta_guess ; padding];
            end      
            
            if obj.n_theta_fix > n_theta
                obj.n_theta_fix = n_theta;
            end
        end
        
        function set.n_theta_fix(obj,n_theta_fix)
            if n_theta_fix > obj.n_theta
                n_theta_fix = obj.n_theta;
            end
            obj.n_theta_fix = n_theta_fix;
        end
        
        function set.polarisation_resolved(obj,polarisation_resolved)
            obj.polarisation_resolved = polarisation_resolved;
            if polarisation_resolved
                if obj.n_theta == 0
                    obj.n_theta = 1;
                end
                if obj.fit_beta == 1
                    obj.fit_beta = 0;
                end
            else
                obj.n_theta = 0;
                obj.n_theta_fix = 0;   
            end
        end
        
    end
    
end