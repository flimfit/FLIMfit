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
      
        function obj = flim_fit_ui(wait)
            
            diagnostics('program','start');
            set_splash('FLIMfit-logo-colour.png');
            
            % pause to allow splash screen to display
            pause(0.1);
            
                    
            obj.check_prefs();
           
            if nargin < 1
                wait = false;
            end
                        
            if ~isdeployed
                addpath_global_analysis();
                if ispc
                    path_ = [pwd '\pdftops.exe'];
                end
                if ismac
                    path_ = [pwd '/pdftops.bin'];
                end
            else
                
                wait = true;
                if ispc
                    path_ = [ctfroot '\FLIMfit\pdftops.exe'];
                end
                if ismac
                    user_string('ghostscript','gs-noX11');
                    path_ = [ctfroot '/FLIMfit/pdftops.bin'];
                end
                
            end
            
            % set up pdftops path
            user_string('pdftops',path_);
            
            % Fix for inverted text in segmentation on one PC
            % use software to do graphics where available
            if ~isempty(strfind(computer,'PCWIN'))
                opengl software;
            end
            
           
           
           
            profile = profile_controller.get_instance();
            profile.load_profile();
            

            % Try and read in version number
            try
                v = textread(['GeneratedFiles' filesep 'version.txt'],'%s');
                v = v{1};
            catch
                v = '[unknown version]';
            end
                        
            % Open a window and add some menus
            obj.window = figure( ...
                'Name', ['FLIMfit ' v], ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'HandleVisibility', 'off', ...
                'Visible','off'); %, ...
                %'Units','normalized', ...
                %'OuterPosition',[0 0.03 1 0.97]);
            
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
            handles = guidata(obj.window); 
             
        
            handles.version = v;
            handles.window = obj.window;
            handles.use_popup = true;
                                                           
            handles = obj.setup_layout(handles);                        
            handles = obj.setup_toolbar(handles);

            handles.data_series_controller = flim_data_series_controller(handles);                                    
            handles.omero_logon_manager = flim_omero_logon_manager(handles);
            
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
            
            
            % unless preferences specifically say not, then show OMERO logon
            %if ~ispref('GlobalAnalysisFrontEnd','NeverOMERO');            
            %   handles.omero_logon_manager.Omero_logon();
            %end
            
            handles = obj.setup_menu(handles);            
            
            handles.menu_controller = front_end_menu_controller(handles);

            guidata(obj.window,handles);
            
         
            loadOmero();
            
            % find paths to OMEuiUtils.jar and ini4j.jar - approach copied from
            % bfCheckJavaPath

            jPath = javaclasspath;

            function findAndAddJar(jar)
               
                already_in_path = any(cellfun(@(x) ~isempty(strfind(x,jar)),jPath));
                
                if ~already_in_path
                    path = which(jar);
                    if isempty(path)
                        path = fullfile(fileparts(mfilename('fullpath')), jar);
                    end
                    if ~isempty(path) && exist(path, 'file') == 2
                        javaaddpath(path);
                        disp(['Added ' jar])
                    else 
                        assert(['Cannot automatically locate ' jar]);
                    end
                end
                
            end
                        
            if ~isdeployed
                findAndAddJar('OMEuiUtils.jar')
                findAndAddJar('ini4j.jar')
            end
   
            % verify that enough memory is allocated for bio-formats
            bfCheckJavaMemory();
          
            % load both bioformats & OMERO
            autoloadBioFormats = 1;

            % load the Bio-Formats library into the MATLAB environment
            status = bfCheckJavaPath(autoloadBioFormats);
            assert(status, ['Missing Bio-Formats library. Either add loci_tools.jar '...
                'to the static Java path or add it to the Matlab path.']);
            
            
            % initialize logging
            %loci.common.DebugTools.enableLogging('INFO');
            loci.common.DebugTools.enableLogging('ERROR');
            
          
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
            
            
            
            diagnostics('program','end');
            
            handles = guidata(obj.window);
            client = handles.omero_logon_manager.client;
            
            %delete(handles.data_series_controller.data_series)
            
            if ~isempty(client)                
                
                disp('Closing OMERO session');
                client.closeSession();
                %
                handles.omero_logon_manager.session = [];
                handles.omero_logon_manager.client = [];
                
            end
            
            exit()
            
            % Make sure we clean up all the left over classes
            %names = fieldnames(handles);
                      
           % for i=1:length(names)
                % Check the field is actually a handle and isn't the window
                % which we need to close right at the end
            %    if ~strcmp(names{i},'window') && all(ishandle(handles.(names{i})))
            %        delete(handles.(names{i}));
            %    end
            %end
            
       
            % Finally actually close window
            %delete(handles.window);
           
            % kluge to close the left over figure 
            %- TBD work out what's leaving it open
           % h = get(0,'Children');
           % if ~isempty(h)
           %     close(h);
           % end
            
           % clear all;

             
          
            
            
        end
        
    end
    
end
