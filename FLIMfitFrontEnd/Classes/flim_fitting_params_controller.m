classdef flim_fitting_params_controller < control_binder & flim_data_series_observer
   
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
        bound_all_controls = false;
        
        tau_guess_table;
        fret_guess_table;
        theta_guess_table;
        
        
        fit_controller;
        
        fit_params;
        
    end
    
    events
        fit_params_update;
    end
    
    methods
             
       
        function obj = flim_fitting_params_controller(handles)

            obj = obj@flim_data_series_observer(handles.data_series_controller);
            obj = obj@control_binder(flim_fitting_params());
            
            assign_handles(obj,handles);

            obj.fit_params = obj.bound_data_source;
        
            
            set(obj.tau_guess_table,'CellEditCallback',@obj.table_changed);
            set(obj.fret_guess_table,'CellEditCallback',@obj.table_changed);
            set(obj.theta_guess_table,'CellEditCallback',@obj.table_changed);
            
            obj.bind_control(handles,'auto_estimate_tau','checkbox');
            
            obj.bind_control(handles,'n_exp','popupmenu');
            obj.bind_control(handles,'n_fix','popupmenu');
            obj.bind_control(handles,'global_fitting','popupmenu');
            obj.bind_control(handles,'global_variable','popupmenu');
            obj.bind_control(handles,'global_algorithm','popupmenu');
            obj.bind_control(handles,'fit_beta','popupmenu');
            obj.bind_control(handles,'fit_offset','popupmenu');
            obj.bind_control(handles,'fit_scatter','popupmenu');
            obj.bind_control(handles,'fit_tvb','popupmenu');
            %obj.bind_control(handles,'t0','edit');
            obj.bind_control(handles,'offset','edit');
            obj.bind_control(handles,'scatter','edit');
            obj.bind_control(handles,'tvb','edit');
            obj.bind_control(handles,'pulsetrain_correction','popupmenu');
            obj.bind_control(handles,'fit_reference','popupmenu');
            obj.bind_control(handles,'fit_t0','popupmenu');
            obj.bind_control(handles,'n_thread','edit');
            obj.bind_control(handles,'fitting_algorithm','popupmenu');
            obj.bind_control(handles,'n_fret','popupmenu');
            obj.bind_control(handles,'n_fret_fix','popupmenu');
            obj.bind_control(handles,'inc_donor','popupmenu');
            
            obj.bind_control(handles,'n_theta','popupmenu');
            obj.bind_control(handles,'n_theta_fix','popupmenu');
            
            obj.bind_control(handles,'weighting_mode','popupmenu');
            obj.bind_control(handles,'calculate_errs','checkbox');
            obj.bind_control(handles,'use_memory_mapping','checkbox');
            obj.bind_control(handles,'use_autosampling','popupmenu');
            obj.bind_control(handles,'image_irf_mode','popupmenu');
            
            
            obj.bound_all_controls = true;
            
            obj.set_polarisation_mode(false);
            
            addlistener(obj.data_series_controller,'new_dataset',@obj.data_update_evt);
            
           
            obj.update_controls();
            
            
            
        end
        
        function data_update(obj)
            
            if obj.data_series.init
                obj.set_polarisation_mode(obj.data_series.polarisation_resolved);
                
                %if ~isempty(obj.data_series.t0_image)
                %    obj.fit_params.image_irf_mode = 2;
                %end
                
                %obj.fit_params.split_fit = obj.data_series.lazy_loading;
                %obj.fit_params.use_memory_mapping = obj.data_series.lazy_loading || ~is64;

                var_list = fieldnames(obj.data_series.metadata);
                var_list = ['-'; var_list];

                set(obj.controls.global_variable_popupmenu,'String',var_list);
            end
            
        end
        
        function load_fitting_params(obj,file)
            try 
                doc_node = xmlread(file);
                obj.fit_params = marshal_object(doc_node,'flim_fitting_params',obj.fit_params);
                obj.update_controls();
                notify(obj,'fit_params_update');
            catch
                warning('FLIMfit:LoadDataSettingsFailed','Failed to load data settings file'); 
            end
            
        end
        
        function save_fitting_params(obj,file)
            obj.fit_params.save_fitting_params(file);
        end
        
        function set_polarisation_mode(obj,polarisation_resolved)
           
            obj.fit_params.polarisation_resolved = polarisation_resolved;
            
            if polarisation_resolved
                pol_disable_group = 'off';
                pol_enable_group = 'on';
            else
                pol_disable_group = 'on';
                pol_enable_group = 'off';
            end
            
            if isfield(obj.controls,'n_fret_popupmenu')
                set(obj.controls.n_fret_popupmenu,'Enable',pol_disable_group);
                set(obj.controls.n_fret_fix_popupmenu,'Enable',pol_disable_group);
            end
            
            if isfield(obj.controls,'n_theta_popupmenu')
                set(obj.controls.n_theta_popupmenu,'Enable',pol_enable_group);
                set(obj.controls.n_theta_fix_popupmenu,'Enable',pol_enable_group);
            end
            
        end
        
        
        function table_changed(obj,~,~)
            flim_table_data = get(obj.tau_guess_table,'Data');
            
            p = obj.fit_params;
            
            has_global_beta_group = p.fit_beta == 3;
            beta_global = p.fit_beta ~= 1;
                        
            new_groups = zeros(p.n_exp,1);
            if (has_global_beta_group)
                groups = flim_table_data(:,3);
                groups = groups - min(groups);
                cur_group = 0;
                for i=1:p.n_exp
                    if groups(i) > cur_group
                        cur_group = cur_group + 1;
                    end
                    new_groups(i) = cur_group;
                end
            else
                new_groups = zeros(p.n_exp,1);
            end
            
            if (beta_global)
                
                old_fixed_beta = p.fixed_beta;
                fixed_beta = flim_table_data(:,2);
                
                for i=0:max(new_groups)
                   
                    beta_g = fixed_beta(new_groups == i);
                    old_beta_g = old_fixed_beta(new_groups == i);
                    
                    changed = beta_g ~= old_beta_g;
                    if ~any(changed)
                        beta_g = beta_g / sum(beta_g);
                    else
                        ch = beta_g(changed);
                        ch(ch>1) = 1;
                        ch(ch<0) = 0;
                        beta_g(changed) = ch;
                        
                        mod_beta_g = beta_g(~changed);
                        if sum(mod_beta_g) == 0
                            mod_beta_g = (1-sum(beta_g(changed))) / length(mod_beta_g);
                        else
                            mod_beta_g = mod_beta_g / sum(mod_beta_g) * (1-sum(beta_g(changed)));
                        end
                        beta_g(~changed) = mod_beta_g;
                    end
                    
                    beta_g(isnan(beta_g)) = 0;
                    
                    fixed_beta(new_groups == i) = beta_g;
                   
                end

            end
                
            if ~isempty(flim_table_data)
                p.tau_guess = flim_table_data(:,1);
                %obj.fit_params.tau_min = flim_table_data(:,2);
                %obj.fit_params.tau_max = flim_table_data(:,3);
                if beta_global
                    p.fixed_beta = fixed_beta;
                end
                if has_global_beta_group
                    p.global_beta_group = new_groups;
                end
            end
            
            fret_table_data = get(obj.fret_guess_table,'Data');
            obj.fit_params.fret_guess = fret_table_data;
            
            phi_table_data = get(obj.theta_guess_table,'Data');
            obj.fit_params.theta_guess = phi_table_data;
            
            obj.update_controls();
        end
                
        function update_controls(obj)
            
            if ~obj.bound_all_controls
                return
            end
            
            table_header = {'Initial Tau'}; % 'Min' 'Max'};
            table_data = obj.fit_params.tau_guess;
            
            if obj.fit_params.fit_beta ~= 1
                table_header = [table_header 'Beta'];
                table_data = [table_data obj.fit_params.fixed_beta];
            end
            
            if obj.fit_params.fit_beta == 3
                table_header = [table_header 'Group'];
                table_data = [table_data obj.fit_params.global_beta_group];
            end
                        
            table_width = ones(size(table_header)) * 80;
            table_width = num2cell(table_width);
            
            set(obj.tau_guess_table,'ColumnName',table_header);
            set(obj.tau_guess_table,'ColumnEditable',true)
            set(obj.tau_guess_table,'Data',table_data);
            set(obj.tau_guess_table,'ColumnWidth',table_width);
            
            
            set(obj.fret_guess_table,'Data',obj.fit_params.fret_guess);
            set(obj.fret_guess_table,'ColumnEditable',true)
            set(obj.fret_guess_table,'ColumnName',{'E'});
            
            set(obj.theta_guess_table,'Data',obj.fit_params.theta_guess);
            set(obj.theta_guess_table,'ColumnEditable',true)
            set(obj.theta_guess_table,'ColumnName',{'phi'});
            
            
            if obj.fit_params.global_fitting == 0
                set(obj.controls.global_algorithm_popupmenu,'Enable','off')
            else
                set(obj.controls.global_algorithm_popupmenu,'Enable','on');
            end
            
            if obj.fit_params.global_fitting < 2
                set(obj.controls.global_variable_popupmenu,'Enable','off');
            else
                set(obj.controls.global_variable_popupmenu,'Enable','on');
            end

            %{
            if obj.fit_params.ref_reconvolution == 0
                set(obj.ref_lifetime_edit,'Enable','off');
            else
                set(obj.ref_lifetime_edit,'Enable','on');
            end
            %}
            if obj.fit_params.auto_estimate_tau
                set(obj.tau_guess_table,'Enable','off');
            else
                set(obj.tau_guess_table,'Enable','on');
            end
            
            if isfield(obj.controls,'n_fret_popupmenu')
                if obj.fit_params.fit_beta ~= 1
                    set(obj.controls.n_fret_popupmenu,'Enable','on');
                    set(obj.controls.n_fret_fix_popupmenu,'Enable','on');
                    set(obj.controls.inc_donor_popupmenu,'Enable','on');
                else
                    set(obj.fret_guess_table,'Data',[]);


                    set(obj.controls.n_fret_popupmenu,'Value',1);
                    set(obj.controls.n_fret_popupmenu,'Enable','off');
                    set(obj.controls.n_fret_fix_popupmenu,'Enable','off');
                    set(obj.controls.inc_donor_popupmenu,'Enable','off');
                end
            end
            notify(obj,'fit_params_update');
            
        end
        
    end
    
end