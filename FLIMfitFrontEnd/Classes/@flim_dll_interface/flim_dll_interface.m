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
        progress;
        datasets;
    end
    
    events
        progress_update;
        fit_completed;
    end
    
    properties(Access='protected')
        data_series;
        use_image_irf;
        
        bin;        
        use;
        
        dll_id;
    end
    
    methods
                
        function terminate_fit(obj)
            ff_Controller(obj.dll_id,'StopFit');
        end
                
        function clear_fit(obj)
            if ~isempty(obj.dll_id)
                ff_Controller(obj.dll_id,'Clear');
                obj.dll_id = [];
            end
        end
        
        function fit_result = get_fit_result(obj)
            result_ptr = ff_Controller(obj.dll_id,'GetFitResults');
            fit_result = flim_fit_result_mex(result_ptr,obj.data_series,obj.datasets);
        end
        
        function [progress, finished] = get_progress(obj)
            [progress, finished] = ff_Controller(obj.dll_id,'GetFitStatus');
        end
        
        function decay = fitted_decay(obj,mask,selected)               
            if obj.bin
                loc = uint32(0);
                im = 1;
            else
                [~,im] = find(obj.datasets == selected); 

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

