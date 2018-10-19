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
    end
    
    properties
        data_series_list;
        model_controller;
        pol_table;
        display_smoothed_popupmenu;
        window;
        version;
    end
    
    properties(Transient = true)
        lh; 
    end
    
    events
        new_dataset;
    end
    
    methods
        
        function obj = flim_data_series_controller(varargin)
            
            handles = args2struct(varargin);
            assign_handles(obj,handles);
            
            if isempty(obj.data_series) 
                obj.data_series = flim_data_series();
            end
            
            set(obj.display_smoothed_popupmenu,'Callback',@obj.set_use_smoothing);
            set(obj.pol_table,'CellEditCallback',@obj.pol_table_updated);
            
        end
        
        function set_use_smoothing(obj,src,~)
            obj.data_series.use_smoothing = src.Value == 2;
            obj.data_series.compute_tr_data();
        end
        
        function file_name = save_settings(obj)
            if isvalid(obj.data_series)
                file_name = obj.data_series.save_data_settings();
            end
        end
        
        function clear(obj)
            delete(obj.data_series);
            obj.data_series = flim_data_series();
        end
        
        function load_data_series(obj,root_path,mode,polarisation_resolved)
            if nargin < 4
                polarisation_resolved = false;
            end

            obj.clear();
            obj.data_series.load_data_series(root_path,mode,polarisation_resolved);
                        
            obj.loaded_new_dataset();
        end
        
        function load_raw(obj,file)
            obj.clear();
            obj.data_series.load_raw_data(file);           
                                   
            obj.loaded_new_dataset();
        end
        
        
        function load_single(obj,file,polarisation_resolved)
            % save settings from previous dataset if it exists
            if nargin < 3
                polarisation_resolved = false;
            end

            % load new dataset
            obj.clear();
            obj.data_series.load_single(file,polarisation_resolved);
                        
                        
            obj.loaded_new_dataset();
        end
        
        function load_plate(obj,plate)
                   
            % load new dataset
            obj.data_series.load_plate(plate);
            
            if ~isempty(obj.window)
                set(obj.window,'Name',[obj.data_series.header_text ' (' obj.version ')']);
            end
                        
            obj.loaded_new_dataset();
        end
        
        function loaded_new_dataset(obj)
            if ~isempty(obj.window)
                set(obj.window,'Name',[obj.data_series.header_text ' (' obj.version ')']);
            end
            
            obj.model_controller.set_n_channel(obj.data_series.n_chan);
            obj.lh = addlistener(obj.data_series,'polarisation','PostSet',@obj.polarisation_changed);

            obj.data_series_list.set_source(obj.data_series);
            
            obj.update_polarisation();
            notify(obj,'new_dataset');
        end

        function polarisation_changed(obj,~,~)
            obj.update_polarisation();
        end
        
        function update_polarisation(obj)
            n_chan = obj.data_series.n_chan;
            for i=1:length(obj.data_series.polarisation)
                pol_str{i,1} = char(obj.data_series.polarisation(i)); %#ok
            end
            obj.pol_table.Data = [ num2cell((1:n_chan)') pol_str ];
        end
        
        function pol_table_updated(obj,~,~)
            pol = obj.pol_table.Data(:,2);
            pol = cellfun(@(p) Polarisation.(p),pol);
            obj.data_series.polarisation = pol;
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
           
            mask = [];
            
            if obj.data_series.init && selected > 0 && selected <= obj.data_series.n_datasets
                mask = obj.data_series.mask(:,:,selected);
                if ~isempty(obj.data_series.seg_mask)
                    seg_mask = obj.data_series.seg_mask(:,:,selected);
                    mask = mask & seg_mask;
                end
            end
            
        end
                
    end
end