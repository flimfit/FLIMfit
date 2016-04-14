%> @ingroup UserInterfaceControllers
classdef flim_data_series_controller < handle 
    
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

    
    properties(SetObservable = true)
        
        data_series;
        fitting_params_controller;
        window;
        version;
                
        data_settings_filename = {'data_settings.xml', 'polarisation_data_settings.xml'};
    end
    
    events
        new_dataset;
    end
    
    methods
        
        function obj = flim_data_series_controller(varargin)
            
            handles = args2struct(varargin);
            clear obj.data_series;

            assign_handles(obj,handles);
            
            if isempty(obj.data_series) 
                obj.data_series = flim_data_series();
            end
        end
        
        function file_name = save_settings(obj)
            if isvalid(obj.data_series)
                file_name = obj.data_series.save_data_settings();
            end
        end
        
        function reuse = check_reuse_settings(obj,setting_file_name)
        	reuse = false;
            %{
            if ~isempty(setting_file_name)
                reuse = questdlg('Would you like to reuse data settings from the last dataset? This will keep your IRF and transformation settings','Reuse settings','Yes','No','Yes');
                reuse = strcmp(reuse,'Yes');
            else
                reuse = false;
        	end
            %}
        end
        
        
        function load_data_series(obj,root_path,mode,polarisation_resolved,setting_file_name,selected,channels)
            % save settings from previous dataset if it exists
            saved_setting_file_name = obj.data_settings_filename{1};
            
            if nargin < 6
                channels = [];
            end
            
            if nargin < 4
                polarisation_resolved = false;
            end
            
            if nargin < 5
                % if no setting file was specified ask if user want to
                % reuse last settings
                reuse = obj.check_reuse_settings(saved_setting_file_name);
                if ~reuse
                    setting_file_name = [];
                else
                    setting_file_name = saved_setting_file_name;
                end
            end
           
            % load new dataset
            if nargin < 6
                selected = [];
            end
            
            obj.data_series.load_data_series(root_path,mode,polarisation_resolved,setting_file_name,selected,channels);
            
%            obj.fitting_params_controller.set_polarisation_mode(polarisation_resolved);
            
            if ~isempty(obj.window)
                set(obj.window,'Name',[ obj.data_series.header_text ' (' obj.version ')']);
            end

            notify(obj,'new_dataset');
        end
        
        function load_raw(obj,file,setting_file_name)
            % save settings from previous dataset if it exists
            saved_setting_file_name = obj.data_settings_filename{1}
            
            obj.data_series = flim_data_series();
            obj.data_series.load_raw_data(file);
           
            
            if nargin < 4
                % if no setting file was specified ask if user want to
                % reuse last settings
                obj.check_reuse_settings(saved_setting_file_name);
            else
                % if setting file was specified use that
                obj.data_series.load_data_settings(setting_file_name);
            end
           
                       
            if ~isempty(obj.window)
                set(obj.window,'Name',[file ' (' obj.version ')']);
            end
            
            notify(obj,'new_dataset');
        end
        
        
        function load_single(obj,path,files,polarisation_resolved,setting_file_name,channels)
            % save settings from previous dataset if it exists
            saved_setting_file_name = obj.data_settings_filename{1};
 
            if nargin < 6
                channels = [];
            end
            
            if nargin < 5
                setting_file_name = [];
            end
            
            if nargin < 4
                polarisation_resolved = false;
            end

            % load new dataset
            obj.data_series.load_single(path, files, polarisation_resolved);
            
            %{
            if nargin < 4
                % if no setting file was specified ask if user want to
                % reuse last settings
                obj.check_reuse_settings(saved_setting_file_name);
            else
                % if setting file was specified use that
                obj.data_series.load_data_settings(setting_file_name);
            end
            %}
            
            if ~isempty(obj.window)
                set(obj.window,'Name',[obj.data_series.header_text ' (' obj.version ')']);
            end
                        
            notify(obj,'new_dataset');
        end
        
        function load_plate(obj,plate)
            
            polarisation_resolved = false;
       
            % load new dataset
            obj.data_series.load_plate(plate);
            
            if ~isempty(obj.window)
                set(obj.window,'Name',[obj.data_series.header_text ' (' obj.version ')']);
            end
                        
            notify(obj,'new_dataset');
        end

        function intensity = selected_intensity(obj,selected,apply_mask)
           
            if nargin == 2
                apply_mask = true;
            end
            
            if obj.data_series.init && selected > 0 && selected <= obj.data_series.n_datasets
                
                intensity = obj.data_series.selected_intensity(selected,apply_mask);
                
                
            else
                intensity = [];
            end
            
        end
        
        function mask = selected_mask(obj,selected)
           
            if obj.data_series.init && selected > 0 && selected <= obj.data_series.n_datasets
                
                mask = obj.data_series.mask(:,:,selected);
                if ~isempty(obj.data_series.seg_mask)
                    seg_mask = obj.data_series.seg_mask(:,:,selected);
                    mask = mask & seg_mask;
                end
                                
            else
                mask = [];
            end
            
        end
                
        function delete(obj)
        end
    end
end