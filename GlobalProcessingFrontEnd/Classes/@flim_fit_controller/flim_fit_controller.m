classdef flim_fit_controller < flim_data_series_observer
    
    
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
        
        fitting_params_controller;
        fit_params;
        
        roi_controller;
        data_series_list;
        
        binned_fit_pushbutton;
        fit_pushbutton;
        results_table;
        progress_table;
        table_stat_popupmenu;
    
        filter_table;
        
        dll_interface;
        
        param_table;
        param_table_headers;
        
        live_update_checkbox;
        
        progress_cur_group;
        progress_n_completed
        progress_iter;
        progress_chi2;
        progress;
        
        has_fit = false;
        fit_in_progress = false;
        
        wait_handle;
        cur_fit;
        start_time;
        
        selected;
        
        live_update = false;
        refit_after_return = false;
        
        use_popup = false;
        
        plot_select_table;
        invert_colormap_popupmenu;
        
        display_normal = struct();
        display_merged = struct();
        plot_names = {};
        plot_data;
        default_lims = {};
        plot_lims = struct();
        auto_lim = struct();

        cur_lims = [];
        invert_colormap = false;
        
        n_plots = 0;
        
        lh = {};
                
    end
    
    events
        progress_update;
        fit_updated;
        fit_display_updated;
        fit_completed;
    end
        
    
    methods
        
        function delete(obj,src)
        end
        
        function obj = flim_fit_controller(varargin)
            
            if nargin < 1
                handles = struct('data_series_controller',[]);
            else
                handles = args2struct(varargin);
            end
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);
            
            obj.fit_result = flim_fit_result();
            obj.dll_interface = flim_dll_interface();
            
            if ishandle(obj.fit_pushbutton)
                set(obj.fit_pushbutton,'Callback',@obj.fit_pushbutton_callback);
            end

            if ishandle(obj.binned_fit_pushbutton)
                set(obj.binned_fit_pushbutton,'Callback',@obj.binned_fit_pushbutton_callback);
            end

            
            if ~isempty(obj.data_series_controller) 
                addlistener(obj.data_series_controller,'new_dataset',@obj.new_dataset);
            end
            
            addlistener(obj.dll_interface,'fit_completed',@obj.fit_complete);
            addlistener(obj.dll_interface,'progress_update',@obj.update_progress);
            
            if ~isempty(obj.fitting_params_controller)
                addlistener(obj.fitting_params_controller,'fit_params_update',@obj.fit_params_updated);
                obj.fit_params = obj.fitting_params_controller.fit_params;
            end
            
            if ~isempty(obj.roi_controller)
                addlistener(obj.roi_controller,'roi_updated',@obj.roi_mask_updated);
            end
            
            if ~isempty(obj.live_update_checkbox)
                set(obj.live_update_checkbox,'Value',obj.live_update);
                set(obj.live_update_checkbox,'Callback',@obj.live_update_callback);
            end
            
            if ~isempty(obj.plot_select_table)
                set(obj.plot_select_table,'CellEditCallback',@obj.plot_select_update);
            end
            
            if ~isempty(obj.invert_colormap_popupmenu)
                add_callback(obj.invert_colormap_popupmenu,@obj.plot_select_update);
            end
            
            if ~isempty(obj.table_stat_popupmenu)
                set(obj.table_stat_popupmenu,'Callback',@obj.table_stat_updated);
            end
            
            obj.update_list();
            obj.update_display_table();
            
        end       
        
        function fit_params_updated(obj,~,~)
            obj.fit_params = obj.fitting_params_controller.fit_params;
            if obj.data_series_controller.data_series.init && obj.live_update
                obj.fit(true);
            else
                obj.has_fit = false;
            end
        end
        
        function roi_mask_updated(obj,~,~)
            d = obj.data_series_controller.data_series;
            if ~(obj.has_fit && obj.fit_result.binned == false) && d.init
                if obj.live_update
                    obj.fit(true);
                else
                    obj.clear_fit();
                end
            end
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
                [param_data, mask] = obj.dll_interface.get_image(im,param,indexing); % the original line - YA May 30 2013                
            end;
                                        
        end

        
        function [param_data, mask] = get_intensity(obj,im,indexing)
            
            if nargin < 3
                indexing = 'dataset';
            end
            
            param = obj.fit_result.intensity_idx;
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series') && ~isempty(obj.data_series_controller.data_series.fitted_data)
                    [param_data, mask] = obj.data_series_controller.data_series.get_image(im,param,indexing);
            else            
                [param_data, mask] = obj.dll_interface.get_image(im,param,indexing); % the original line - YA May 30 2013                
            end;
                        
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
        
        function lims = get_cur_intensity_lims(obj)      
            param = obj.fit_result.intensity_idx;
            lims = obj.get_cur_lims(param);     
        end
        
        function lims = set_cur_lims(obj,param,lims)
            obj.cur_lims(param,:) = lims;
        end
        
        
        function live_update_callback(obj,~,~)
            obj.live_update = get(obj.live_update_checkbox,'Value');
            if obj.live_update == false
                obj.clear_fit();
            end
        end
        
        function fit_pushbutton_callback(obj,~,~)
            d = obj.data_series_controller.data_series;
            if d.init
                obj.fit();
            end            
        end
        
        function binned_fit_pushbutton_callback(obj,~,~)
            d = obj.data_series_controller.data_series;
            if d.init
                obj.fit(true);
            end
        end
        
        function data_update(obj)
            obj.clear_fit();
        end
        
        function new_dataset(obj,~,~)
            obj.clear_fit();
        end
        
        function table_stat_updated(obj,~,~)
            obj.update_table()
        end
        
        function decay = fitted_decay(obj,t,im_mask,selected)
            decay = obj.dll_interface.fitted_decay(t,im_mask,selected);
        end
        
        function anis = fitted_anisotropy(obj,t,im_mask,selected)
            decay = obj.fitted_decay(t,im_mask,selected);
            
            d = obj.data_series;
            
            para = decay(:,1);
            perp = decay(:,2);
            perp_shift = obj.data_series.shifted_perp(perp) * d.g_factor;
            
            anis = (para-perp_shift)./(para+2*perp_shift);
                       
            parac = conv(para,d.tr_irf(:,2));
            perpc = conv(perp,d.tr_irf(:,1));
            [~,n] = max(d.tr_irf(:,1));
            anis = (parac-perpc)./(parac+2*perpc);
            anis = anis((1:size(decay,1))+n,:);
            
                        
        end
        
        function magic = fitted_magic_angle(obj,t,im_mask,selected)
            decay = obj.fitted_decay(t,im_mask,selected);
            
            para = decay(:,1);
            perp = decay(:,2);
            perp_shift = obj.data_series.shifted_perp(perp) * obj.data_series.g_factor;

            irf = obj.data_series.tr_irf;
            
            parac = conv(para,irf(:,2));
            perpc = conv(perp,irf(:,1));

            [~,n] = max(irf(:,1));
             magic = (parac+2*perpc);
            
            magic = magic((1:size(decay,1))+n,:);
        end
        
        function display_fit_end(obj)
            
            if ishandle(obj.fit_pushbutton)
                set(obj.fit_pushbutton,'String','Fit Dataset');  
            end
            
            if ishandle(obj.wait_handle)
                delete(obj.wait_handle)
            end
           
        end
        
        function display_fit_start(obj)
            
            if ishandle(obj.fit_pushbutton)
                set(obj.fit_pushbutton,'String','Stop Fit');
                if obj.use_popup
                    obj.wait_handle = waitbar(0,'Fitting...');
                end
            end
            
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
                if (obj.has_fit)

                    r = obj.fit_result;

                    old_names = obj.plot_names;
                    obj.plot_names = r.fit_param_list();

                    names = obj.plot_names;
                    n_items = length(names);

                    for i=1:n_items
                        if ~any(strcmp(old_names,names{i}))
                            obj.display_normal.(names{i}) = false;
                            obj.display_merged.(names{i}) = false;
                            obj.auto_lim.(names{i}) = true;
                            obj.plot_lims.(names{i}) = r.get_default_lims(i);
                        end
                    end

                    for i=1:length(old_names)
                        if ~any(strcmp(obj.plot_names,old_names{i}))
                            obj.display_normal = rmfield(obj.display_normal,old_names{i});
                            obj.display_merged = rmfield(obj.display_merged,old_names{i});
                            obj.auto_lim = rmfield(obj.auto_lim,old_names{i});
                            obj.plot_lims = rmfield(obj.plot_lims,old_names{i});
                        end
                    end   
                end

         end
        
         
         function update_display_table(obj)
                       
            if obj.has_fit
                r = obj.fit_result;
                names = obj.plot_names;
                table = cell(length(names),6);
                for i=1:length(names)

                    if obj.auto_lim.(names{i}) 
                        obj.plot_lims.(names{i}) = r.get_default_lims(i);
                    end

                    table{i,1} = names{i};
                    table{i,2} = obj.display_normal.(names{i});
                    table{i,3} = obj.display_merged.(names{i});
                    table(i,4:5) = num2cell(obj.plot_lims.(names{i}));
                    table{i,6} = obj.auto_lim.(names{i});
                end

                for i=1:length(names) 
                    obj.set_cur_lims(i, obj.plot_lims.(names{i}));
                end

                set(obj.plot_select_table,'Data',table);
                set(obj.plot_select_table,'ColumnEditable',logical([0 1 1 1 1 1]));
                set(obj.plot_select_table,'RowName',[]);

                obj.invert_colormap = get(obj.invert_colormap_popupmenu,'Value')-1;
            end
         end
         
         function plot_select_update(obj,~,~)
            plots = get(obj.plot_select_table,'Data');

            obj.n_plots = 0;
            
            for i=1:size(plots,1)
               name = plots{i,1};
               obj.display_normal.(name) = plots{i,2};
               obj.display_merged.(name) = plots{i,3};
               
               obj.n_plots = obj.n_plots + sum(cell2mat(plots(i,2:3))); 
               
               new_lims = cell2mat(plots(i,4:5));
               if any(new_lims ~= obj.plot_lims.(name))
                   obj.auto_lim.(name) = false;
               else
                   obj.auto_lim.(name) = plots{i,6};
               end
               obj.plot_lims.(name) = new_lims;
            end
            
            obj.update_display_table();
            
            notify(obj,'fit_display_updated');
            
        end
        
    end
    
end