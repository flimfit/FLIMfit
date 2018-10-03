classdef flim_result_controller < flim_data_series_observer
    
    
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
        fit_result;
        
        data_series_list;
        fit_controller;
        
        results_table;
        table_stat_popupmenu;
        
        filter_table;
        
        param_table;
        param_table_headers;
        
        selected;
        
        plot_select_table;
        invert_colormap_popupmenu;
        show_colormap_popupmenu;
        show_limits_popupmenu;
        
        display_normal;
        display_merged;
        plot_names;
        plot_data;
        default_lims;
        plot_lims;
        auto_lim;
        
        cur_lims = [];
        invert_colormap = false;
        show_colormap = true;
        show_limits = true;
        
        n_plots = 0;
        
        lh = {};
    end
    
    
    methods
        
        function obj = flim_result_controller(varargin)
            
            if nargin < 1
                handles = struct('data_series_controller',[]);
            else
                handles = args2struct(varargin);
            end
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
            
            obj.display_normal = containers.Map('KeyType','char','ValueType','logical');
            obj.display_merged = containers.Map('KeyType','char','ValueType','logical');
            obj.plot_names = {};
            obj.default_lims = {};
            obj.plot_lims = containers.Map('KeyType','char','ValueType','any');
            obj.auto_lim = containers.Map('KeyType','char','ValueType','logical');
            
            if ~isempty(obj.data_series_controller)
                addlistener(obj.data_series_controller,'new_dataset',@(~,~) EC(@obj.new_dataset));
            end
            
            if ~isempty(obj.fit_controller)
                addlistener(obj.fit_controller,'fit_updated',@(~,~) EC(@obj.update_results));
            end
            
            if ~isempty(obj.plot_select_table)
                set(obj.plot_select_table,'CellEditCallback',@(~,~) EC(@obj.plot_select_update));
            end
            
            if ~isempty(obj.invert_colormap_popupmenu)
                add_callback(obj.invert_colormap_popupmenu,@(~,~) EC(@obj.plot_select_update));
            end
            
            if ~isempty(obj.show_colormap_popupmenu)
                add_callback(obj.show_colormap_popupmenu,@(~,~) EC(@obj.plot_select_update));
            end
            
            if ~isempty(obj.show_limits_popupmenu)
                add_callback(obj.show_limits_popupmenu,@(~,~) EC(@obj.plot_select_update));
            end
            
            if ~isempty(obj.table_stat_popupmenu)
                set(obj.table_stat_popupmenu,'Callback',@(~,~) EC(@obj.table_stat_updated));
            end
            
            obj.update_list();
            obj.update_display_table();
            
        end
        
        function fit_params_updated(obj)
            obj.fit_params = obj.fitting_params_controller.fit_params;
            obj.has_fit = false;
        end
        
        function [param_data, mask] = get_image(obj,im,param,indexing)
            
            if nargin < 4
                indexing = 'dataset';
            end
            
            if ischar(param)
                param_idx = strcmp(obj.fit_result.params,param);
                param = find(param_idx);
            end
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series') && ~isempty(obj.data_series_controller.data_series.fitted_data)
                [param_data, mask] = obj.data_series_controller.data_series.get_image(im,param,indexing);
            else
                [param_data, mask] = obj.fit_result.get_image(im,param,indexing); % the original line - YA May 30 2013
            end
            
            param_name = obj.fit_result.params{param};
            if contains(param_name,' I') || strcmp(param_name,'I')
                param_data = obj.normalise_intensity(param_data,im,indexing);
            end
            
        end
        
        
        function [param_data, mask] = get_intensity(obj,im,param,indexing)
            
            if nargin < 3
                indexing = 'dataset';
            end
            
            if ischar(param)
                param_idx = strcmp(obj.fit_result.params,param);
                param = find(param_idx);
            end
            
            param = obj.get_intensity_idx(param);
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series') && ~isempty(obj.data_series_controller.data_series.fitted_data)
                [param_data, mask] = obj.data_series_controller.data_series.get_image(im,param,indexing);
            else
                [param_data, mask] = obj.fit_result.get_image(im,param,indexing); % the original line - YA May 30 2013
                param_data = obj.normalise_intensity(param_data,im,indexing);
            end
            
        end
        
        function param_data = normalise_intensity(obj,param_data,im,indexing)
            if strcmp(indexing,'result')
                im = obj.fit_result.image(im);
            end
            norm = obj.data_series_controller.data_series.intensity_normalisation;
            if ~isempty(norm)
                norm = norm(:,:,im);
                param_data = param_data ./ norm;
            end
        end
        
        function lims = get_cur_lims(obj,param)
            if ischar(param)
                param_idx = strcmp(obj.params,param);
                param = find(param_idx);
            end
            
            lims = obj.cur_lims(param,:);
            lims(1) = sd_round(lims(1),3,3); % round down to 3sf
            lims(2) = sd_round(lims(2),3,2); % round up to 3sf
        end
        
        function idx = get_intensity_idx(obj,param)
            group = obj.fit_result.group_idx(param);
            if (group == 0)
                match = strcmp(obj.fit_result.params,'I');
                idx = find(match,1);
            else
                match = strcmp(obj.fit_result.params,['[' num2str(group) '] I_0']);
                idx = find(match,1);
            end
        end
        
        function lims = get_cur_intensity_lims(obj,param)
            param = obj.get_intensity_idx(param);
            lims = obj.get_cur_lims(param);
        end
        
        function lims = set_cur_lims(obj,param,lims)
            obj.cur_lims(param,:) = lims;
        end
        
        function data_update(obj)
        end
        
        function new_dataset(obj)
        end
        
        function table_stat_updated(obj)
            obj.update_table()
        end
        
        
        function update_filter_table(obj)
            
            md = obj.fit_result.metadata;
            
            data = get(obj.filter_table,'Data');
            
            if isempty(data)
                empty_data = repmat({'','',''},[10 1]);
                
                set(obj.filter_table,'ColumnName',{'Param','Type','Value'})
                set(obj.filter_table,'Data',empty_data)
                set(obj.filter_table,'ColumnEditable',true(1,3));
                set(obj.filter_table,'CellEditCallback',@obj.filter_table_updated);
                set(obj.filter_table,'RowName',[]);
            end
            
            set(obj.filter_table,'ColumnFormat',{[{'-'} fieldnames(md)'],{'=','!=','<','>'},'char'})
            
            obj.filter_table_updated([],[]);
            
        end
        
        function update_list(obj)
            if ~isempty(obj.fit_result)
                
                r = obj.fit_result;
                
                old_names = obj.plot_names;
                obj.plot_names = r.fit_param_list();
                
                names = obj.plot_names;
                n_items = length(names);
                
                for i=1:n_items
                    if ~any(strcmp(old_names,names{i}))
                        obj.display_normal(names{i}) = false;
                        obj.display_merged(names{i}) = false;
                        obj.auto_lim(names{i}) = true;
                        obj.plot_lims(names{i}) = r.get_default_lims(i);
                    end
                end
                
                for i=1:length(old_names)
                    if ~any(strcmp(obj.plot_names,old_names{i}))
                        containers.Map
                        
                        remove(obj.display_normal,old_names{i});
                        remove(obj.display_merged,old_names{i});
                        remove(obj.auto_lim,old_names{i});
                        remove(obj.plot_lims,old_names{i});
                    end
                end
            end
            
        end
        
        
        function update_display_table(obj)
            
            if isempty(obj.fit_result)
                set(obj.results_table,'ColumnName',[]);
                set(obj.results_table,'Data',[]);    
            else
                r = obj.fit_result;
                names = obj.plot_names;
                table = cell(length(names),6);
                for i=1:length(names)
                    
                    if obj.auto_lim(names{i})
                        obj.plot_lims(names{i}) = r.get_default_lims(i);
                    end
                    
                    table{i,1} = names{i};
                    table{i,2} = obj.display_normal(names{i});
                    table{i,3} = obj.display_merged(names{i});
                    table(i,4:5) = num2cell(obj.plot_lims(names{i}));
                    table{i,6} = obj.auto_lim(names{i});
                end
                
                for i=1:length(names)
                    obj.set_cur_lims(i, obj.plot_lims(names{i}));
                end
                
                set(obj.plot_select_table,'Data',table);
                set(obj.plot_select_table,'ColumnEditable',logical([0 1 1 1 1 1]));
                set(obj.plot_select_table,'RowName',[]);
                
                obj.invert_colormap = get(obj.invert_colormap_popupmenu,'Value')-1;
                obj.show_colormap =  get(obj.show_colormap_popupmenu,'Value')-1;
                obj.show_limits =  get(obj.show_limits_popupmenu,'Value')-1;
            end
        end
        
        function plot_select_update(obj)
            plots = get(obj.plot_select_table,'Data');
            
            obj.n_plots = 0;
            
            for i=1:size(plots,1)
                name = plots{i,1};
                obj.display_normal(name) = plots{i,2};
                obj.display_merged(name) = plots{i,3};
                
                obj.n_plots = obj.n_plots + sum(cell2mat(plots(i,2:3)));
                
                new_lims = cell2mat(plots(i,4:5));
                
                % Only update if min < max (locks out fat fingers)
                if new_lims(1) < new_lims(2)
                    
                    if any(new_lims ~= obj.plot_lims(name))
                        obj.auto_lim(name) = false;
                    else
                        obj.auto_lim(name) = plots{i,6};
                    end
                    obj.plot_lims(name) = new_lims;
                end
            end
            
            obj.update_display_table();
            
            notify(obj,'fit_display_updated');
            
        end
        
    end
    
end