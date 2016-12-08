classdef flim_fitting_params < handle & h5_serializer
    
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

   
    properties(SetObservable)     

        polarisation_resolved = false;
        
        calculate_errs = false;
        split_fit = false;
        use_memory_mapping = false;
        
        use_autosampling = false;
        
        image_irf_mode = 0;
        
        
        weighting_mode = 0;
        
        merge_regions = false;
        
        n_thread = 8;
    end
   
    methods
        
        function post_serialize(obj)
        end
        
        function post_deserialize(obj)
        end
        
        function obj = flim_fitting_params()
            import java.lang.*;
            r=Runtime.getRuntime;
            obj.n_thread = r.availableProcessors;
                        
        end
        
        function save_fitting_params(obj,file)
            serialise_object(obj,file);
        end
        
    end
    
end