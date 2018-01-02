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
                
        progress_bar;
    end
    
    events
        progress_update;
        fit_completed;
    end
        
    properties(Access='protected')
        use_image_irf;
                
        bin;
        
        fit_timer;
        wait_handle;
        start_time;
        
        im_size;
        
        single_guess;
        use;
        
        dll_id;
        result_objs = struct('type',{},'pointer',{},'valid',{});
    end
        
    methods
    
         function load_global_library(obj) 
         end

         function unload_global_library(obj)
            obj.clear_fit();
            %clear ff_FLIMImage ff_FLIMData ff_FitResult ff_DecayModel ff_Controller
         end
         
         function terminate_fit(obj)
            ff_Controller(obj.dll_id,'StopFit');
         end
        
        function obj = flim_dll_interface()
            obj.load_global_library();
        end
        
        function delete(obj)
            obj.unload_global_library();
        end
       
        function clear_fit(obj)
            for r=1:length(obj.result_objs)
                ff_FitResults(obj.result_objs(r),'Clear');
            end
            obj.result_objs = struct('type',{},'pointer',{},'valid',{});
            if ~isempty(obj.dll_id)
                ff_Controller(obj.dll_id,'Clear');
                obj.dll_id = [];
            end
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

