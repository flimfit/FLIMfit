classdef flim_fitting_params_controller < handle & flim_data_series_observer
   
    properties
    
        n_exp_popupmenu;
        n_fix_popupmenu;
        global_fitting_popupmenu;
        data_type_popupmenu;
        fit_beta_popupmenu;
        fit_offset_popupmenu;
        fit_scatter_popupmenu;
        fit_tvb_popupmenu;
        tau_guess_table;
        t0_edit;
        offset_edit;
        scatter_edit;
        tvb_edit;
        pulsetrain_correction_popupmenu;
        rep_rate_edit;
        ref_reconvolution_popupmenu;
        ref_lifetime_edit;
        n_thread_edit;
        fitting_algorithm_popupmenu;
        n_fret_popupmenu;
        n_fret_fix_popupmenu;
        inc_donor_popupmenu;
        fret_guess_table;
        global_variable_popupmenu;
        use_phase_plane_estimation_popupmenu;
        calculate_errs_checkbox;
        split_fit_checkbox;
        use_memory_mapping_checkbox;
        
        n_theta_popupmenu;
        n_theta_fix_popupmenu;
        theta_guess_table;
        
        fit_controller;
        
        fit_params;
        
        flh = {};
    end
    
    events
        fit_params_update;
    end
    
    methods
             
       
        function obj = flim_fitting_params_controller(handles)
        
            obj = obj@flim_data_series_observer(handles.data_series_controller);
             
            assign_handles(obj,handles);
            
            set(obj.tau_guess_table,'CellEditCallback',@obj.table_changed);
            set(obj.fret_guess_table,'CellEditCallback',@obj.table_changed);
            set(obj.theta_guess_table,'CellEditCallback',@obj.table_changed);
            
            obj.fit_params = flim_fitting_params();
            
            obj.bind_control(obj.n_exp_popupmenu,'popupmenu','n_exp');
            obj.bind_control(obj.n_fix_popupmenu,'popupmenu','n_fix');
            obj.bind_control(obj.global_fitting_popupmenu,'popupmenu','global_fitting');
            obj.bind_control(obj.global_variable_popupmenu,'popupmenu','global_variable');
            obj.bind_control(obj.use_phase_plane_estimation_popupmenu,'popupmenu','use_phase_plane_estimation');
            obj.bind_control(obj.data_type_popupmenu,'popupmenu','data_type');
            obj.bind_control(obj.fit_beta_popupmenu,'popupmenu','fit_beta');
            obj.bind_control(obj.fit_offset_popupmenu,'popupmenu','fit_offset');
            obj.bind_control(obj.fit_scatter_popupmenu,'popupmenu','fit_scatter');
            obj.bind_control(obj.fit_tvb_popupmenu,'popupmenu','fit_tvb');
            obj.bind_control(obj.t0_edit,'edit','t0');
            obj.bind_control(obj.offset_edit,'edit','offset');
            obj.bind_control(obj.scatter_edit,'edit','scatter');
            obj.bind_control(obj.tvb_edit,'edit','tvb');
            obj.bind_control(obj.pulsetrain_correction_popupmenu,'popupmenu','pulsetrain_correction');
            obj.bind_control(obj.rep_rate_edit,'edit','rep_rate');
            obj.bind_control(obj.ref_reconvolution_popupmenu,'popupmenu','ref_reconvolution');
            obj.bind_control(obj.ref_lifetime_edit,'edit','ref_lifetime');
            obj.bind_control(obj.n_thread_edit,'edit','n_thread');
            obj.bind_control(obj.fitting_algorithm_popupmenu,'popupmenu','fitting_algorithm');
            obj.bind_control(obj.n_fret_popupmenu,'popupmenu','n_fret');
            obj.bind_control(obj.n_fret_fix_popupmenu,'popupmenu','n_fret_fix');
            obj.bind_control(obj.inc_donor_popupmenu,'popupmenu','inc_donor');
            
            obj.bind_control(obj.n_theta_popupmenu,'popupmenu','n_theta');
            obj.bind_control(obj.n_theta_fix_popupmenu,'popupmenu','n_theta_fix');
            
            obj.bind_control(obj.calculate_errs_checkbox,'checkbox','calculate_errs');
            obj.bind_control(obj.split_fit_checkbox,'checkbox','split_fit');
            obj.bind_control(obj.use_memory_mapping_checkbox,'checkbox','use_memory_mapping');
            
            obj.set_polarisation_mode(false);
            
            addlistener(obj.data_series_controller,'new_dataset',@obj.data_update_evt);
            
            obj.update_controls();
            
        end
        
        function data_update(obj)
            
            if obj.data_series.init
                obj.set_polarisation_mode(obj.data_series.polarisation_resolved);
                
                %obj.fit_params.split_fit = obj.data_series.lazy_loading;
                %obj.fit_params.use_memory_mapping = obj.data_series.lazy_loading || ~is64;

                var_list = fieldnames(obj.data_series.metadata);
                var_list = ['-'; var_list];

                set(obj.global_variable_popupmenu,'String',var_list);
            end
            
        end
        
        function load_fitting_params(obj,file)
            obj.fit_params = marshal_object(file,'flim_fitting_params',obj.fit_params);
            
            obj.update_controls();
            notify(obj,'fit_params_update');
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
                
            set(obj.n_fret_popupmenu,'Enable',pol_disable_group);
            set(obj.n_fret_fix_popupmenu,'Enable',pol_disable_group);
            
            
            set(obj.n_theta_popupmenu,'Enable',pol_enable_group);
            set(obj.n_theta_fix_popupmenu,'Enable',pol_enable_group);

        end
        
        function bind_control(obj,control,control_type,parameter)
            control_callback = @(src,evt) control_updated(obj,src,evt,control_type,parameter);
            set(control,'Callback',control_callback);
            
            variable_callback =  @(src,evt) variable_updated(obj,src,evt,control,control_type,parameter);
            obj.flh{end+1} = addlistener(obj.fit_params,parameter,'PostSet',variable_callback);
            
            variable_updated(obj,[],[],control,control_type,parameter);
        end
        
        function variable_updated(obj,~,~,control,control_type,parameter)
            
            value = obj.fit_params.(parameter);
            
            switch control_type
                case 'edit'
                    set(control,'String',num2str(value,'%11.4g'));
                case 'popupmenu'
                    str = get(control,'String');
                    items = str2double(str);
                    
                    if all(isnan(items)) % we have a popup menu of strings
                        idx = value + 1;
                    else
                        idx = find(items==value,1,'first');
                    end
                    
                    if ~isempty(idx)
                        set(control,'Value',idx)
                    else
                        set(control,'Value',1);
                    end
                case 'checkbox'
                    set(control,'Value',value);
            end
            
            obj.update_controls();
            
            notify(obj,'fit_params_update');
        end
        
        function control_updated(obj,src,~,control_type,parameter)
        
            value = [];
            
            switch control_type
                case 'edit'
                    value = str2double(get(src,'String'));
                case 'popupmenu'
                    idx = get(src,'Value');
                    str = get(src,'String');
                    value = str2double(str{idx});
                    
                    if isnan(value) % string value
                        value = idx - 1;
                    end
                case 'checkbox'
                    value = get(src,'Value');
            end
            
            obj.fit_params.(parameter) = value;
        
        end
        
        function table_changed(obj,~,~)
            flim_table_data = get(obj.tau_guess_table,'Data');
            
            if ~isempty(flim_table_data)
                obj.fit_params.tau_guess = flim_table_data(:,1);
                obj.fit_params.tau_min = flim_table_data(:,2);
                obj.fit_params.tau_max = flim_table_data(:,3);
                if obj.fit_params.fit_beta ~= 1
                    obj.fit_params.fixed_beta = flim_table_data(:,4);
                end
            end
            
            fret_table_data = get(obj.fret_guess_table,'Data');
            obj.fit_params.fret_guess = fret_table_data;
            
            phi_table_data = get(obj.theta_guess_table,'Data');
            obj.fit_params.theta_guess = phi_table_data;
        end
                
        function update_controls(obj)
            
            table_header = {'Initial' 'Min' 'Max'};
            table_data = [obj.fit_params.tau_guess obj.fit_params.tau_min obj.fit_params.tau_max];
            
            if obj.fit_params.fit_beta ~= 1
                table_header = [table_header 'Fixed beta'];
                table_data = [table_data obj.fit_params.fixed_beta];
            end
                        
            table_width = ones(size(table_header)) * 50;
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
            
            
            if obj.fit_params.fit_beta ~= 1
                set(obj.n_fret_popupmenu,'Enable','on');
                set(obj.n_fret_fix_popupmenu,'Enable','on');
                set(obj.inc_donor_popupmenu,'Enable','on');
            else
                set(obj.n_fret_popupmenu,'Value',1);
                set(obj.fret_guess_table,'Data',[]);
                set(obj.n_fret_popupmenu,'Enable','off');
                set(obj.n_fret_fix_popupmenu,'Enable','off');
                set(obj.inc_donor_popupmenu,'Enable','off');
            end
            
            
        end
        
    end
    
end