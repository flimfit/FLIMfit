classdef file_menu_controller < handle
    
    
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
        data_decay_view;
        fit_controller;
        model_controller;
        hist_controller;
        plot_controller;
        
        menu_irf_recent;
        menu_file_recent_default;
        
        recent_irf;
        recent_default_path;
        window;
    end
    
    methods(Access=private)
                
        function update_recent_default_list(obj)
            function menu_call(path)
                 setpref('GlobalAnalysisFrontEnd','DefaultFolder',path);
            end
            
            if ~isempty(obj.recent_default_path)
                names = obj.recent_default_path;

                delete(get(obj.menu_file_recent_default,'Children'));
                add_menu_items(obj.menu_file_recent_default,names,@menu_call,obj.recent_default_path)
            end
        end
        
        function set_default_path(obj,path)
            if ~any(strcmp(path,obj.recent_default_path))
                obj.recent_default_path = [path; obj.recent_default_path];
            end
            if length(obj.recent_default_path) > 20
                obj.recent_default_path = obj.recent_default_path(1:20);
            end
            setpref('GlobalAnalysisFrontEnd','RecentDefaultPath',obj.recent_default_path);

            setpref('GlobalAnalysisFrontEnd','DefaultFolder',path);
            obj.update_recent_default_list();
        end
        
    end
    
    methods
        
        function obj = file_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
            
            
            obj.recent_irf = getpref('GlobalAnalysisFrontEnd','RecentIRF',{});
            obj.recent_default_path = getpref('GlobalAnalysisFrontEnd','RecentDefaultPath',{});
            
            obj.update_recent_default_list();

        end
        
        function menu_file_new_window(~)
            FLIMfit();
        end
        
        %------------------------------------------------------------------
        % Default Path
        %------------------------------------------------------------------
        function menu_file_set_default_path(obj)
            path = uigetdir(default_path,'Select default path');
            if path ~= 0
                obj.set_default_path(path);
            end
        end
        
        function menu_file_exit(obj)
           
            if isdeployed
                exit()
            else
                close(obj.window)
            end
            
        end
                         
        %------------------------------------------------------------------
        % Load Data
        %------------------------------------------------------------------
        function menu_file_load_single(obj)
            
            [files,path] = uigetfile('*.*','Select a file from the data',default_path,'MultiSelect','on'); 
            if ~iscell(files) 
                if files == 0
                    return;
                end
            end
            obj.data_series_controller.load_single([path files]); 
            obj.set_default_path(path);
                        
        end
        
        function menu_file_load_widefield(obj)
            
            folder = uigetdir(default_path,'Select the folder containing the datasets');
            if folder ~= 0 
                obj.data_series_controller.load_data_series(folder,'tif-stack'); 
                obj.set_default_path(folder);
            end
        end
        
        function menu_file_load_tcspc(obj)
            folder = uigetdir(default_path,'Select the folder containing the datasets');
            if folder ~= 0
                obj.data_series_controller.load_data_series(folder,'bio-formats');
                obj.set_default_path(folder);
            end
        end
        
        
        function menu_file_load_plate(obj)
            
            [file,path] = uigetfile('*.ome.tiff;*.OME.tiff;*.ome.tif;;*.OME.tif','Select an ome.tiff containing plate data',default_path);
            if file ~= 0
                obj.data_series_controller.load_plate([path file]); 
                obj.set_default_path(path);
            end
        end
        
        function menu_file_load_single_pol(obj)
            [file,path] = uigetfile('*.*','Select a file from the data',default_path);
            if file ~= 0
                obj.data_series_controller.load_single([path file],true); 
                obj.set_default_path(path);
            end
                end
        
        function menu_file_load_tcspc_pol(obj)
            folder = uigetdir(default_path,'Select the folder containing the datasets');
            if folder ~= 0
                obj.data_series_controller.load_data_series(folder,'bio-formats',true);
                obj.set_default_path(folder);
            end
        end
        
        function menu_file_reload_data(obj)
            obj.data_series_controller.data_series.reload_data;
        end
        
        function menu_file_load_acceptor(obj)
            folder = uigetdir(default_path,'Select the folder containing the acceptor images');
            if folder ~= 0
                obj.data_series_controller.data_series.load_acceptor_images(folder);
            end
        end
        
        function menu_file_import_acceptor(obj)
            [file, path] = uigetfile({'*.tiff'},'Select the exported acceptor image file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.load_acceptor_images([path file]);
            end
        end
        
        function menu_file_export_acceptor(obj)
            [file, path] = uiputfile({'*.tiff'},'Select exported acceptor image file name',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.export_acceptor_images([path file]);
            end
        end
        
        %------------------------------------------------------------------
        % Export Data Settings
        %------------------------------------------------------------------
        function menu_file_save_data_settings(obj)
            [filename, pathname] = uiputfile({'*.xml', 'XML File (*.xml)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_settings([pathname filename]);         
            end
        end
                
        
        function menu_file_load_data_settings(obj)
            [filename, pathname] = uigetfile({'*.xml', 'XML File (*.xml)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.load_data_settings([pathname filename]);         
            end
        end
        
        function menu_file_load_t_calibration(obj)
            [filename, pathname] = uigetfile({'*.csv', 'CSV File (*.csv)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.load_t_calibriation([pathname filename]);         
            end
        end

        %------------------------------------------------------------------
        % Export Data
        %------------------------------------------------------------------
        function menu_file_save_dataset(obj)
            [filename, pathname] = uiputfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_series([pathname filename]);         
            end
        end
        
        function menu_file_save_raw(obj)
            [filename, pathname] = uiputfile({'*.raw', 'Raw File (*.raw)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_raw_data([pathname filename]);         
            end
        end
        
        function menu_file_save_magic_angle_raw(obj)
            [filename, pathname] = uiputfile({'*.raw', 'Raw File (*.raw)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_series_controller.data_series.save_magic_angle_raw([pathname filename]);         
            end
        end
            
        function menu_file_export_segmented_regions(obj)
            pathname = uigetdir(default_path,'Select folder');
            if pathname ~= 0
                obj.data_series_controller.data_series.export_segmented_regions(pathname);         
            end
        end
        
        %------------------------------------------------------------------
        % Export Decay
        %------------------------------------------------------------------
        function menu_file_export_decay(obj)
            [filename, pathname] = uiputfile({'*.txt', 'TXT File (*.txt)'},'Select file name',default_path);
            if filename ~= 0
                obj.data_decay_view.update_display([pathname filename]);
            end
        end
        
        function menu_file_export_decay_series(obj)
            [filename, pathname] = uiputfile({'*.txt', 'TXT File (*.txt)'},'Select file postfix',default_path);
            if filename ~= 0
                obj.data_decay_view.update_display([pathname filename],'all');
            end
        end
        
        %------------------------------------------------------------------
        % Import/Export Fit Results
        %------------------------------------------------------------------
        function menu_file_export_fit_results(obj)
            [filename, pathname] = uiputfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',default_path);
            if filename ~= 0
                obj.fit_controller.save_fit_result([pathname filename]);         
            end
        end

        function menu_file_import_fit_results(obj)
            [filename, pathname] = uigetfile({'*.hdf5', 'HDF5 File (*.hdf5)'},'Select file name',default_path);
            if filename ~= 0
                obj.fit_controller.load_fit_result([pathname filename]);           
            end
        end
        
        function menu_file_export_intensity(obj)
            folder = uigetdir(default_path);
            obj.data_series_controller.data_series.export_intensity_images(folder);
        end
        
        %------------------------------------------------------------------
        % Import/Export Fit Parameters
        %------------------------------------------------------------------
        function menu_file_save_model(obj)
            [filename, pathname] = uiputfile({'model.xml', 'XML File (*.xml)'},'Select file name',default_path);
            if filename ~= 0
                obj.model_controller.save([pathname filename]);         
            end
        end

        function menu_file_load_model(obj)
            [filename, pathname] = uigetfile({'*.xml', 'XML File (*.xml)'},'Select file name',default_path);
            if filename ~= 0
                obj.model_controller.load([pathname filename]);           
            end
        end
        
        function menu_tools_edit_model_library(~)
            model_library_ui(); 
        end
        
        
        
        %------------------------------------------------------------------
        % Export Fit Table
        %------------------------------------------------------------------
        function menu_file_export_fit_table(obj)
            [filename, pathname] = uiputfile({'*.csv', 'CSV File (*.csv)'},'Select file name',default_path);
            if filename ~= 0
                obj.fit_controller.save_param_table([pathname filename]);
            end
        end
   
        function menu_file_import_plate_metadata(obj)
            [file,path] = uigetfile({'*.xls;*.xlsx;*.csv','All Compatible Files';'*.xls;*.xlsx','Excel Files';'*.csv','CSV File'},'Select the metadata file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.import_plate_metadata([path file]);
            end
        end
        
        
        function menu_file_import_exclusion_list(obj)
            [file,path] = uigetfile({'*.txt','Text Files'},'Select the exclusion file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.import_exclusion_list([path file]);
            end
        end
        
        function menu_file_export_exclusion_list(obj)
            [file,path] = uiputfile({'*.txt','Text Files'},'Select the exclusion file',default_path);
            if file ~= 0
                obj.data_series_controller.data_series.export_exclusion_list([path file]);
            end
        end
        
        function menu_file_export_hist_data(obj, ~, ~)
            
            [filename, pathname] = uiputfile({'*.txt', 'Text File (*.txt)'},'Select file name',default_path);
            if filename ~= 0
                obj.hist_controller.export_histogram_data([pathname filename]);
            end
        end
        
        function menu_file_export_plots(obj, ~, ~)
            [filename, pathname, ~] = uiputfile( ...
                        {'*.tiff', 'TIFF image (*.tiff)';...
                         '*.pdf','PDF document (*.pdf)';...
                         '*.png','PNG image (*.png)';...
                         '*.eps','EPS image (*.eps)';...
                         '*.fig','Matlab figure (*.fig)'},...
                         'Select root file name',[default_path filesep 'fit']);

            if filename ~= 0
                obj.plot_controller.update_plots([pathname filename])
            end
        end
        
        
    end
    
end
