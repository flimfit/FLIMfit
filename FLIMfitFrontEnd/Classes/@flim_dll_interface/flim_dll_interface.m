classdef flim_dll_interface < handle
    
    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren


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
        
        progress_bar;
    end
    
    events
        progress_update;
        fit_completed;
    end
        
    properties(Access='protected')
        use_image_irf;
        
        p_t;
        p_t_int;
        p_data;
        p_mask;
        p_tau_guess;
        p_tau_min;
        p_tau_max;
        p_irf;
        p_t_irf;
        p_E_guess;
        p_theta_guess;
        p_ierr;
        p_t0_image;
        p_global_beta_group;
        p_acceptor;
        p_image_t0_shift;
        
        p_use;
        p_background;

        p_tvb_profile;
        p_tvb_profile_single;
        p_fixed_beta;
                
        bin;
        
        fit_timer;
        wait_handle;
        start_time;
        
        im_size;
        
        single_guess;
        use;
        
        dll_id;
    end
        
    methods
    
         function load_global_library(obj) 
         end

         function unload_global_library(obj)
            clear ff_FLIMImage ff_FLIMData ff_FitResult ff_DecayModel ff_Controller
         end
         
         function terminate_fit(obj)
             clear obj.data obj.p_data obj.mask obj.p_beta obj.p_I0 obj.p_chi2 obj.p_ierr obj.p_tau obj.p_t0 obj.p_offset obj.p_scatter;
         end
        
        function obj = flim_dll_interface()
            obj.load_global_library();
            
            obj.dll_id = ff_Controller();
        end
        
        function delete(obj)
            obj.unload_global_library();
        end
       
        
        function im = fill_image(obj,var,mask,min_region)

            if (isempty(mask) || ndims(var)==3 || all(size(var)==size(mask)) || isempty(min_region) )
                im = var;
                return
            end

            n = size(var,1);
            nv = size(var,2);



            im = NaN([length(mask(:)) n]);
            for i=1:n
                for j=1:nv
                    im(mask==(j+min_region-1),i) = var(i,j);
                end
            end
            im = reshape(im,[size(mask) n]);
            
        end
        
    end
    
end

