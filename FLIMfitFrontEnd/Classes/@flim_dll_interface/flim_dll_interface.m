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
        fit_result;
        
        progress_cur_group;
        progress_n_completed
        progress_iter;
        progress_chi2;
        progress;
        
        fit_in_progress = false;
        
        datasets;
                
        progress_bar;
    end
    
    events
        progress_update;
        fit_completed;
    end
    
    properties(Access='protected')
        
        data_series;
        use_image_irf;
        
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
                
        function terminate_fit(obj)
            ff_Controller(obj.dll_id,'StopFit');
        end
                
        function clear_fit(obj)
            obj.fit_result = [];
            if ~isempty(obj.dll_id)
                ff_Controller(obj.dll_id,'Clear');
                obj.dll_id = [];
            end
        end
        
        function get_return_data(obj)
            if ishandleandvalid(obj.progress_bar)
                obj.progress_bar.StatusMessage = 'Processing Fit Results...';
                obj.progress_bar.Indeterminate = true;
            end
            
            % Get timing information
            t_exec = toc(obj.start_time);
            disp(['DLL execution time: ' num2str(t_exec)]);
            
            result_ptr = ff_Controller(obj.dll_id,'GetFitResults');
            obj.fit_result = flim_fit_result_mex(result_ptr,obj.data_series,obj.datasets);
            
            obj.progress_bar = [];
        end
        
        function update_progress(obj)
            [obj.progress, finished] = ff_Controller(obj.dll_id,'GetFitStatus');
            
            if finished
                obj.get_return_data();
                obj.fit_in_progress = false;
                stop(obj.fit_timer);
                delete(obj.fit_timer);
                notify(obj,'fit_completed');
            else
                notify(obj,'progress_update');
            end
        end
        
        function [progress, n_completed, cur_group, iter, chi2] = get_progress(obj)
            progress = obj.progress;
            n_completed = obj.progress_n_completed;
            cur_group = obj.progress_cur_group;
            iter = obj.progress_iter;
            chi2 = obj.progress_chi2;
        end
        
        function decay = fitted_decay(obj,mask,selected)               
            if obj.bin
                loc = uint32(0);
                im = 1;
            else
                [~,im] = find(obj.fit_result.image == selected); 

                mask = mask(:);
                loc = 0:(length(mask)-1);
                loc = loc(mask);
                loc = uint32(loc);
            end

            if isempty(im)
                decay = [];
                return
            end

            decay = ff_Controller(obj.dll_id, 'GetFit', im - 1, loc);
            decay = nanmean(decay,3);           
        end
        
    end
    
end

