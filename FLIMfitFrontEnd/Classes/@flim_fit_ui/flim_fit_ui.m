    classdef flim_fit_ui
        
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
    end
    
    methods
      
        function obj = flim_fit_ui(wait,OMERO_active,external,require_auth)
            
            set_splash('FLIMfit_splash1.tif');
                    
            if nargin < 1
                wait = false;
            end
            if nargin < 2
                OMERO_active = false;
            end
            if nargin < 3
                external = false;
            end
            if nargin < 4
                require_auth = false;
            end
            
            if ~isdeployed
                addpath_global_analysis()
            else
                wait = true;
            end
            
           
            profile = profile_controller();
            profile.load_profile();
            

            % Try and read in version number
            try
                v = textread(['GeneratedFiles' filesep 'version.txt'],'%s');
                v = v{1};
            catch
                v = '[unknown version]';
            end
            
            %{
            cur_ver = urlread('https://raw.github.com/openmicroscopy/Imperial-FLIMfit/master/GlobalProcessingFrontEnd/GeneratedFiles/version.txt');
            if obj.split_ver(cur_ver) > obj.split_ver(v)
                msgbox(['A new version of FLIMfit, v' cur_ver ' is now available. ']);
            end
              %}  
            % Get authentication if needed
            %{
            if require_auth
                auth_text = urlread('https://global-analysis.googlecode.com/hg/GlobalAnalysisAuth.txt');
                auth_success = false;
                
                if strfind(auth_text,'external_auth=false')
                    auth_success = true;
                end
                
                min_ver = regexp(auth_text,'min_version=([[0-9]\.]+)','tokens');
                if ~isempty(min_ver)
                    min_ver = obj.split_ver(min_ver{1}{1});
                else
                    min_ver = 0;
                end
                if min_ver == 0 || obj.split_ver(v{1}) < min_ver
                    auth_success = false;
                end
                if ~auth_success 
                    disp('Sorry, error occured while authenticating.');
                    return
                end
            end
            %}
            
            % Open a window and add some menus
            obj.window = figure( ...
                'Name', ['FLIMfit ' v], ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'HandleVisibility', 'off', ...
                'Visible','off', ...
                'Units','normalized', ...
                'OuterPosition',[0 0.03 1 0.97]);
            
            coords = get(0,'MonitorPositions');             
             %position only in main monitor
            hostname = getenv('COMPUTERNAME');
            % I want it on my second monitor!
            if strcmp(hostname,'PH-SCW09') && size(coords,1)==2
                monitor = 2;
            else
                monitor = 1;
            end                         
            coords = coords(monitor,:);
            
            % Allow for taskbar if we're on windows
            comp = computer;
            if strcmp(comp(1:2),'PC')
                coords(4) = coords(4) - 30;
                coords(2) = coords(2) + 30;
            end
            set(obj.window,'Units','Pixels','OuterPosition',coords);
           
            handles = guidata(obj.window); 
                                                
            handles.external = external;
            handles.version = v;
            handles.window = obj.window;
            handles.use_popup = true;
                                                           
            handles = obj.setup_layout(handles);                        
            handles = obj.setup_toolbar(handles);

            handles.data_series_controller = flim_data_series_controller(handles);                                    
            handles.omero_data_manager = flim_omero_data_manager(handles);
            
            handles.fitting_params_controller = flim_fitting_params_controller(handles);
            handles.data_series_list = flim_data_series_list(handles);
            handles.data_intensity_view = flim_data_intensity_view(handles);
            handles.roi_controller = roi_controller(handles);                                                   
            handles.fit_controller = flim_fit_controller(handles);    
            handles.data_decay_view = flim_data_decay_view(handles);
            handles.data_masking_controller = flim_data_masking_controller(handles);
            handles.plot_controller = flim_fit_plot_controller(handles);
            handles.gallery_controller = flim_fit_gallery_controller(handles);
            handles.hist_controller = flim_fit_hist_controller(handles);
            handles.corr_controller = flim_fit_corr_controller(handles);
            handles.graph_controller = flim_fit_graph_controller(handles);
            handles.platemap_controller = flim_fit_platemap_controller(handles);            
                        
            if OMERO_active == true               
               handles.omero_data_manager.Omero_logon();
            end
            
            handles = obj.setup_menu(handles);            
            
            handles.menu_controller = front_end_menu_controller(handles);

            guidata(obj.window,handles);
            
            close all;
            
            set(obj.window,'Visible','on');
            set(obj.window,'CloseRequestFcn',@obj.close_request_fcn);
                        
            if wait
                waitfor(obj.window);
            end
            
            
        end
        
        function vx = split_ver(obj,ver)
            % Convert version string into a number
            tk = regexp(ver,'([0-9]+).([0-9]+).([0-9]+)','tokens');
            if ~isempty(tk{1})
                tk = tk{1};
                vx = str2double(tk{1})*1e6 + str2double(tk{2})*1e3 + str2double(tk{3});
            else 
                vx = 0;
            end
        end

        
        function close_request_fcn(obj,~,~)
            
            handles = guidata(obj.window);
            client = handles.omero_data_manager.client;
            
            if ~isempty(client)                
                % save logon anyway                
                %logon = handles.omero_data_manager.logon;
                %logon_filename = handles.omero_data_manager.omero_logon_filename;                
                %omero_logon = [];
                %omero_logon.logon = logon;
                %if ~handles.external
                %    xml_write(logon_filename,omero_logon);                                
                %end;
                %
                disp('Closing OMERO session');
                client.closeSession();
                %
                handles.omero_data_manager.session = [];
                handles.omero_data_manager.client = [];
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
            
            % Finally actaully close window
            delete(handles.window);
            
        end
        
    end
    
end
