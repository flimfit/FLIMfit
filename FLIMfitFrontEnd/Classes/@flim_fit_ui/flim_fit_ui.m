classdef flim_fit_ui < handle
        
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
        data_intensity_view
        roi_controller
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
      
        function obj = flim_fit_ui(wait)
            
            diagnostics('program','start');
            splash = set_splash('FLIMfit-logo-colour.png');
                                
            obj.check_prefs();
           
            if nargin < 1
                wait = isdeployed;
            end
            
            if ~isdeployed
                addpath_global_analysis();
            end
            
            init_pdftops();
            
            % Fix for inverted text in segmentation on one PC
            % use software to do graphics where available
            %if contains(computer,'PCWIN')
            %    opengl software;
            %end
            
            profile = profile_controller.get_instance();
            profile.load_profile();

            % Try and read in version number
            v = read_version();
                        
            % Open a window and add some menus
            obj.window = figure( ...
                'Name', ['FLIMfit ' v], ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'HandleVisibility', 'off', ...
                'Visible','off');
            
            coords = get(0,'MonitorPositions');             
            %position only in main monitor
                        
            monitor = 1;                       
            coords = coords(monitor,:);
            
            % Allow for taskbar if we're on windows
            comp = computer;
            if strcmp(comp(1:2),'PC')
                coords(4) = coords(4) - 40;
                coords(2) = coords(2) + 40;
            end
            
            try 
                set(obj.window,'Units','Pixels','OuterPosition',coords);
            catch e %#ok
               disp('Warning: could not maximise window'); 
            end
            
            handles.version = v;
            handles.window = obj.window;
            handles.use_popup = true;
                                                           
            handles = obj.setup_layout(handles);                        
            handles = obj.setup_toolbar(handles);

            handles.model_controller = flim_model_controller(handles.model_panel);            
            handles.data_series_list = flim_data_series_list(handles);
            handles.data_series_controller = flim_data_series_controller(handles);                                    
            handles.omero_logon_manager = flim_omero_logon_manager(handles);
            
            handles.fitting_params_controller = flim_fitting_params_controller(handles);
            handles.data_intensity_view = flim_data_intensity_view(handles);
            handles.roi_controller = roi_controller(handles);                                                   
            handles.fit_controller = flim_fit_controller(handles);   
            handles.result_controller = flim_result_controller(handles);
            handles.data_decay_view = flim_data_decay_view(handles);
            handles.data_masking_controller = flim_data_masking_controller(handles);
            handles.irf_controller = irf_controller(handles);
            handles.plot_controller = flim_fit_plot_controller(handles);
            handles.gallery_controller = flim_fit_gallery_controller(handles);
            handles.hist_controller = flim_fit_hist_controller(handles);
            handles.corr_controller = flim_fit_corr_controller(handles);
            handles.graph_controller = flim_fit_graph_controller(handles);
            handles.platemap_controller = flim_fit_platemap_controller(handles);            

            handles.project_controller = flim_project_controller(handles);

            handles = obj.setup_menu(handles);            
            handles.file_menu_controller = file_menu_controller(handles);
            handles.omero_menu_controller = omero_menu_controller(handles);
            handles.irf_menu_controller = irf_menu_controller(handles);
            handles.misc_menu_controller = misc_menu_controller(handles);
            handles.tools_menu_controller = tools_menu_controller(handles);
            handles.help_menu_controller = help_menu_controller(handles);
            handles.icy_menu_controller = icy_menu_controller(handles);
            
            guidata(obj.window,handles);
            
            assign_handles(obj,handles)
            
            init_omero_bioformats();
          
            close(splash);
            
            set(obj.window,'Visible','on','CloseRequestFcn',@obj.close_request_fcn);
                       
            if wait
                waitfor(obj.window);
            end
            
        end
        
        function close_request_fcn(obj,~,~)
            
            diagnostics('program','end');
            
            handles = guidata(obj.window);
            client = handles.omero_logon_manager.client;
            
            delete(handles.data_series_controller.data_series)
            
            if ~isempty(client)                
                disp('Closing OMERO session');
                client.closeSession();
                handles.omero_logon_manager.session = [];
                handles.omero_logon_manager.client = [];
            end
            
        
            % Make sure we clean up all the left over classes
            names = fieldnames(handles);
                      
            for i=1:length(names)
                % Check the field is actually a handle and isn't the window
                % which we need to close right at the end
                if ~strcmp(names{i},'window') && all(ishandle(handles.(names{i})))
                    delete(handles.(names{i}));
                end
            end
        
            % Get rid of global figure created by plotboxpos
            global f_temp
            if ~isempty(f_temp) && ishandle(f_temp)
                close(f_temp)
                f_temp = [];
            end
            
            % Finally actually close window
            delete(handles.window);
        
        end
        
    end
    
end
