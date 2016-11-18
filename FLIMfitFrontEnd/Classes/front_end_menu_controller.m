classdef front_end_menu_controller < handle
    
    
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
        
        %%%%%%%%%%%%%%%%%%%%%%% OMERO                
        
        menu_login;
        
        menu_OMERO_Set_Dataset;        
        menu_OMERO_Set_Plate;        
        menu_OMERO_Load_FLIM_Data;
        menu_OMERO_Load_FLIM_Dataset; 
        menu_OMERO_Load_plate;
        menu_OMERO_Load_irf; 
        menu_OMERO_Load_sv_irf;
        menu_OMERO_Load_Background;            
        %menu_OMERO_Export_Fitting_Results;    
       
        menu_OMERO_Reset_Logon;  
        menu_OMERO_Load_Background_average;
        menu_OMERO_Switch_User;
            
        menu_OMERO_Working_Data_Info;
        menu_OMERO_Load_tvb
         
        menu_OMERO_Load_FLIM_Dataset_Polarization;
        
        menu_OMERO_save_data_settings;
        menu_OMERO_load_data_settings;
        
        menu_OMERO_export_fit_params;
        menu_OMERO_import_fit_params;
        
        menu_OMERO_Connect_To_Another_User;    
        menu_OMERO_Connect_To_Logon_User;    
        
        %menu_OMERO_Import_Fitting_Results;
        
        omero_logon_manager;     
        
        
        menu_OMERO_load_acceptor;
        
        menu_OMERO_export_fit_table;
        menu_OMERO_export_plots;
        menu_OMERO_export_hist_data;
        
        
        %%%%%%%%%%%%%%%%%%%%%%% OMERO                        
                        
        menu_file_new_window;
        
        menu_file_load_single;
        menu_file_load_widefield;
        menu_file_load_tcspc;
        menu_file_load_plate;
        
        menu_file_load_single_pol;
        menu_file_load_tcspc_pol;
        
        menu_file_load_acceptor;
        menu_file_export_acceptor;
        menu_file_import_acceptor;
        
        menu_file_reload_data;
        
        menu_file_save_dataset;
        menu_file_save_raw;
        menu_file_save_magic_angle_raw;
        
        menu_file_export_decay;
        menu_file_export_decay_series;
        
        menu_file_set_default_path;
        menu_file_recent_default
        
        menu_file_load_raw;
        
        menu_file_load_data_settings;
        menu_file_save_data_settings;
        
        menu_file_load_t_calibration;
        menu_OMERO_import;
        
        menu_file_open_fit;
        menu_file_save_fit;
        
        menu_file_export_plots;
        menu_file_export_hist_data;
        
        menu_file_import_plate_metadata;
        
        menu_file_export_fit_table;
        
        menu_file_import_fit_params;
        menu_file_export_fit_params;
        
        menu_file_import_fit_results;
        menu_file_export_fit_results;
        
        menu_file_import_exclusion_list;
        menu_file_export_exclusion_list;
        
        menu_file_export_intensity;
            
        menu_file_exit;
        
        % icy..
        menu_file_export_volume_to_icy;
        menu_file_export_volume_as_OMEtiff;
        menu_file_export_volume_batch;
        
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
        menu_background_background_load_average;
        %menu_background_background_load_series;
        
        menu_background_tvb_load;
        menu_background_tvb_use_selected;
        
        menu_segmentation_manual;
        menu_segmentation_yuriy;
        
        menu_tools_photon_stats;
        menu_tools_estimate_irf;
        menu_tools_create_irf_shift_map;
        menu_tools_create_tvb_intensity_map;
        menu_tools_fit_gaussian_irf;
        menu_tools_preferences;
                
        menu_test_test1;
        menu_test_test2;
        menu_test_test3;
        menu_test_unload_dll;
        
        menu_help_about;
        menu_help_bugs;
        menu_help_tracker;
        menu_help_check_version;
        
        menu_batch_batch_fitting;
        
        data_series_list;
        data_series_controller;
        data_decay_view;
        fit_controller;
        fitting_params_controller;
        plot_controller;
        hist_controller;
        data_masking_controller;
        
        recent_irf;
        recent_default_path;

        platform_default_path; 
        default_path;
        window;

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
                if ispc
                    obj.platform_default_path = 'C:';
                else
                    obj.platform_default_path = '';
                end
                addpref('GlobalAnalysisFrontEnd','DefaultFolder',obj.platform_default_path)
                obj.default_path = obj.platform_default_path;
            end
            
            try
                obj.recent_data = getpref('GlobalAnalysisFrontEnd','RecentData');
            catch 
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
            
        end
        
        function set_callbacks(obj)
            
             mc = metaclass(obj);
             obj_prop = mc.Properties;
             obj_method = [mc.Methods{:}];
             
             
             % Search for properties with corresponding callbacks
             for i=1:length(obj_prop)
                prop = obj_prop{i}.Name;
                if strncmp(prop,'menu_',5)
                    method = [prop '_callback'];
                    matching_methods = findobj(obj_method,'Name',method);
                    if ~isempty(matching_methods)  
                        fcn = eval(['@obj.' method]);
                        set(obj.(prop),'Callback',@(x,y) escaped_callback(x,y,fcn));
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
        function menu_file_new_window_callback(obj)
            FLIMfit();
        end
        
        %------------------------------------------------------------------
        % Default Path
        %------------------------------------------------------------------
        function menu_file_set_default_path_callback(obj)
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
        
        function menu_file_exit_callback(obj)
           
            if isdeployed
                exit()
            else
                close(obj.window)
            end
            
        end
                
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------
        function menu_login_callback(obj)
            obj.omero_logon_manager.Omero_logon();
            
            if ~isempty(obj.omero_logon_manager.session)
                props = properties(obj);
                OMERO_props = props( strncmp('menu_OMERO',props,10) );
                for i=1:length(OMERO_props) 
                    set(obj.(OMERO_props{i}),'Enable','on');
                end
            end
            
        end
        %------------------------------------------------------------------
        function menu_OMERO_Set_Dataset_callback(obj)            
            infostring = obj.omero_logon_manager.Set_Dataset();
            if ~isempty(infostring)
                set(obj.menu_OMERO_Working_Data_Info,'Label',infostring,'ForegroundColor','blue');
            end;
        end                        
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Data_callback(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, true);
            images = chooser.getSelectedImages();
            clear chooser;
            if images.length > 0
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                % NB misnomer "load_single" retained for compatibility with
                % file-side
                obj.data_series_controller.data_series = OMERO_data_series();
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;
                obj.data_series_controller.load_single(images);
                notify(obj.data_series_controller,'new_dataset');
            end
        end                                  
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Dataset_callback(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(1));
            dataset = chooser.getSelectedDataset();
            clear chooser;
            if ~isempty(dataset)
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = OMERO_data_series();   
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;  
                obj.data_series_controller.load_data_series(dataset,''); 
                notify(obj.data_series_controller,'new_dataset');
            end   
        end    
        %------------------------------------------------------------------        
        function menu_OMERO_Load_plate_callback(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(2));
            plate = chooser.getSelectedPlate();
            clear chooser;
            if ~isempty(plate)
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = OMERO_data_series();   
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;  
                obj.data_series_controller.load_plate(plate); 
                obj.data_series_controller.data_series.plateId = plate.getId().getValue();
                notify(obj.data_series_controller,'new_dataset');
            end
        end  
                    
        %------------------------------------------------------------------
        function menu_OMERO_Load_irf_callback(obj)
            
            [image, selected] = obj.load_image_or_attachment;
           
            if ~isempty(image)
                  load_as_image = false;
                  obj.data_series_controller.data_series.load_irf(image,load_as_image);
            else
                if ~isempty(selected)
                    obj.data_series_controller.data_series.load_irf(selected);
                    if isa(selected,char)
                        delete(selected);
                    end
                end
            end
        end
    
        %------------------------------------------------------------------
        function [image, file] = load_image_or_attachment(obj)
            % common functionality for OMERO_load_irf load 
            % and OMERO_load_tvb
            
            images = [];
            image = [];
            file = [];
            fullpath = [];
                            
            dId = obj.data_series_controller.data_series.datasetId;
            pId = obj.data_series_controller.data_series.plateId;
            
            if pId > 0
                % plate so attachment only 
                chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(7), java.lang.Long(pId));
                selected = chooser.getSelectedFile();
            else
                chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(8),java.lang.Long(dId));
                images = chooser.getSelectedImages();
                selected = chooser.getSelectedFile();
            end
            clear chooser;
            if images.length == 1
                  image = images(1);
            else
                if ~isempty(selected)
                    
                     fname = char(selected.getName().getValue());
                     [path,name,ext] = fileparts_inc_OME(fname);
                    
                    % NB marshal-object is overloaded in OMERO_data_series 
                    % load_irf etc use marshal_object for .xml files so 
                    % simply return selected file
                    
                    if strcmp(ext,'.xml')
                        file = selected;
                    else 
                        fullpath  = [tempdir fname];
                        getOriginalFileContent(obj.omero_logon_manager.session, selected, fullpath);
                        file = fullpath;
                    end
                end
            end
          end                    
        %------------------------------------------------------------------
        function menu_OMERO_Load_sv_irf_callback(obj)
            images = [];
            dId = obj.data_series_controller.data_series.datasetId;
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(0),java.lang.Long(dId));
            images = chooser.getSelectedImages();
            clear chooser;
            if images.length == 1
                  load_as_image = true;
                  obj.data_series_controller.data_series.load_irf(images(1),load_as_image)
            end  
        end
        %------------------------------------------------------------------
        function menu_OMERO_Load_Background_callback(obj)                                     
            dId = obj.data_series_controller.data_series.datasetId;
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, java.lang.Long(dId));
            images = chooser.getSelectedImages();
            if images.length == 1
                obj.data_series_controller.data_series.load_background(images(1), false)
            end
            clear chooser;                     
        end                            
        %------------------------------------------------------------------
         function menu_OMERO_Load_Background_average_callback(obj)                                     
            dId = obj.data_series_controller.data_series.datasetId;
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, java.lang.Long(dId) );
            images = chooser.getSelectedImages();
            if images.length == 1
                obj.data_series_controller.data_series.load_background(images(1),true)
            end
            clear chooser;                     
        end  
                          
       
        %------------------------------------------------------------------        
        function menu_OMERO_Reset_Logon_callback(obj)
            obj.omero_logon_manager.Omero_logon();
        end
       
        
        %------------------------------------------------------------------                
        function menu_OMERO_Switch_User_callback(obj)
            obj.omero_logon_manager.Omero_logon();
        end    
        
        %------------------------------------------------------------------
        function menu_OMERO_Load_tvb_callback(obj)
            
            [image, selected] = obj.load_image_or_attachment;
           
            if ~isempty(image)
                  load_as_image = false;
                  obj.data_series_controller.data_series.load_tvb(image);
            else
                if ~isempty(selected)
                    obj.data_series_controller.data_series.load_tvb(selected);
                    if isa(selected,char)
                        delete(selected);
                    end
                end
            end
        end
    
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Dataset_Polarization_callback(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(1));
            dataset = chooser.getSelectedDataset();
            clear chooser;
            if ~isempty(dataset)
                    if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = OMERO_data_series();   
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;  
                obj.data_series_controller.load_data_series(dataset,'',true); 
                notify(obj.data_series_controller,'new_dataset');
            end
            
            
        end             
                          
        %------------------------------------------------------------------
        function menu_OMERO_load_data_settings_callback(obj)
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(6));
            selected = chooser.getSelectedFile();
            clear chooser;
            if ~isempty(selected)
                 fname = char(selected.getName().getValue());
                 [path,name,ext] = fileparts_inc_OME(fname);
                  if strcmp(ext,'.xml')
                      obj.data_series_controller.data_series.load_data_settings(fname);
                  else
                      errordlg('Please select a .xml file')
                  end
            end
        end                                            
                                          
        %------------------------------------------------------------------
        function menu_OMERO_Connect_To_Another_User_callback(obj)
            obj.omero_logon_manager.Select_Another_User();
            %set(obj.menu_OMERO_Working_Data_Info,'Label','Working Data have not been set up','ForegroundColor','red');
        end                            
        %------------------------------------------------------------------
        function menu_OMERO_Connect_To_Logon_User_callback(obj)            
            obj.omero_logon_manager.userid = obj.omero_logon_manager.session.getAdminService().getEventContext().userId;
            obj.omero_logon_manager.project = [];
            obj.omero_logon_manager.dataset = [];
            obj.omero_logon_manager.screen = [];
            obj.omero_logon_manager.plate = [];
            %set(obj.menu_OMERO_Working_Data_Info,'Label','Working Data have not been set up','ForegroundColor','red');
        end                            
        %------------------------------------------------------------------                
        function menu_OMERO_Import_Fitting_Results_callback(obj)  
            obj.data_series_controller.data_series.clear();    % ensure delete if multiple handles
            obj.data_series_controller.data_series = OMERO_data_series();
            obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;
            infostring = obj.data_series_controller.data_series.load_fitted_data(obj.fit_controller);
            %if ~isempty(infostring)
            %    set(obj.menu_OMERO_Working_Data_Info,'Label',infostring,'ForegroundColor','blue');            
            %end;            
        end                                    
        %------------------------------------------------------------------                
        function menu_OMERO_load_acceptor_callback(obj)
            obj.omero_logon_manager.Load_Acceptor_Images(obj.data_series_controller.data_series);
        end
        %------------------------------------------------------------------                
        function menu_OMERO_export_acceptor_callback(obj)
            obj.omero_logon_manager.Export_Acceptor_Images(obj.data_series_controller.data_series);
        end
                
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------                                
                                        
        %------------------------------------------------------------------
        % Load Data
        %------------------------------------------------------------------
        function menu_file_load_single_callback(obj)
            
            [files,path] = uigetfile('*.*','Select a file from the data',obj.default_path,'MultiSelect','on'); 
            if ~iscell(files) 
                if files == 0
                    return;
                end
            end
            % clear & delete existing data series 
            if isvalid(obj.data_series_controller.data_series)
                obj.data_series_controller.data_series.clear();
            end
            obj.data_series_controller.data_series = flim_data_series();
            obj.data_series_controller.load_single([path files]); 
            if strcmp(obj.default_path,obj.platform_default_path)
                obj.default_path = path;
            end
            
            
            %[file,path] = uigetfile('*.*','Select a file from the data',obj.default_path);
            %if file ~= 0
            %    obj.data_series_controller.data_series = flim_data_series();
            %    obj.data_series_controller.load_single([path file]); 
            %    if strcmp(obj,default_path,obj.platform_default_path)
            %        obj.default_path = path;
            %    end
            %end
        end
        
        function menu_file_load_widefield_callback(obj)
            
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                % clear & delete existing data series 
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = flim_data_series();
                obj.data_series_controller.load_data_series(folder,'tif-stack'); 
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_load_tcspc_callback(obj)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = flim_data_series();
                obj.data_series_controller.load_data_series(folder,'bio-formats');
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
        end
        
        
        function menu_file_load_plate_callback(obj)
            
            [file,path] = uigetfile('*.ome.tiff;*.OME.tiff;*.ome.tif;;*.OME.tif','Select an ome.tiff containing plate data',obj.default_path);
            if file ~= 0
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = flim_data_series();
                obj.data_series_controller.load_plate([path file]); 
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_load_single_pol_callback(obj)
            [file,path] = uigetfile('*.*','Select a file from the data',obj.default_path);
            if file ~= 0
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = flim_data_series();
                obj.data_series_controller.load_single([path file],true); 
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
                end
        
        function menu_file_load_tcspc_pol_callback(obj)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = flim_data_series();
                obj.data_series_controller.load_data_series(folder,'bio-formats',true);
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
        end
        
        function menu_file_reload_data_callback(obj)
            obj.data_series_controller.data_series.reload_data;
        end
        
        function menu_file_load_acceptor_callback(obj)
            folder = uigetdir(obj.default_path,'Select the folder containing the acceptor images');
            if folder ~= 0
                obj.data_series_controller.data_series.load_acceptor_images(folder);
            end
        end
        
        function menu_file_import_acceptor_callback(obj)
            [file path] = uigetfile({'*.tiff'},'Select the exported acceptor image file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_acceptor_images([path file]);
            end
        end
        
        function menu_file_export_acceptor_callback(obj)
            [file path] = uiputfile({'*.tiff'},'Select exported acceptor image file name',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.export_acceptor_images([path file]);
            end
        end
        
        %------------------------------------------------------------------
        % Export Data Settings
        %------------------------------------------------------------------
        function menu_file_save_data_settings_callback(obj)
            [filename, pathname] = uiputfile({'*.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_settings([pathname filename]);         
            end
        end
        
         function menu_OMERO_save_data_settings_callback(obj)
          
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.xml');
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_settings(filename, dataset);         
            end
        end
        
        
        function menu_file_load_data_settings_callback(obj)
            [filename, pathname] = uigetfile({'*.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.load_data_settings([pathname filename]);         
            end
        end
        
        function menu_OMERO_import_callback(obj)
            
            obj.data_series_controller.data_series.clear();    % ensure delete if multiple handles
            obj.data_series_controller.data_series = OMERO_data_series();
            obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;
            default_name = '';
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(1));
            dataset = chooser.getSelectedDataset();
            [filename,pathname] = uigetfile('*.*','Select file for import then DELETION!');
            
            if filename ~= 0
                before_list = [];
                obj.data_series_controller.data_series.export_new_images(pathname,filename ,before_list, dataset);
            end
        end
        
        function menu_file_load_t_calibration_callback(obj)
            [filename, pathname] = uigetfile({'*.csv', 'CSV File (*.csv)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.load_t_calibriation([pathname filename]);         
            end
        end

        %------------------------------------------------------------------
        % Export Data
        %------------------------------------------------------------------
        function menu_file_save_dataset_callback(obj)
            [filename, pathname] = uiputfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_series([pathname filename]);         
            end
        end
        
        function menu_file_save_raw_callback(obj)
            [filename, pathname] = uiputfile({'*.raw', 'Raw File (*.raw)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_raw_data([pathname filename]);         
            end
        end
        
        function menu_file_save_magic_angle_raw_callback(obj)
            [filename, pathname] = uiputfile({'*.raw', 'Raw File (*.raw)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_magic_angle_raw([pathname filename]);         
            end
        end
            
        function menu_file_load_raw_callback(obj)
            [filename, pathname] = uigetfile({'*.raw', 'Raw File (*.raw)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_series_controller.load_raw([pathname filename]);         
            end
        end
        
        %------------------------------------------------------------------
        % Export Decay
        %------------------------------------------------------------------
        function menu_file_export_decay_callback(obj)
            [filename, pathname] = uiputfile({'*.txt', 'TXT File (*.txt)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.data_decay_view.update_display([pathname filename]);
            end
        end
        
        function menu_file_export_decay_series_callback(obj)
            [filename, pathname] = uiputfile({'*.txt', 'TXT File (*.txt)'},'Select file postfix',obj.default_path);
            if filename ~= 0
                obj.data_decay_view.update_display([pathname filename],'all');
            end
        end
        
        %------------------------------------------------------------------
        % Import/Export Fit Results
        %------------------------------------------------------------------
        function menu_file_export_fit_results_callback(obj)
            [filename, pathname] = uiputfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fit_controller.save_fit_result([pathname filename]);         
            end
        end

        function menu_file_import_fit_results_callback(obj)
            [filename, pathname] = uigetfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fit_controller.load_fit_result([pathname filename]);           
            end
        end
        
        function menu_file_export_intensity_callback(obj)
            folder = uigetdir(obj.default_path);
            obj.data_series_controller.data_series.export_intensity_images(folder);
        end
        
        %------------------------------------------------------------------
        % Import/Export Fit Parameters
        %------------------------------------------------------------------
        function menu_file_export_fit_params_callback(obj)
            [filename, pathname, dataset] = uiputfile({'fit_parameters.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fitting_params_controller.save_fitting_params([pathname filename]);         
            end
        end

        function menu_file_import_fit_params_callback(obj)
            [filename, pathname] = uigetfile({'*.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fitting_params_controller.load_fitting_params([pathname filename]);           
            end
        end
        
        function menu_OMERO_export_fit_params_callback(obj)
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('root filename', 'fit_parameters', '.xml');
            if filename ~= 0
                obj.fitting_params_controller.save_fitting_params([pathname filename]);         
                add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                            dataset, ...
                            char('application/octet-stream'), ...
                            [pathname filename], ...
                            '', ...
                            'IC_PHOTONICS');  
            end
        end
        
        function menu_OMERO_import_fit_params_callback(obj)
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(6));
            selected = chooser.getSelectedFile();
            clear chooser;
            if ~isempty(selected)
                fname = char(selected.getName().getValue());
                [path,name,ext] = fileparts_inc_OME(fname);
                
                if ~strcmp(ext,'.xml')
                    errordlg('Plese select a .xml file!');
                    return;
                end;
                
                fullpath  = [tempdir fname];
                getOriginalFileContent(obj.omero_logon_manager.session, selected, fullpath);
                obj.fitting_params_controller.load_fitting_params(fullpath); 
                delete(fullpath);
               
            end
        end       
        
        %------------------------------------------------------------------
        % Export Fit Table
        %------------------------------------------------------------------
        function menu_file_export_fit_table_callback(obj)
            [filename, pathname] = uiputfile({'*.csv', 'CSV File (*.csv)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.fit_controller.save_param_table([pathname filename]);
            end
        end
        
        function menu_OMERO_export_fit_table_callback(obj)
            
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.csv');
            if filename ~= 0
                obj.fit_controller.save_param_table([pathname filename]);         
                add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                            dataset, ...
                            char('application/octet-stream'), ...
                            [pathname filename], ...
                            '', ...
                            'IC_PHOTONICS');  
            end
        end
        
        
   
        function menu_file_import_plate_metadata_callback(obj)
            [file,path] = uigetfile({'*.xls;*.xlsx;*.csv','All Compatible Files';'*.xls;*.xlsx','Excel Files';'*.csv','CSV File'},'Select the metadata file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.import_plate_metadata([path file]);
            end
        end
        
        
        function menu_file_import_exclusion_list_callback(obj)
            [file,path] = uigetfile({'*.txt','Text Files'},'Select the exclusion file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.import_exclusion_list([path file]);
            end
        end
        
        function menu_file_export_exclusion_list_callback(obj)
            [file,path] = uiputfile({'*.txt','Text Files'},'Select the exclusion file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.export_exclusion_list([path file]);
            end
        end
        
        %------------------------------------------------------------------
        % IRF
        %------------------------------------------------------------------
        function menu_irf_load_callback(obj)
            [file,path] = uigetfile('*.*','Select a file from the irf',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_irf([path file]);
                % obj.add_recent_irf([path file]); % ?!!
            end
        end
        
        function menu_irf_image_load_callback(obj)
            [file,path] = uigetfile('*.*','Select a file from the irf',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_irf([path file],true);
            end
        end
        
        function menu_irf_set_delta_callback(obj)
            obj.data_series_controller.data_series.set_delta_irf();
        end
        
        function menu_irf_set_rectangular_callback(obj)
            width = inputdlg('IRF Width','IRF Width',1,{'500'});
            width = str2double(width);
            obj.data_series_controller.data_series.set_rectangular_irf(width);
        end
        
        function menu_irf_set_gaussian_callback(obj)
            width = inputdlg('IRF Width','IRF Width',1,{'500'});
            width = str2double(width);
            obj.data_series_controller.data_series.set_gaussian_irf(width);
        end
        
        function menu_irf_estimate_background_callback(obj)
            obj.data_series_controller.data_series.estimate_irf_background();
        end
        
        function menu_irf_estimate_t0_callback(obj)
            obj.data_masking_controller.t0_guess_callback();    
        end
        
        function menu_irf_estimate_g_factor_callback(obj)
            obj.data_masking_controller.g_factor_guess_callback();    
        end
        
        
        %------------------------------------------------------------------
        % Background
        %------------------------------------------------------------------
        function menu_background_background_load_callback(obj)
            [file,path] = uigetfile('*.*','Select a background file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file], false);    
            end
        end
        
        function menu_background_background_load_average_callback(obj)
            [file,path] = uigetfile('*.*','Select a background file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file], true);    
            end
        end
        
       
        function menu_background_tvb_load_callback(obj)
            [file,path] = uigetfile('*.*','Select a TVB file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_tvb([path file]);    
            end
        end
        
        function menu_background_tvb_I_map_load_callback(obj)
            [file,path] = uigetfile('*.xml','Select a TVB intensity map file',obj.default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_background([path file]);    
            end
        end
        
        function menu_background_tvb_use_selected_callback(obj)
           obj.data_masking_controller.tvb_define_callback();    
        end
        
        
        %------------------------------------------------------------------
        % Segmentation
        %------------------------------------------------------------------
        function menu_segmentation_yuriy_callback(obj)
            segmentation_manager(obj.data_series_controller);
        end
        
        %------------------------------------------------------------------
        % Batch Fit
        %------------------------------------------------------------------
        function menu_batch_batch_fitting_callback(obj)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                settings_file = tempname;
                fit_params = obj.fitting_params_controller.fit_params;
                obj.data_series_controller.data_series.save_dataset_indextings(settings_file);
                batch_fit(folder,'widefield',settings_file,fit_params);
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
            
        end
        
        
        function menu_tools_photon_stats_callback(obj)
            d = obj.data_series_controller.data_series;
            
            % get data without smoothing
            d.compute_tr_data(false,true);
            
             data = d.cur_tr_data;
            [N,Z] = determine_photon_stats(data);
            
            d.counts_per_photon = N;
            d.background_value = d.background_value + Z;
            
            d.compute_tr_data(true,true);

        end

        function menu_tools_preferences_callback(obj)
            profile = profile_controller();
            profile.set_profile();
        end

        
        function menu_tools_estimate_irf_callback(obj)
            d = obj.data_series_controller.data_series;
            estimate_irf(d.tr_t_irf,d.tr_irf);
        end
        
        
        %------------------------------------------------------------------
        % Views
        %------------------------------------------------------------------
        
        function menu_view_chi2_display_callback(obj)
            chi2_display(obj.fit_controller);
        end
        
        function menu_test_test1_callback(obj)
            regression_testing(obj);
            %polarisation_testing(obj.data_series_controller.data_series,obj.default_path);
        end
        
        
        function menu_tools_create_irf_shift_map_callback(obj)
                        
            mask=obj.data_masking_controller.roi_controller.roi_mask;
            t0_data = obj.data_series_controller.data_series.generate_t0_map(mask,1);
            
            OMEROsave = false;
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series')                
                choice = questdlg('Do you want to export t0 shift data to the current OMERO server or save on disk?', ' ', ...
                                        'Omero' , ...
                                        'disk','Cancel','Cancel');  
                if strcmp( choice, 'Cancel'), return, end; 
                if strcmp( choice, 'Omero')
                    [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.xml');
                    OMEROsave = true;
                end    
            end
            
            if ~OMEROsave
                [filename, pathname] = uiputfile({'*.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            end                                                               
            if filename ~= 0
                serialise_object(t0_data,[pathname filename],'flim_data_series');
                if OMEROsave
                    add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                        dataset, ...
                        char('application/octet-stream'), ...
                        [pathname filename], ...
                        '', ...
                        'IC_PHOTONICS');
                end
            end
                        
        end
        
        function menu_tools_fit_gaussian_irf_callback(obj)

            fh = figure(100);
            set(fh,'Name','Estimate Gaussian IRF','NumberTitle','off');
            ax = axes();
           
            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = mean(double(data),3);
            
            for i=1:size(data,2)
                [irf(:,i), t_final] = FitGaussianIRF(t,data(:,i),T,ax);
            end

            dat = table();
            dat.t = t_final;
            for i=1:size(irf,2)
                dat.(['irf_ch' num2str(i)]) = irf(:,i);
            end
            
            [file, path] = uiputfile({'*.csv', 'CSV File (*.csv)'},'Select file name',obj.default_path);
            if file~=0
                writetable(dat,[path file]);
            end
            
            close(fh);
            
        end
        
        function menu_tools_create_tvb_intensity_map_callback(obj)

            mask=obj.data_masking_controller.roi_controller.roi_mask;
            tvb_data = obj.data_series_controller.data_series.generate_tvb_I_map(mask,1);  
            
            OMEROsave = false;
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series')                
                choice = questdlg('Do you want to export t0 shift data to the current OMERO server or save to disk?', ' ', ...
                                        'Omero' , ...
                                        'disk','Cancel','Cancel');  
                if strcmp( choice, 'Cancel'), return, end; 
                if strcmp( choice, 'Omero')
                    [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.xml');
                    OMEROsave = true;
                end   
            end
            
            if ~OMEROsave
                [filename, pathname] = uiputfile({'*.xml', 'XML File (*.xml)'},'Select file name',obj.default_path);
            end                                                                  
            if filename ~= 0
                serialise_object(tvb_data,[pathname filename],'flim_data_series');
                if OMEROsave
                    add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                        dataset, ...
                        char('application/octet-stream'), ...
                        [pathname filename], ...
                        '', ...
                        'IC_PHOTONICS');
                end
            end
        end

  
        function menu_test_test2_callback(obj)
            
            d = obj.data_series_controller.data_series;

            tr_acceptor = zeros(size(d.acceptor));

            [optimizer, metric] = imregconfig('multimodal'); 
            optimizer.MaximumIterations = 40;
            h = waitbar(0,'Aligning...');

            for i=1:d.n_datasets
            
                a = d.acceptor(:,:,i);
                intensity = d.integrated_intensity(i);
                %try
                    t = imregtform(a,intensity,'rigid',optimizer,metric);
                    dx = t.T(3,1:2);
                    dx = norm(dx);
                    disp(dx);
                    
                    if dx>200
                        tr = a;
                    else
                        tr = imwarp(a,t,'OutputView',imref2d(size(intensity)));
                    end

                %catch e
                %    tr = a;
                %end
                
                tr_acceptor(:,:,i) = tr;
                
                figure(13);
                
                subplot(1,2,1)
                a = a - min(a(:));
                im(:,:,1) = a ./ max(a(:));
                im(:,:,2) = intensity ./ max(intensity(:));
                im(:,:,3) = 0;
                
                im(im<0) = 0;
                
                imagesc(im);
                daspect([1 1 1]);
                set(gca,'XTick',[],'YTick',[]);
                title('Before Alignment');
                

                subplot(1,2,2)
                tr = tr - min(tr(:));
                im(:,:,1) = tr ./ max(tr(:));
                im(:,:,2) = intensity ./ max(intensity(:));
                im(:,:,3) = 0;
                
                im(im<0) = 0;
                
                imagesc(im);
                daspect([1 1 1]);
                set(gca,'XTick',[],'YTick',[]);
                title('After Alignment');
                
                waitbar(i/d.n_datasets,h);
            end
            
            global acceptor;
            acceptor = tr_acceptor;
            %save('C:\Users\scw09\Documents\00 Local FLIM Data\2012-10-17 Rac COS Plate\acceptor_images.mat','acceptor');
            close(h);            
            
        end
        
        function menu_test_test3_callback(obj)
            
            d = obj.data_series_controller.data_series;
            
            
            images = d.acceptor;
            names = d.names;
            description = 'Acceptor';
            file = 'c:\users\scw09\documents\acceptor.tiff';
            
            %SaveFPTiffStack(file,images,names,description)
            
            %return ;
            
            l_images = ReadSelectedFromTiffStack(file,names,description);
            
            %file = 'c:\users\scw09\documents\data_serialization.h5';
            
            %obj.data_series_controller.data_series.serialize(file);
            
            %{
            global fg fh;
            r = obj.fit_controller.fit_result;
            
            im = r.get_image(1,'tau_1');
            I = r.get_image(1,'I');
            dim = 2;
            color = {'b', 'r', 'm', 'g', 'k'};
            s = nanstd(im,0,dim);
            m = nanmean(im,dim);
            I = nanmean(I,dim);
            figure(fg);
            hold on;
            fh(end+1) = plot(s,color{length(fh)+1});
            ylim([0 500]);
            %}
        end
        
        
        function menu_test_unload_dll_callback(obj)
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
                         '*.eps','EPS image (*.eps)';...
                         '*.fig','Matlab figure (*.fig)'},...
                         'Select root file name',[obj.default_path filesep 'fit']);

            if filename ~= 0
                obj.plot_controller.update_plots([pathname filename])
            end
        end
        
        function menu_OMERO_export_plots_callback(obj, ~, ~)
            
            if strcmp(class(obj.data_series_controller.data_series),'flim_data_series')
                errordlg('Not yet implemented for data not loaded from OMERO!');
                return;
            end 
            
            default_name = [char(obj.omero_logon_manager.dataset.getName().getValue() ) 'fit'];
            [filename, pathname, dataset, before_list] = obj.data_series_controller.data_series.prompt_for_export('root filename', default_name, '.tiff');
            obj.plot_controller.update_plots([pathname filename]);
            obj.data_series_controller.data_series.export_new_images(pathname,filename,before_list, dataset);
            
        end
        
        function menu_file_export_hist_data_callback(obj, ~, ~)
            
            [filename, pathname] = uiputfile({'*.txt', 'Text File (*.txt)'},'Select file name',obj.default_path);
            if filename ~= 0
                obj.hist_controller.export_histogram_data([pathname filename]);
            end
        end
        
        function menu_OMERO_export_hist_data_callback(obj)
            
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('root filename', '', '.txt');
            if filename ~= 0
                fname = obj.hist_controller.export_histogram_data([pathname filename]);
                add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                    dataset, ...
                    char('application/octet-stream'), ...
                    fname, ...
                    '', ...
                    'IC_PHOTONICS');
            end
        end
        
        function menu_help_about_callback(obj, ~, ~)
            ver = obj.data_series_controller.version;
            HelpAbout('Property', ver); 
        end

        function menu_help_tracker_callback(obj, ~, ~)
            
            obj.open_browser('https://github.com/imperial-photonics/FLIMfit/issues');
            
        end

        function menu_help_bugs_callback(obj, ~, ~)
            obj.open_browser('https://github.com/imperial-photonics/FLIMfit/issues/new'); 
        end
        
        function menu_help_check_version_callback(obj, ~, ~)
            check_version();
        end
        
        function open_browser(~, url_str)
            % cut down web function to open a web  browser without HelpUtils
            
            stat = -1; %default
            
            if ismac
                 % We can't detect system errors on the Mac, so the warning options are unnecessary.
                unix(['open ' url_str]);
                stat = 0;
       
            elseif isunix
                
                errordlg('Sorry! - not currently available for Linux/Unix', 'Browser Error')
            
            elseif ispc
                stat = dos(['cmd.exe /c rundll32 url.dll,FileProtocolHandler "' url_str '"']);
            end
            
            if stat ~= 0
                errordlg(horzcat('Failed to open browser! Please direct a browser to ', url_str ),'Browser Error');
                
            end
                        
        end
        
        function menu_file_export_volume_to_icy_callback(obj)
            try
                obj.export_volume('send to Icy');            
            catch
                errordlg('error - there might be no fitted data');
            end
        end

        function menu_file_export_volume_as_OMEtiff_callback(obj)
            try
                obj.export_volume('save as OME.tiff');            
            catch
                errordlg('error - there might be no fitted data');
            end
            
        end
                
        function export_volume(obj,mode,~)            
                        
            n_planes = obj.data_series_controller.data_series.n_datasets;
            
            params = obj.fit_controller.fit_result.fit_param_list();                        
            
            param_array(:,:) = obj.fit_controller.get_image(1, params{1});                                    
            sizeY = size(param_array,1);
            sizeX = size(param_array,2);                                        

            params_extended = [params 'I_mean_tau_chi2'];
            
            [param,v] = listdlg('PromptString','Choose fitted parameter',...
                'SelectionMode','single',...
                'ListSize',[150 200],...                                        
                'ListString',params_extended);                                    
            if (~v), return, end;
            
            full_filename = obj.data_series_controller.data_series.file_names{1};
            file_name = 'xxx ';
            if ischar(full_filename)
                C = strsplit(full_filename,filesep);
                file_name = char(C(length(C)));
            else % omero                
                image = obj.data_series_controller.data_series.file_names{1};
                file_name = char(image.getName.getValue);               
            end
            
            file_name = ['FLIMfit result ' params_extended{param} ' ' file_name];
            
            % usual way
            if param <= length(params)
                volm = zeros(sizeX,sizeY,n_planes,'single');
                for p = 1 : n_planes                
                    plane = obj.fit_controller.get_image(p,params{param})';
                    volm(:,:,p) = cast(plane,'single');
                end
                
                volm(isnan(volm))=0;
                volm(volm<0)=0;
                    
                if strcmp(mode,'send to Icy')
                    try
                        icy_im3show(volm,file_name);                    
                    catch
                        errordlg('error - Icy might be not running');
                    end
                elseif strcmp(mode,'save as OME.tiff')
                    [filename, pathname] = uiputfile('*.OME.tiff','Save as',obj.default_path);
                    if filename ~= 0
                        bfsave(reshape(volm,[sizeX,sizeY,1,n_planes,1]),[pathname filename],'dimensionOrder','XYCZT','Compression', 'LZW','BigTiff', true);
                    end                                                            
                end
                
            elseif strcmp(params_extended{param},'I_mean_tau_chi2') % check not needed, actually 
                
                % find indices
                ind_intensity = [];
                ind_lifetime = [];
                ind_chi2 = [];                       
                for k=1:length(params), if strcmp(char(params{k}),'I'), ind_intensity=k; break; end; end; 
                for k=1:length(params), if strcmp(char(params{k}),'mean_tau'), ind_lifetime=k; break; end; end; 
                for k=1:length(params), if strcmp(char(params{k}),'chi2'), ind_chi2=k; break; end; end;                   
                if isempty(ind_lifetime) % case of single-exponential fit
                    for k=1:length(params), if strcmp(char(params{k}),'tau_1'), ind_lifetime=k; break; end; end; 
                end
                
                if ~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)
                    
                    volm = zeros([sizeX,sizeY,3,n_planes,1],'single'); % XYCZT                    
                    for p = 1 : n_planes                
                        plane_intensity = obj.fit_controller.get_image(p,params{ind_intensity})';
                        plane_lifetime = obj.fit_controller.get_image(p,params{ind_lifetime})';
                        plane_chi2 = obj.fit_controller.get_image(p,params{ind_chi2})';
                        volm(:,:,1,p,1) = cast(plane_intensity,'single');
                        volm(:,:,2,p,1) = cast(plane_lifetime,'single');
                        volm(:,:,3,p,1) = cast(plane_chi2,'single');                        
                    end                    
                    
                    volm(isnan(volm))=0;
                    volm(volm<0)=0;                    
                        
                    if strcmp(mode,'send to Icy')
                        try
                            icy_imshow(volm,file_name);                                                
                        catch
                            errordlg('error - Icy might be not running');
                        end   
                    elseif strcmp(mode,'save as OME.tiff')
                        [filename, pathname] = uiputfile('*.OME.tiff','Save as',obj.default_path);
                        if filename ~= 0
                            bfsave(volm,[pathname filename],'dimensionOrder','XYCZT','Compression', 'LZW','BigTiff', true);
                        end                                                                                   
                    end                    
                    
                end %~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)
                
           end
                                                            
        end % export_volume

        function menu_file_export_volume_batch_callback(obj)            

            % try batch here            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder == 0, return, end;
                
                path_parts = split(filesep,folder);
                batch_folder = [folder filesep '..' filesep 'Batch fit - ' path_parts{end} ' - ' datestr(now,'yyyy-mm-dd HH-MM-SS')];
                mkdir(batch_folder);
                
                files = dir([folder filesep '*.OME.tiff']);
                num_datasets = size(files,1);                                
                                
                for k=1:num_datasets
                    
                    obj.data_series_controller.data_series = flim_data_series();
                    obj.data_series_controller.data_series.all_Z_volume_loading = true;
                    obj.data_series_controller.data_series.batch_mode = true; 
                    
                    obj.data_series_controller.load_single([ folder filesep char(files(k).name)]);
                    obj.data_series_controller.data_series.binning = 0;
                    notify(obj.data_series_controller.data_series,'masking_updated');                    
                                        
                    obj.fit_controller.fit();                    
                    if obj.fit_controller.has_fit == 0
                        uiwait();
                    end                    
                    %
                    % [data, row_headers] = obj.fit_controller.get_table_data();
                    str = char(files(k).name);                    
                    str = str(1:length(str)-8);                      
                    param_table_name = [str 'csv'];
                    obj.fit_controller.save_param_table([batch_folder filesep param_table_name]);
                    
                    %%%%%%%%%%%%%%%%%% save parameters as OME.tiff
                    n_planes = obj.data_series_controller.data_series.n_datasets;                    
                    params = obj.fit_controller.fit_result.fit_param_list();                                            
                    param_array(:,:) = obj.fit_controller.get_image(1, params{1});                                    
                    sizeY = size(param_array,1);
                    sizeX = size(param_array,2);                                        
                    
                    % find indices
                    ind_intensity = [];
                    ind_lifetime = [];
                    ind_chi2 = [];                       
                    for m=1:length(params), if strcmp(char(params{m}),'I'), ind_intensity=m; break; end; end; 
                    for m=1:length(params), if strcmp(char(params{m}),'mean_tau'), ind_lifetime=m; break; end; end; 
                    for m=1:length(params), if strcmp(char(params{m}),'chi2'), ind_chi2=m; break; end; end;   
                    if isempty(ind_lifetime) % case of single-exponential fit
                        for m=1:length(params), if strcmp(char(params{m}),'tau_1'), ind_lifetime=m; break; end; end; 
                    end
                    
                    if ~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)

                        volm = zeros([sizeX,sizeY,3,n_planes,1],'single'); % XYCZT                    
                        for p = 1 : n_planes                
                            plane_intensity = obj.fit_controller.get_image(p,params{ind_intensity})';
                            plane_lifetime = obj.fit_controller.get_image(p,params{ind_lifetime})';
                            plane_chi2 = obj.fit_controller.get_image(p,params{ind_chi2})';
                            volm(:,:,1,p,1) = cast(plane_intensity,'single');
                            volm(:,:,2,p,1) = cast(plane_lifetime,'single');
                            volm(:,:,3,p,1) = cast(plane_chi2,'single');                        
                        end                    

                        volm(isnan(volm))=0;
                        volm(volm<0)=0;                    

                        ometifffilename = [batch_folder filesep str(1:length(str)-1) ' fitting results.OME.tiff'];
                        bfsave(volm,ometifffilename,'dimensionOrder','XYCZT','Compression', 'LZW','BigTiff', true);

                    end %~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)                                       
                    %%%%%%%%%%%%%%%%%% save parameters as OME.tiff
                end
        end
        
        
    end
    
end
