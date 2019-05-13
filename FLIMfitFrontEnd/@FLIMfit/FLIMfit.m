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
        project_controller
    end
    
    methods
        
        function obj = FLIMfit(wait)
            if nargin < 1; wait = isdeployed; end
            obj.initialise();
            if wait; waitfor(obj.window); end
            check_version(true);
        end
        
        function load_files(obj, files, varargin)
            % Load one or more files 
            obj.data_series_controller.load_files(files, varargin{:}); 
        end
        
        function set_data(obj, t, data, varargin)
            % Set data directly
            obj.data_series_controller.set_data(t, data, varargin{:});
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
            % Fit the data
            obj.fit_controller.fit();
            while ~obj.fit_controller.has_fit
                pause(0.001)
            end
        end
        
        function save_project(obj, path, project_name)
            obj.project_controller.save(path, project_name);
        end
        
        function stats = get_result_statistics(obj)
            stats = obj.result_controller.fit_result.region_stats;
        end
        
        function metadata = get_result_metadata(obj)
            metadata = obj.result_controller.fit_result.metadata;
        end
        
        function im = get_result_image(obj, image, parameter)
            im = obj.fit_controller.fit_result.get_image(image, parameter);
        end
        
        function add_result_callback(obj, callback)
            addlistener(obj.fit_controller, 'fit_completed', @fit_completed);
            
            function fit_completed(src,evt)
                stats = obj.get_result_statistics();
                metadata = obj.get_result_metadata();
                callback(stats, metadata);
            end
        end
        
    end
    
end
