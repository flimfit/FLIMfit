classdef FLIMfit < handle
        
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
        window
        handles
        
        data_series_list
        data_series_controller
        data_intensity_view
        roi_controller
        model_controller
        fit_controller
        result_controller
        data_decay_view
        data_masking_controller
        irf_controller
        plot_controller
        gallery_controller
        hist_controller
        corr_controller
        graph_controller
        platemap_controller
    end
    
    methods
        
        function obj = FLIMfit(wait)
            if nargin < 1
                wait = isdeployed;
            end
            
            obj.initialise();
            
            if wait
                waitfor(obj.window)
            end
            
            check_version(true);
        end
        
        function load_data(obj, files)
            % Load one or more files 
            obj.data_series_controller.load_single(files); 
        end
        
        function load_irf(obj, file)
            % Load instrument response function from file
            obj.data_series_controller.data_series.irf.load_irf(file);
        end
        
        function load_data_settings(obj, file)
            % Load data settings from file
            obj.data_series_controller.data_series.load_data_settings(file);         
        end
        
        function load_model(obj, file)
            % Load a model from file
            obj.model_controller.load(file);
        end
        
        function fit(obj)
            obj.fit_controller.fit();
        end
        
    end
    
end
