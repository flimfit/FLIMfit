classdef irf_controller < ui_control_binder & flim_data_series_observer
    
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
        roi_controller;
        data_series_list;
        fit_controller;
        
        irf_lower_ann = [];
        irf_upper_ann = [];
        
        lh = {};
    end
       
    methods 
        function obj = irf_controller(handles)
        
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            obj = obj@ui_control_binder(handles.data_series_controller.data_series.irf);
            
            assign_handles(obj,handles);
            
            obj.bind_control(handles,'t_irf_min','edit');
            obj.bind_control(handles,'t_irf_max','edit');
            obj.bind_control(handles,'irf_background','edit');
            obj.bind_control(handles,'g_factor','edit');
            obj.bind_control(handles,'pol_angle','edit');
            obj.bind_control(handles,'afterpulsing_correction','popupmenu');
            obj.bind_control(handles,'ref_lifetime','edit');
            obj.bind_control(handles,'irf_type','popupmenu');
            obj.bind_control(handles,'t0','edit');
            obj.bind_control(handles,'use_image_t0_correction','checkbox');
                       
            obj.update_controls();
            
        end
        
        function data_set(obj)
            obj.set_bound_data_source(obj.data_series.irf);
        end
        
        function data_update(obj)
        end
        
               
        function irf_background_guess_callback(obj,~,~)
            obj.data_series.estimate_irf_background();
        end
        
        function g_factor_guess_callback(obj,~,~)
            obj.data_series.estimate_g_factor();
        end
        
        function controls_updated(obj,~,~)
            obj.update_controls();
        end
        
        function irf_plot_clicked(obj,src,evt)
            h = obj.irf_display_axes;
        end
        
        function update_background_plot(obj)
            h = obj.background_axes;
            d = obj.data_series;
            
            if d.init && d.background_type == 2
                imagesc(d.background_image,'Parent',h);
                colorbar('peer',h);
                colormap(h,'gray');
                daspect(h,[1 1 1]);
                set(h,'XTick',[]);
                set(h,'YTick',[]);
                set(obj.background_container,'Visible','on');
            else
                set(obj.background_container,'Visible','off');
                %set(h,'Visible','off')
            end
        end
        
        
        function update_controls(obj)
            
            if isfield(obj.controls,'ref_lifetime_edit')
                if obj.data_series.irf.irf_type == 0
                    set(obj.controls.ref_lifetime_edit,'Enable','off');
                else
                   set(obj.controls.ref_lifetime_edit,'Enable','on');
                end
            end
            
        end
        
    end
    
end