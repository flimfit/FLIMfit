classdef global_processing_ui
   
    properties
        window
        %handles
    end
    
    methods
      
        function obj = global_processing_ui(OMERO_active,wait)
            
            
            if nargin < 1 
                OMERO_active = false;
            end
            
            if nargin < 2
                wait = false;
            end
            
            
            
            if ~isdeployed
                addpath_global_analysis()
            else
                wait = true;
            end
            
            client = [];
            session = [];       %default value
            
            if OMERO_active == true
            
                logon = OMERO_logon;
                
                client = loadOmero(logon{1});
                try 
                    session = client.createSession(logon{2},logon{3});
                catch  err
                    errordlg('error while creating OMERO session');
                end
            end
            
            
            
                % Open a window and add some menus
            obj.window = figure( ...
                'Name', 'GlobalProcessing', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'HandleVisibility', 'off', ...
                'Visible','off', ...
                'Units','normalized', ...
                'OuterPosition',[0 0.03 1 0.97]);
            
           
                
            obj.setup_layout();
            
            if isempty(session)
                obj.setup_menu();
            else
               obj.setup_alt_menu();
            end
            
            obj.setup_toolbar();

            handles = guidata(obj.window); 

            handles.window = obj.window;
            handles.use_popup = true;
            handles.data_series_controller = flim_data_series_controller(handles);
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
            
            handles.OMERO_session = session;
            handles.OMERO_client = client;

            handles.menu_controller = front_end_menu_controller(handles);

            set(obj.window,'Visible','on');
            %set(obj.window,'CloseRequestFcn',@obj.close_request_fcn);
            
            set(obj.window,'Closerequestfcn', {@obj.close_request_fcn, handles}) 
            
            try
                v = textread(['GeneratedFiles' filesep 'version.txt'],'%s');
            catch
                v = '[unknown version]';
            end
            
            disp(['Welcome to GlobalProcessing v' v{1}]);
            
            if wait
                waitfor(obj.window);
            end
            

            
        end
        
        function close_request_fcn(obj,src,evt, handles)
         
            
            disp('Closing GlobalProcessing on request');
            
            session = handles.OMERO_session;
            client = handles.OMERO_client;
            
            
         
            global f_temp
            if isempty(f_temp)
                close(f_temp)
            end
            
            clear handles;
            
            
            delete(obj.window);
            
            clear obj;
            
            if ~isempty(session)
                
                %Close the OMERO session
                disp('Closing OMERO session');
                
                
                
                client.closeSession();
                %clear client;
                %clear session;
                %unloadOmero();
                %clear java;
            end
            
            
        end
        
    end
    
end

