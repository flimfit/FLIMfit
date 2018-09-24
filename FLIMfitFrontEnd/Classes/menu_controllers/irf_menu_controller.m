classdef irf_menu_controller < handle
    
    
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
        data_series_controller;
        data_masking_controller;
        data_series_list;
        
        menu_irf_recent;
        
        recent_irf;
    end
    
    methods(Access=private)
        
        function add_recent_irf(obj,path)
            if ~any(strcmp(path,obj.recent_irf))
                obj.recent_irf = [path; obj.recent_irf];
            end
            if length(obj.recent_irf) > 20
                obj.recent_irf = obj.recent_irf(1:20);
            end
            setpref('GlobalAnalysisFrontEnd','RecentIRF',obj.recent_irf);
            obj.update_recent_irf_list();
        end
        
        function update_recent_irf_list(obj)
            
            function menu_call(file)
                 obj.data_series_controller.data_series.irf.load_irf(file);
            end
            
            if ~isempty(obj.recent_irf)
                names = create_relative_path(default_path,obj.recent_irf);

                delete(get(obj.menu_irf_recent,'Children'));
                add_menu_items(obj.menu_irf_recent,names,@menu_call,obj.recent_irf)
            end
        end
        
        
    end
    
    methods
        
        function obj = irf_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
            
            obj.recent_irf = getpref('GlobalAnalysisFrontEnd','RecentIRF',{});
            obj.update_recent_irf_list();
        end
        
        function menu_irf_load(obj)
            [file,path] = uigetfile('*.*','Select a file from the irf',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.irf.load_irf([path file]);
                obj.add_recent_irf([path file]);
            end
        end
        
        function menu_irf_image_load(obj)
            [file,path] = uigetfile('*.*','Select a file from the irf',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.irf.load_irf([path file],true);
            end
        end
        
        function menu_irf_estimate_background(obj)
            obj.data_series_controller.data_series.estimate_irf_background();
        end
        
        function menu_irf_estimate_t0(obj)
            obj.data_masking_controller.t0_guess();    
        end
        
        function menu_irf_estimate_g_factor(obj)
            obj.data_masking_controller.g_factor_guess();    
        end        
        
        
        function menu_irf_fit_gaussian_irf(obj)
            
            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = sum(double(data),3);
            
            analytical = false;
            
            estimate_irf_interface(t,data,T,analytical,default_path);
            
        end

        function menu_irf_fit_analytical_irf(obj)
            
            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = sum(double(data),3);
            
            analytical = true;
            
            estimate_irf_interface(t,data,T,analytical,default_path);
            
        end
        
        function menu_irf_fit_pol_resolved_irf(obj)

            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = sum(double(data),3);
            
            estimate_polarisation_resolved_irf_interface(t,data,T,default_path);
            
        end

        
    end
    
end
