classdef front_end_menu_controller < handle
    
    properties
        
% %         menu_OMERO_fetch_TCSPC;
% %         menu_OMERO_irf_TCSPC;
% %         menu_OMERO_store_fit_result;


        %%%%%%%%%%%%%%%%%%%%%%% OMERO        
        %
        menu_OMERO_Set_Dataset;
        %
% %         menu_OMERO_Load_FLIM_Data_Widefield;
% %         menu_OMERO_Load_FLIM_Dataset_Widefield;
% %         menu_OMERO_Load_FLIM_Data_TCSPC;
% %         menu_OMERO_Load_FLIM_Dataset_TCSPC;        
        menu_OMERO_Load_FLIM_Data;
        menu_OMERO_Load_FLIM_Dataset;  
        menu_OMERO_Load_FLIM_Screen;
        %        
        menu_OMERO_Load_IRF_image;
        menu_OMERO_Load_IRF_annot;
        %    
        menu_OMERO_Load_Background;    
        menu_OMERO_Load_Time_Varying_Background;    
        %
        menu_OMERO_Export_Fitting_Results;    
        menu_OMERO_Export_Fitting_Settings;    
        %
        menu_OMERO_Import_Fitting_Settings;    
                        
        session;    % set up in constructor
        %
        % locals to work with single-image hack
            dataset;    % current OMERO dataset
            project;    % current OMERO project
            selected_channel; % need to keep this for results loading to Omero...
        %%%%%%%%%%%%%%%%%%%%%%% OMERO

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
        menu_file_recent_default
        
        menu_file_load_raw;
        
        menu_file_open_fit;
        menu_file_save_fit;
        
        menu_file_export_plots;
        menu_file_export_gallery;
        menu_file_export_hist_data;
        
        menu_file_import_plate_metadata;
        
        menu_file_export_fit_table;
        
        menu_file_import_fit_params;
        menu_file_export_fit_params;
        
        menu_file_import_fit_results;
        menu_file_export_fit_results;
        
        
        menu_irf_load;
        menu_irf_image_load;
        menu_irf_set_delta;
        
        menu_irf_estimate_t0;
        menu_irf_estimate_g_factor;
        menu_irf_estimate_background;
        %menu_irf_set_rectangular;
        %menu_irf_set_gaussian;
        menu_irf_recent;
        
        menu_background_background_load;
        menu_background_background_load_series;
        
        menu_background_tvb_load;
        menu_background_tvb_use_selected;
        
        menu_segmentation_manual;
        menu_segmentation_yuriy;
        
        menu_tools_photon_stats;
        menu_tools_estimate_irf;
        
        menu_view_data
        menu_view_plots;
        menu_view_hist_corr;
        menu_view_chi2_display;
        
        menu_test_test1;
        menu_test_unload_dll;
        
        menu_help_bugs;
        menu_help_tracker;
        
        menu_batch_batch_fitting;
        
        data_series_controller;
        data_decay_view;
        fit_controller;
        fitting_params_controller;
        plot_controller;
        hist_controller;
        data_masking_controller;
        
        recent_irf;
        recent_default_path;

        default_path;

    end
    
    properties(SetObservable = true)

        recent_data;
    end
    
    
    methods
        function obj = front_end_menu_controller(handles)
            assign_handles(obj,handles);
            set_callbacks(obj);
            try
                obj.default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            catch e
                addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
                obj.default_path = 'C:\';
            end
            
            try
                obj.recent_data = getpref('GlobalAnalysisFrontEnd','RecentData');
            catch %#ok
                addpref('GlobalAnalysisFrontEnd','RecentData',{})
                obj.recent_data = [];
            end
            
            try
                obj.recent_irf = getpref('GlobalAnalysisFrontEnd','RecentIRF');
            catch e
                addpref('GlobalAnalysisFrontEnd','RecentIRF',{})
                obj.recent_irf = {};
            end
            
            try
                obj.recent_default_path = getpref('GlobalAnalysisFrontEnd','RecentDefaultPath');
            catch e
                addpref('GlobalAnalysisFrontEnd','RecentDefaultPath',{})
                obj.recent_default_path = {};
            end
            
            % obj.update_recent_irf_list(); % YA ????? !!!!!!
            
            obj.update_recent_default_list();
            
            obj.session = handles.OMERO_session;      % OMERO session ID
        end
        
        function set_callbacks(obj)
            
             mc = metaclass(obj);
             obj_prop = mc.Properties;
             obj_method = mc.Methods;
             
             
             % Search for properties with corresponding callbacks
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
        
                       
        function set.recent_data(obj,recent_data)
            obj.recent_data = recent_data;
            setpref('GlobalAnalysisFrontEnd','RecentData',recent_data);
        end
        
        function add_recent_data(obj,type,path)
            obj.recent_data = {obj.recent_data; [type, path]};
        end

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
                 obj.data_series_controller.data_series.load_irf(file);
            end
            
            if ~isempty(obj.recent_irf)
                names = create_relative_path(obj.default_path,obj.recent_irf);

                delete(get(obj.menu_irf_recent,'Children'));
                add_menu_items(obj.menu_irf_recent,names,@menu_call,obj.recent_irf)
            end
        end
        
        function update_recent_default_list(obj)
            function menu_call(path)
                 obj.default_path = path;
                 setpref('GlobalAnalysisFrontEnd','DefaultFolder',path);
            end
            
            if ~isempty(obj.recent_default_path)
                names = obj.recent_default_path;

                delete(get(obj.menu_file_recent_default,'Children'));
                add_menu_items(obj.menu_file_recent_default,names,@menu_call,obj.recent_default_path)
            end
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
                
                if ~any(strcmp(path,obj.recent_default_path))
                    obj.recent_default_path = [path; obj.recent_default_path];
                end
                if length(obj.recent_default_path) > 20
                    obj.recent_default_path = obj.recent_default_path(1:20);
                end
                setpref('GlobalAnalysisFrontEnd','RecentDefaultPath',obj.recent_default_path);
                
                setpref('GlobalAnalysisFrontEnd','DefaultFolder',path);
                obj.update_recent_default_list();
                obj.update_recent_irf_list();
            end
        end
        
        
        
        
        
        
        
        
        
        
        
        
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------
        function menu_OMERO_Set_Dataset_callback(obj,~,~)
            %
            [ Dataset Project ] = select_Dataset(obj.session,'Select a Dataset:'); 
            %
            if isempty(Dataset) 
                return; 
            end;
            %
            obj.dataset = Dataset;
            obj.project = Project;
            % 
        end                
        
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Data_callback(obj,~,~)
            %
            obj.set_dataset_if_not_selected;
            %
            if isempty(obj.dataset), return, end;            
            % 
            image = select_Image(obj.dataset);
            %
            if ~isempty(image) 
                try
                    obj.selected_channel = obj.data_series_controller.fetch_TCSPC({obj.session, image.getId().getValue()});                                                                                    
                catch ME
                    errorglg('Error when loading an image')
                    display(ME);
                end;
            end;
        end                          
        
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Dataset_callback(obj,~,~)
            %
            % always work with datasets ...
            obj.set_dataset_if_not_selected;
            if isempty(obj.dataset), return, end;                        
            %
            % work only with "sdt" for now...
            extension = 'sdt';
            imageList = obj.dataset.linkedImageList;
            %       
            if 0==imageList.size()
                errordlg(['Dataset have no images - please choose Dataset with images'])
                return;
            end;                                    
            %        
             z = 0;       
             str = char(512,256); % ?????
             for k = 0:imageList.size()-1,                       
                     z = z + 1;                                                       
                     iName = char(java.lang.String(imageList.get(k).getName().getValue()));                                                                
                     A = split('.',iName);
                     if true % strcmp(extension,A(length(A))) 
                        str(z,1:length(iName)) = iName;
                     end;
             end 
            %
            folder_names = sort_nat(cellstr(str));               
            %folder_names = cellstr(str); %without sort_nat    
            %
% ???????            
% %             selected = [];        
% %             if isempty(selected)
% %                 [folder_names, ~, obj.data_series_controller.data_series.lazy_loading] = dataset_selection(folder_names);
% %             elseif strcmp(selected,'all')
% %                 obj.data_series_controller.data_series.lazy_loading = false;
% %             else
% %                 folder_names = folder_names(selected);
% %                 obj.data_series_controller.data_series.lazy_loading = false;
% %             end
            %
            [folder_names, ~, obj.data_series_controller.data_series.lazy_loading] = dataset_selection(folder_names);            
            %
            num_datasets = length(folder_names);
            %
            % find corresponding Image ids list...
            folder_ids = zeros(1,num_datasets);
            for m = 1:num_datasets
                iName_m = folder_names{m};
                for k = 0:imageList.size()-1,                       
                         iName_k = char(java.lang.String(imageList.get(k).getName().getValue()));
                         if strcmp(iName_m,iName_k)
                            folder_ids(1,m) = imageList.get(k).getId().getValue();
                            break;
                         end;
                end 
            end
            %                                    
            polarisation_resolved = false;            
            % load new dataset
            obj.data_series_controller.data_series = flim_data_series();            
            % currently only allow one channel to be loaded
            obj.selected_channel = obj.data_series_controller.data_series.request_channels(polarisation_resolved);
            
            %for i=1:4           %assume 4 channel TCSPC data for now
            %        chan_info{i} = ['sdt channel ' num2str(i)];
            %end
            % [obj.data_series.names,channel] = dataset_selection(chan_info);
                                                      
            image_descriptor{1} = obj.session;
            image_descriptor{2} = folder_ids(1);                        
            try
                [delays, data_cube, name] = OMERO_fetch(image_descriptor, obj.selected_channel);
            catch err
                 rethrow(err);
            end      
            data_size = size(data_cube);
            % if only one channel reshape to include singleton dimension
            if length(data_size) == 3
                data_size = [data_size(1) 1 data_size(2:3)];
            end
            clear('data_cube');
            %
            obj.data_series_controller.data_series.data_size = data_size;
            obj.data_series_controller.data_series.num_datasets = num_datasets;       
            %
            %set names
            obj.data_series_controller.data_series.names = cell(1,num_datasets);
            for j=1:num_datasets
                % need to remove extension - for sdt...
                string = strrep(folder_names{j},['.' extension],'');
                obj.data_series_controller.data_series.names{j} = string;
            end
            %        
            if size(delays) > 0 % we work with FLIM, right?
                if size(delays) > 32 % ????!!!!!!
                    obj.data_series_controller.data_series.mode = 'TCSPC'; 
                else
                    obj.data_series_controller.data_series.mode = 'Widefield';
                end
                %
                obj.data_series_controller.data_series.file_names = {'file'};
                obj.data_series_controller.data_series.channels = 1;
                obj.data_series_controller.data_series.metadata = extract_metadata(obj.data_series_controller.data_series.names);        
                obj.data_series_controller.data_series.polarisation_resolved = polarisation_resolved;
                obj.data_series_controller.data_series.t = delays;
                obj.data_series_controller.data_series.use_memory_mapping = false;
                obj.data_series_controller.data_series.load_multiple_channels = false; % YA
                %
                if obj.data_series_controller.data_series.lazy_loading        
                    obj.data_series_controller.data_series.load_selected_files_Omero(obj.session,folder_ids,1,obj.selected_channel);
                else
                    obj.data_series_controller.data_series.load_selected_files_Omero(obj.session,folder_ids,1:obj.data_series_controller.data_series.num_datasets,obj.selected_channel);        
                end    
                % ?
                obj.data_series_controller.data_series.switch_active_dataset(1);    
                % ?
                %obj.data_series_controller.data_series.init_dataset(dataset_indexting_file);                    
                obj.data_series_controller.data_series.init_dataset();            
            end
        end            
        
% %         %------------------------------------------------------------------        
% %         function menu_OMERO_Load_FLIM_Screen_callback(obj,~,~)
% %             %
% %             % that will be, WOW ...
% %             %
% %         end                    
% %         
% %         %------------------------------------------------------------------
% %         function menu_OMERO_Load_IRF_image_callback(obj,~,~)
% %             %
% %             % not sure
% %             obj.set_dataset_if_not_selected;            
% %             if isempty(obj.dataset) return; end;            
% %             %
% %         end            
        
        %------------------------------------------------------------------        
        function menu_OMERO_Load_IRF_annot_callback(obj,~,~)
            %
            obj.set_dataset_if_not_selected; 
            if isempty(obj.dataset) return; end;            
            %
            [str fname] = select_Annotation(obj.session, obj.dataset,'Please choose IRF file');
            %
            % can't do better for now..
            if strcmp('sdt',fname(numel(fname)-2:numel(fname)))
                errordlg('Loading native sdt IRFs not supported');
                return;
            end
            %
            if isempty(str)
                return;
            end;
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
                fwrite(fid,str,'*uint8');
            fclose(fid);
            %
            try
                obj.data_series_controller.data_series.load_irf(full_temp_file_name);
            catch e
                errordlg('error: menu_OMERO_Load_IRF_annot_callback');
                dislpay(e);
            end
            %
            delete(full_temp_file_name);
        end            
        
        %------------------------------------------------------------------
        function menu_OMERO_Load_Background_callback(obj,~,~)    
            %
            obj.set_dataset_if_not_selected;                         
            %
            if isempty(obj.dataset),
                warndlg('Operation not completed - Background image was not loaded','Warning');
                return;
            end;            
            %
            image = select_Image(obj.dataset);           
            if isempty(image) 
                warndlg('Operation not completed - Background image was not loaded','Warning');
                return;                                
            end
            %
            data_cube = get_Channels( obj.session, image.getId().getValue(), 1, 1 );            
            bckg_data = squeeze(data_cube);
            if 2 ~= numel(size(bckg_data))
                errordlg('single plane image is expected - can not complete Background image loading');
                return;
            end
            %
            fname = tempname;
            imwrite(bckg_data,fname,'tif');           
            %
            try
                obj.data_series_controller.data_series.load_background(fname);                          
            catch e
                errordlg('error: menu_OMERO_Load_Background_callback');                
                display(e);
            end
        end            
        
        %------------------------------------------------------------------        
        function menu_OMERO_Load_Time_Varying_Background_callback(obj,~,~)    
            %            
            obj.set_dataset_if_not_selected; 
            % etcetera
            %
        end            
        
        %------------------------------------------------------------------
        function menu_OMERO_Export_Fitting_Results_callback(obj,~,~)
            %
            % another way: first save results into intermed. directory, then transfer to
            % Omero?
            %
            if ~obj.fit_controller.has_fit
                 errordlg('There are no analysis results - nothing to Export');
                 return;
            end
                 %
                 obj.set_dataset_if_not_selected; 
                 %
                 res = obj.fit_controller.fit_result;
                 %
                 dName = char(java.lang.String(obj.dataset.getName().getValue()));
                    pName = char(java.lang.String(obj.project.getName().getValue()));
                        name = [ pName ' : ' dName ];
                 %
                 choice = questdlg(['Do you want to Export current results on ' name ' to OMERO? It might take some time.'], ...
                  'Export current analysis' , ...
                  'Export','Cancel','Cancel');
                 %  
                 switch choice
                     case 'Cancel'
                         return;
                 end            
                 %
                 current_dataset_name = char(java.lang.String(obj.dataset.getName().getValue()));    
                    new_dataset_name = [current_dataset_name ' FLIM fitting channel ' num2str(obj.selected_channel) ' '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
                        description  = ['analysis of the ' current_dataset_name ' at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
                            newdataset = create_new_Dataset(obj.session,obj.project,new_dataset_name,description);                                                                                                    
                 %
                 if isempty(newdataset)
                     errordlg('Can not create new Dataset');
                     return;
                 end
                 %
                 % get first parameter image just to get the size
                 params = res.fit_param_list();
                 n_params = length(params);
                 param_array(:,:) = single(res.get_image(1, params{1}));
                    sizeY = size(param_array,1);
                    sizeX = size(param_array,2);
                 %      
                 hw = waitbar(0, 'Exporting fitting results to Omero, please wait');                 
                 for dataset_index = 1:obj.data_series_controller.data_series.num_datasets
                     %
                     data = zeros(n_params,sizeX,sizeY);
                         for p = 1:n_params,
                            data(p,:,:) = res.get_image(dataset_index, params{p})';
                         end
                     %                  
                     new_image_description = ' ';
                     new_image_name = char(['FLIM fitting channel ' num2str(obj.selected_channel) ' ' obj.data_series_controller.data_series.names{dataset_index}]);
                     imageId = mat2omeroImage_Channels(obj.session, data, 'double', new_image_name, new_image_description, res.fit_param_list());
                         link = omero.model.DatasetImageLinkI;
                             link.setChild(omero.model.ImageI(imageId, false));
                                 link.setParent(omero.model.DatasetI(newdataset.getId().getValue(), false));
                                     obj.session.getUpdateService().saveAndReturnObject(link); 
                     %   
                     waitbar(dataset_index/obj.data_series_controller.data_series.num_datasets, hw);
                     drawnow;                                                                 
                 end;
                 delete(hw);
                 drawnow;                                          
            %
            % attach fitting options to results - including irf etc. ?
            %
        end            
        
        %------------------------------------------------------------------        
        function menu_OMERO_Export_Fitting_Settings_callback(obj,~,~)
            %
            [ dtst prjct ] = select_Dataset(obj.session,'Please select target Dataset:'); 
            if 0==dtst
                warndlg('Operation not completed - fitting settings were not exported','Warning');
                return;
            else
                obj.dataset = dtst;
                obj.project = prjct;
            end
            %                        
            fname = [tempdir 'fitting settings '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.xml'];
            obj.fitting_params_controller.save_fitting_params(fname);         
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            ret = add_Annotation(obj.session, ...
                            dtst, ...
                            sha1, ...
                            file_mime_type, ...
                            fname, ...
                            description, ...
                            namespace);               
        end            
        
        %------------------------------------------------------------------
        function menu_OMERO_Import_Fitting_Settings_callback(obj,~,~)
            %
            obj.set_dataset_if_not_selected; 
            %
            if isempty(obj.dataset),
                warndlg('Operation not completed - fitting settings were not imported','Warning');
                return;
            end;            
            %
            [str fname] = select_Annotation(obj.session, obj.dataset,'Please choose settings file');
            %
            if isempty(str)
                return;
            end;
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
                fwrite(fid,str,'*uint8');
            fclose(fid);
            %
            try
                obj.fitting_params_controller.load_fitting_params(full_temp_file_name);
            catch e
                errordlg('error: menu_OMERO_Import_Fitting_Settings_callback');
                display(e);
            end;
            %
            delete(full_temp_file_name);            
        end            
        
        %------------------------------------------------------------------                
        function set_dataset_if_not_selected(obj,~,~)
            if isempty(obj.dataset) 
                obj.menu_OMERO_Set_Dataset_callback;
                if isempty(obj.dataset) 
                    return;
                end;
            end;            
        end
       %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------                        

        
        
        
        
        
        
        
        
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
        
        
        function menu_file_import_plate_metadata_callback(obj,~,~)
            [file,path] = uigetfile({'*.xls;*.xlsx','Excel Files'},'Select the metadata file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.import_plate_metadata([path file]);
            end
        end
        
        
        %------------------------------------------------------------------
        % IRF
        %------------------------------------------------------------------
        function menu_irf_load_callback(obj,~,~)
            [file,path] = uigetfile('*.*','Select a file from the irf',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_irf([path file]);
                % obj.add_recent_irf([path file]); % ?!!
            end
        end
        
        function menu_irf_image_load_callback(obj,~,~)
            [file,path] = uigetfile('*.*','Select a file from the irf',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_irf([path file],true);
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
        
        function menu_irf_estimate_background_callback(obj,~,~)
            obj.data_series_controller.data_series.estimate_irf_background();
        end
        
        function menu_irf_estimate_t0_callback(obj,~,~)
            obj.data_masking_controller.t0_guess_callback();    
        end
        
        function menu_irf_estimate_g_factor_callback(obj,~,~)
            obj.data_masking_controller.g_factor_guess_callback();    
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
        
        function menu_background_background_load_series_callback(obj,~,~)
            [path] = uigetdir(obj.default_path,'Select a folder of background images');
            if path ~= 0
                obj.data_series_controller.data_series.load_background(path);    
            end
        end
        
        function menu_background_tvb_load_callback(obj,~,~)
            [file,path] = uigetfile('*.*','Select a TVB file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_tvb([path file]);    
            end
        end
        
        function menu_background_tvb_use_selected_callback(obj,~,~)
           obj.data_masking_controller.tvb_define_callback();    
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
                obj.data_series_controller.data_series.save_dataset_indextings(settings_file);
                batch_fit(folder,'widefield',settings_file,fit_params);
                if strcmp(obj.default_path,'C:\')
                    obj.default_path = path;
                end
            end
            
        end
        
        
        function menu_tools_photon_stats_callback(obj,~,~)
            d = obj.data_series_controller.data_series;
            data = d.cur_tr_data;
            seg = d.mask > 0;
            [N,Z] = determine_photon_stats(data(:,:,seg));
            disp(['N= ' num2str(N) ', Z = ' num2str(Z)]);
        end
        
        function menu_tools_estimate_irf_callback(obj,~,~)
            d = obj.data_series_controller.data_series;
            estimate_irf(d.tr_t_irf,d.tr_irf);
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
        
        function menu_test_unload_dll_callback(obj,~,~)
            if is64
                unloadlibrary('FLIMGlobalAnalysis_64');
            else
                unloadlibrary('FLIMGlobalAnalysis_32');
            end
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

        function menu_help_tracker_callback(obj, ~, ~)
            web('https://bitbucket.org/scw09/globalprocessing/issues','-browser');
        end

        function menu_help_bugs_callback(obj, ~, ~)
            web('https://bitbucket.org/scw09/globalprocessing/issues/new','-browser');
        end


    end
    
end
