classdef flim_dll_interface < handle

    properties        
        fit_params;
        data_series;
        fit_result;
        
        progress_cur_group;
        progress_n_completed
        progress_iter;
        progress_chi2;
        progress;
        
        fit_in_progress = false;
        
        datasets;
        
        
        fit_round = 1;
        n_rounds = 0;
        
        lib_name;
        flim_fit;
    end
    
    events
        progress_update;
        fit_completed;
    end
        
    properties(Access='protected')
        p_t;
        p_n_regions;
    	p_data;
        p_mask;
        p_tau_guess;
        p_tau_min;
        p_tau_max;
        p_irf;
        p_t_irf;
        p_tau;
        p_E_guess;
        p_I0;
        p_beta;
        p_E;
        p_chi2;
        p_ierr;
        p_t0;
        p_offset;
        p_scatter;
        p_ref_lifetime;
        p_tvb;
        p_tvb_profile;
        p_fixed_beta;
        p_grid;
        p_gamma;
        p_use;
        
        p_background;
        p_tau_err;
        p_beta_err;
        p_E_err;
        p_theta_err;
        p_offset_err;
        p_scatter_err;
        p_tvb_err;
        p_ref_lifetime_err;
        
        
        p_magic_decay;
        p_theta_guess;
        p_theta;
        p_r;
        
        I0_size;
        beta_size;
        gamma_size;
        E_size;
        tau_size;
        globals_size;
        n_regions;
        n_regions_total;
        theta_size;
        r_size;
        
        bin;
        grid;
        grid_dims;
        
        fit_timer;
        wait_handle;
        start_time;
        
        n_group;
        n_px;
        n_im;
        
        single_guess;
        use;
        
        dll_id;
    end
        
    methods
    
         function load_global_library(obj)
                
            proto_file = ['FLIMGlobalAnalysisProto_' computer];
            proto_ref = eval(['@' proto_file]);

            if ~libisloaded(obj.lib_name)
                warning('off','MATLAB:loadlibrary:TypeNotFound');
                if ~isdeployed
                    [~,warnings] = loadlibrary(obj.lib_name,'FLIMGlobalAnalysis.h','mfilename',proto_file);
                else
                    loadlibrary(obj.lib_name,proto_ref);
                end
                warning('on','MATLAB:loadlibrary:TypeNotFound');
                
                
            end

            if isempty(obj.dll_id)
                obj.dll_id = calllib(obj.lib_name,'FLIMGlobalGetUniqueID');
            end

            
         end

         function unload_global_library(obj)
             if libisloaded(obj.lib_name)
                unloadlibrary(obj.lib_name)
             end
         end
         
         function terminate_fit(obj)
             obj.fit_in_progress = false;
             calllib(obj.lib_name,'FLIMGlobalTerminateFit',obj.dll_id);
             clear obj.data obj.p_data obj.mask obj.p_beta obj.p_I0 obj.p_chi2 obj.p_ierr obj.p_tau obj.p_t0 obj.p_offset obj.p_scatter;
         end
        
        function obj = flim_dll_interface()
            
            if is64
                obj.lib_name = 'FLIMGlobalAnalysis_64';
            else
                obj.lib_name = 'FLIMGlobalAnalysis_32';
            end
            
            obj.load_global_library();
        end
        
        function delete(obj)
            if libisloaded(obj.lib_name)
                calllib(obj.lib_name,'FLIMGlobalRelinquishID',obj.dll_id);
            end
        end
        
    end
    
end

