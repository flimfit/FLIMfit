classdef front_end_menu_controller < handle
    
    properties
        
        menu_OMERO_fetch_TCSPC;
        menu_OMERO_irf_TCSPC;
        
       

        menu_file_new_window;
        
        menu_file_load_single;
        menu_file_load_widefield;
        menu_file_load_tcspc;
        
        menu_file_load_single_pol;
        menu_file_load_tcspc_pol;
        
        menu_file_reload_data;
        
        menu_file_save_dataset;
        menu_file_save_raw;
        
        menu_file_export_decay;
        menu_file_export_decay_series;
        
        menu_file_set_default_path;
        menu_file_load_test;
        menu_file_load_raw;
        
        menu_file_open_fit;
        menu_file_save_fit;
        
        menu_file_export_plots;
        menu_file_export_gallery;
        menu_file_export_hist_data;
        
        menu_file_export_fit_table;
        
        menu_file_import_fit_params;
        menu_file_export_fit_params;
        
        menu_file_import_fit_results;
        menu_file_export_fit_results;
        
        
        menu_irf_load;
        menu_irf_set_delta;
        menu_irf_set_rectangular;
        menu_irf_set_gaussian;
        
        menu_background_background_load;
        menu_background_background_load_series;
        
        menu_segmentation_manual;
        menu_segmentation_yuriy;
        
        menu_view_data
        menu_view_plots;
        menu_view_hist_corr;
        menu_view_chi2_display;
        
        menu_test_test1;
        
        menu_batch_batch_fitting;
        
        data_series_controller;
        data_decay_view;
        fit_controller;
        fitting_params_controller;
        plot_controller;
        hist_controller;
        
        session;    % OMERO session ID
    end
    
    properties(SetObservable = true)
        default_path;
        recent_data;
        recent_irf;
    end
    
    
    methods
        function obj = front_end_menu_controller(handles)
            assign_handles(obj,handles);
            set_callbacks(obj);
            try
                obj.default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            catch %#ok
                addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
                obj.default_path = 'C:\';
            end
            
            try
                obj.recent_data = getpref('GlobalAnalysisFrontEnd','RecentData');
            catch %#ok
                addpref('GlobalAnalysisFrontEnd','RecentData',[])
                obj.recent_data = [];
            end
            
            try
                obj.recent_irf = getpref('GlobalAnalysisFrontEnd','RecentIRF');
            catch %#ok
                addpref('GlobalAnalysisFrontEnd','RecentIRF',[])
                obj.recent_irf = [];
            end
            
            obj.session = handles.OMERO_session;      % OMERO session ID
        end
        
        function set_callbacks(obj)
            
             mc = metaclass(obj);
             obj_prop = mc.Properties;
             obj_method = mc.Methods;
             
             for i=1:length(obj_prop)
                prop = obj_prop{i}.Name;
                if strncmp(prop,'menu_',5)
                    method = [prop '_callback'];
                    matching_methods = findobj([obj_method{:}],'Name',method);
                    if ~isempty(matching_methods)               
                        eval(['set(obj.' prop ',''Callback'',@obj.' method ')' ]);
                    end
                end          
             end
             
        end
        
        
        function set.default_path(obj,default_path)
            obj.default_path = default_path;
            setpref('GlobalAnalysisFrontEnd','DefaultFolder',default_path);
        end
        
        function set.recent_data(obj,recent_data)
            obj.recent_data = recent_data;
            setpref('GlobalAnalysisFrontEnd','RecentData',recent_data);
        end
        
        function set.recent_irf(obj,recent_irf)
            obj.recent_irf = recent_irf;
            setpref('GlobalAnalysisFrontEnd','RecentIRF',recent_irf);
        end
        
        function add_recent_data(obj,type,path)
            obj.recent_data = [obj.recent_data; [type, path]];
        end

        function add_recent_irf(obj,path)
            obj.recent_irf = [obj.recent_irf; path];
        end
        
        %------------------------------------------------------------------
        % Default Path
        %------------------------------------------------------------------
        function menu_file_new_window_callback(obj,~,~)
            GlobalProcessing();
        end
        
        %------------------------------------------------------------------
        % Default Path
        %------------------------------------------------------------------
        function menu_file_set_default_path_callback(obj,~,~)
            path = uigetdir(obj.default_path,'Select default path');
            if path ~= 0
                obj.default_path = path; 
            end
        end
        
        
        
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------
        function menu_OMERO_fetch_TCSPC_callback(obj,~,~)
      
            dlgTitle = 'Enter Image ID';
            prompt = {'ID '};
            defaultvalues = {'0'};
            imageID = 0;
            numLines = 1;
           
            while (imageID < 1) 
                inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                imageID = uint32(str2num(inputdata{1}));
            end

            session = obj.session; 
           
            obj.data_series_controller.fetch_TCSPC({session, imageID}); 
          
        end
        
        
        function menu_OMERO_irf_TCSPC_callback(obj,~,~)
      
            dlgTitle = 'Enter Image ID';
            prompt = {'ID '};
            defaultvalues = {'0'};
            imageID = 0;
            numLines = 1;
           
            while (imageID < 1) 
                inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                imageID = uint32(str2num(inputdata{1}));
            end
            
            session = obj.session;
            
            polarisation_resolved = false;
            
           
            % allow one channel to be loaded as an irf
            channel = obj.data_series_controller.data_series.request_channels(polarisation_resolved);
           
            obj.data_series_controller.data_series.fetchirf_TCSPC({session, imageID}, polarisation_resolved, channel); 
          
        end
        %------------------------------------------------------------------
        % Load Data
        %------------------------------------------------------------------
        function menu_file_load_single_callback(obj,~,~)
            [file,path] = uigetfile('*.*','Select a file from the data',obj.default_path);
            if file ~= 0
                obj.data_series_controller.load_single([path file]); 
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_load_widefield_callback(obj,~,~)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                obj.data_series_controller.load_data_series(folder,'widefield'); 
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_load_tcspc_callback(obj,~,~)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                obj.data_series_controller.load_data_series(folder,'TCSPC');
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_load_single_pol_callback(obj,~,~)
            [file,path] = uigetfile('*.*','Select a file from the data',obj.default_path);
            if file ~= 0
                obj.data_series_controller.load_single([path file],true); 
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
                end
        
        function menu_file_load_tcspc_pol_callback(obj,~,~)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                obj.data_series_controller.load_data_series(folder,'TCSPC',true);
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_reload_data_callback(obj,~,~)
            obj.data_series_controller.data_series.reload_data;
        end
        
        function menu_file_load_test_callback(obj,~,~)
            
            data_folder = 'C:\users\scw09\documents\Local FLIM Data\01_TestDataFolder\Data';
            obj.data_series_controller.load_data_series(data_folder,'widefield'); 
            %obj.data_series_controller.load_single('C:\Documents and Settings\scw09\My Documents\100X objective\Cotransfected CV2\TC1\Time course 00_00000s\fr000del000000.tif');
            %obj.data_series_controller.load_data_series('C:\Documents and Settings\scw09\My Documents\100X objective\Cotransfected CV2\TC1','widefield');
            
            %obj.data_series_controller.load_single('C:\Documents and Settings\scw09\My Documents\RefReconvTest\data\fr000del000333.tif');
            %obj.data_series_controller.load_single('X:\Imperial\2010-07-29 SP5 MEF Libra\03 MEF WT libra PDGF\2010-07-29 03 t=0.sdt');
            %obj.data_series_controller.load_data_series('X:\Imperial\2010-07-29 SP5 MEF Libra\03 MEF WT libra PDGF\','TCSPC'); 
            %obj.data_series_controller.load_data_series('sim\tau=3000+2800\','widefield'); 
            %obj.data_series_controller.load_single('sim\fret_data\fr000del001000.tif'); 
            
            irf_file = 'C:\users\scw09\documents\Local FLIM Data\01_TestDataFolder\irf\fr000del000000.tif';
            %irf_file = 'C:\Documents and Settings\scw09\My Documents\100X objective\IRFs\IRF 1514\fr000del000000.tif';
            %irf_file = 'C:\Documents and Settings\scw09\My Documents\RefReconvTestIRF2\data\fr000del000020.tif';
            %irf_file = 'X:\Imperial\2010-07-29 SP5 MEF Libra\Data Trace of 2010-07-29-irf-daspi-au=3.irf';
            %irf_file = 'sim\irf7.irf';
            
            obj.data_series_controller.data_series.load_irf(irf_file);
        end
        
        %------------------------------------------------------------------
        % Export Data
        %------------------------------------------------------------------
        function menu_file_save_dataset_callback(obj,~,~)
            [filename, pathname] = uiputfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_series([pathname filename]);         
            end
        end
        
        function menu_file_save_raw_callback(obj,~,~)
            [filename, pathname] = uiputfile({'*.raw', 'Raw File (*.raw)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_raw_data([pathname filename]);         
            end
        end
        
        function menu_file_load_raw_callback(obj,~,~)
            [filename, pathname] = uigetfile({'*.raw', 'Raw File (*.raw)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.load_raw([pathname filename]);         
            end
        end
        
        %------------------------------------------------------------------
        % Export Decay
        %------------------------------------------------------------------
        function menu_file_export_decay_callback(obj,~,~)
            [filename, pathname] = uiputfile({'*.txt', 'TXT File (*.txt)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_decay_view.update_display([pathname filename]);
            end
        end
        
        function menu_file_export_decay_series_callback(obj,~,~)
            [filename, pathname] = uiputfile({'*.txt', 'TXT File (*.txt)'},'Select file postfix',obj.default_path);
            if filename ~= 0
                obj.data_decay_view.update_display([pathname filename],'all');
            end
        end
        
        %------------------------------------------------------------------
        % Import/Export Fit Results
        %------------------------------------------------------------------
        function menu_file_export_fit_results_callback(obj,~,~)
            [filename, pathname] = uiputfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fit_controller.save_fit_result([pathname filename]);         
            end
        end

        function menu_file_import_fit_results_callback(obj,~,~)
            [filename, pathname] = uigetfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fit_controller.load_fit_result([pathname filename]);           
            end
        end
        
        %------------------------------------------------------------------
        % Import/Export Fit Parameters
        %------------------------------------------------------------------
        function menu_file_export_fit_params_callback(obj,~,~)
            [filename, pathname] = uiputfile({'fit_parameters.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fitting_params_controller.save_fitting_params([pathname filename]);         
            end
        end

        function menu_file_import_fit_params_callback(obj,~,~)
            [filename, pathname] = uigetfile({'*.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fitting_params_controller.load_fitting_params([pathname filename]);           
            end
        end

        %------------------------------------------------------------------
        % Export Fit Table
        %------------------------------------------------------------------
        function menu_file_export_fit_table_callback(obj,~,~)
            [filename, pathname] = uiputfile({'*.csv', 'CSV File (*.csv)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fit_controller.save_param_table([pathname filename]);
            end
        end
        
        %------------------------------------------------------------------
        % IRF
        %------------------------------------------------------------------
        function menu_irf_load_callback(obj,~,~)
            [file,path] = uigetfile('*.*','Select a file from the irf',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_irf([path file]);    
            end
        end
        
        function menu_irf_set_delta_callback(obj,~,~)
            obj.data_series_controller.data_series.set_delta_irf();
        end
        
        function menu_irf_set_rectangular_callback(obj,~,~)
            width = inputdlg('IRF Width','IRF Width',1,{'500'});
            width = str2double(width);
            obj.data_series_controller.data_series.set_rectangular_irf(width);
        end
        
        function menu_irf_set_gaussian_callback(obj,~,~)
            width = inputdlg('IRF Width','IRF Width',1,{'500'});
            width = str2double(width);
            obj.data_series_controller.data_series.set_gaussian_irf(width);
        end
        
        %------------------------------------------------------------------
        % Background
        %------------------------------------------------------------------
        function menu_background_background_load_callback(obj,~,~)
            [file,path] = uigetfile('*.tif','Select a background image file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file]);    
            end
        end
        
        %------------------------------------------------------------------
        % Background
        %------------------------------------------------------------------
        function menu_background_background_load_series_callback(obj,~,~)
            [path] = uigetdir(obj.default_path,'Select a folder of background images');
            if path ~= 0
                obj.data_series_controller.data_series.load_background(path);    
            end
        end
        
        %------------------------------------------------------------------
        % Segmentation
        %------------------------------------------------------------------
        function menu_segmentation_yuriy_callback(obj,~,~)
            yuiry_segmentation_manager(obj.data_series_controller);
        end
        
        %------------------------------------------------------------------
        % Batch Fit
        %------------------------------------------------------------------
        function menu_batch_batch_fitting_callback(obj,~,~)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                settings_file = tempname;
                fit_params = obj.fitting_params_controller.fit_params;
                obj.data_series_controller.data_series.save_data_settings(settings_file);
                batch_fit(folder,'widefield',settings_file,fit_params);
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
            
        end
        
        %------------------------------------------------------------------
        % Views
        %------------------------------------------------------------------
        
        function menu_view_chi2_display_callback(obj,~,~)
            chi2_display(obj.fit_controller);
        end
        
        function menu_test_test1_callback(obj,~,~)
            regression_testing(obj);
            %polarisation_testing(obj.data_series_controller.data_series,obj.default_path);
        end
        
        function menu_file_export_plots_callback(obj, ~, ~)
            [filename, pathname, ~] = uiputfile( ...
                        {'*.tiff', 'TIFF image (*.tiff)';...
                         '*.pdf','PDF document (*.pdf)';...
                         '*.png','PNG image (*.png)';...
                         '*.eps','EPS level 1 image (*.eps)';...
                         '*.fig','Matlab figure (*.fig)';...
                         '*.*',  'All Files (*.*)'},...
                         'Select root file name',[obj.default_path '\fit']);

            if ~isempty(filename)
                obj.plot_controller.update_plots([pathname filename])
            end
        end
        
        function menu_file_export_all_callback(obj,~,~)
            
        end
        
        function menu_file_export_gallery_callback(obj, ~, ~)

            [filename, pathname, ~] = uiputfile( ...
                        {'*.tiff', 'TIFF image (*.tiff)';...
                         '*.pdf','PDF document (*.pdf)';...
                         '*.png','PNG image (*.png)';...
                         '*.eps','EPS level 1 image (*.eps)';...
                         '*.fig','Matlab figure (*.fig)';...
                         '*.*',  'All Files (*.*)'},...
                         'Select root file name',[obj.default_path '\fit']);

            if ~isempty(filename)
                obj.plot_controller.update_gallery([pathname filename])
            end
            
        end
        
        function menu_file_export_hist_data_callback(obj, ~, ~)
            [filename, pathname] = uiputfile({'*.txt', 'Text File (*.txt)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.hist_controller.export_histogram_data([pathname filename]);
            end
        end


    end
    
end
