classdef misc_menu_controller < handle
    
    
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
    end
    
    methods
        
        function obj = misc_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
        end
        
        %------------------------------------------------------------------
        % Background
        %------------------------------------------------------------------
        function menu_background_background_load(obj)
            [file,path] = uigetfile('*.*','Select a background file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file], false);    
            end
        end
        
        function menu_background_background_load_average(obj)
            [file,path] = uigetfile('*.*','Select a background file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file], true);    
            end
        end
        
       
        function menu_background_tvb_load(obj)
            [file,path] = uigetfile('*.*','Select a TVB file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_tvb([path file]);    
            end
        end
        
        function menu_background_tvb_I_map_load(obj)
            [file,path] = uigetfile('*.xml','Select a TVB intensity map file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file]);    
            end
        end
        
        function menu_background_tvb_use_selected(obj)
           obj.data_masking_controller.tvb_define();    
        end
        
        
        %------------------------------------------------------------------
        % Segmentation
        %------------------------------------------------------------------
        function menu_segmentation_yuriy(obj)
            new_segmentation_manager(obj.data_series_controller);
        end
        
        function menu_segmentation_phasor(obj)
            phasor_segmentation_manager(obj.data_series_controller);
        end
    end
    
end
