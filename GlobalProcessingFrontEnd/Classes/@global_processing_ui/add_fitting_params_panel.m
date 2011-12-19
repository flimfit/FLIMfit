function handles = add_fitting_params_panel(obj,handles,parent)
    
    % Fit Params Panel
    %---------------------------------------
    fit_params_panel = uiextras.TabPanel( 'Parent', parent );
    
    % Main Tab
    fit_params_main_layout = uiextras.HBox( 'Parent', fit_params_panel, 'Spacing', 3, 'Padding', 3 );
    fit_params_main_label_layout = uiextras.VBox( 'Parent', fit_params_main_layout, 'Spacing', 1 );
    fit_params_main_opt_layout = uiextras.VBox( 'Parent', fit_params_main_layout, 'Spacing', 1 );
    fit_params_main_extra_layout = uiextras.VBox( 'Parent', fit_params_main_layout, 'Spacing', 1 );    

    
    fit_params_main_col2_layout = uiextras.HBox( 'Parent', fit_params_main_extra_layout, 'Spacing', 3 );
    fit_params_main_col2_label_layout = uiextras.VBox( 'Parent', fit_params_main_col2_layout, 'Spacing', 1 );
    fit_params_main_col2_opt_layout = uiextras.VBox( 'Parent', fit_params_main_col2_layout, 'Spacing', 1 );
    
    handles.tau_guess_table = uitable('Parent', fit_params_main_extra_layout);
    
    fit_params_main_col3_layout = uiextras.HBox( 'Parent', fit_params_main_extra_layout, 'Spacing', 3 );
    fit_params_main_col3_label_layout = uiextras.VBox( 'Parent', fit_params_main_col3_layout, 'Spacing', 1 );
    fit_params_main_col3_opt_layout = uiextras.VBox( 'Parent', fit_params_main_col3_layout, 'Spacing', 1 );
       
    add_fitting_param_control('main','global_fitting','popupmenu','Global Fitting', {'Pixel-wise', 'Image-wise', 'Global'})
    add_fitting_param_control('main_col2','global_variable','popupmenu','Variable', {'-'})
    add_fitting_param_control('main','n_exp','popupmenu','No. Exp', {'1', '2', '3', '4', '5'});
    add_fitting_param_control('main','n_fix','popupmenu','No. Fixed', {'0', '1', '2', '3', '4', '5'});
    add_fitting_param_control('main','use_phase_plane_estimation','popupmenu','Estimate Initial Guess', {'No','Yes'});
    add_fitting_param_control('main','fit_beta','popupmenu','Fit Contributions', {'Fixed', 'Fitted Locally', 'Fitted Globally'});
    add_fitting_param_control('main','data_type','popupmenu','Data Type', {'TCSPC', 'Time Gated'})
    %add_fitting_param_control('main_col3','t0','edit','t0', '0');
    add_fitting_param_control('main','fit_offset','popupmenu','Fit Offset',{'Fixed','Fitted Locally','Fitted Globally'});
    add_fitting_param_control('main_col3','offset','edit','Offset', '0');
    add_fitting_param_control('main','fit_scatter','popupmenu','Fit Scatter',{'Fixed','Fitted Locally','Fitted Globally'});
    add_fitting_param_control('main_col3','scatter','edit','Scatter', '0');
    add_fitting_param_control('main','fit_tvb','popupmenu','Fit TVB',{'Fixed','Fitted Locally','Fitted Globally'});
    add_fitting_param_control('main_col3','tvb','edit','TVB', '0');
    
    add_fitting_param_control('main','pulsetrain_correction','popupmenu','Pulse train correction', {'No','Yes'});
    add_fitting_param_control('main_col3','rep_rate','edit','Rep. Rate', '80');
    add_fitting_param_control('main','ref_reconvolution','popupmenu','IRF Type', {'Scatter','Fixed Reference','Fitted Reference'});
    add_fitting_param_control('main_col3','ref_lifetime','edit','Ref. Lifetime', '100');

    set(fit_params_main_layout,'Sizes',[120 120 300])
    set(fit_params_main_col2_layout,'Sizes',[70 120])
    set(fit_params_main_col3_layout,'Sizes',[70 120])
    set(fit_params_main_extra_layout,'Sizes',[22, 112, -1])

    % Anisotropy tab
    fit_params_anis_layout = uiextras.HBox( 'Parent', fit_params_panel, 'Spacing', 1, 'Padding', 3 );
    fit_params_anis_label_layout = uiextras.VBox( 'Parent', fit_params_anis_layout, 'Spacing', 1 );
    fit_params_anis_opt_layout = uiextras.VBox( 'Parent', fit_params_anis_layout, 'Spacing', 1 );
    fit_params_anis_extra_layout = uiextras.VBox( 'Parent', fit_params_anis_layout, 'Spacing', 1 );

    add_fitting_param_control('anis','n_theta','popupmenu','No. Decays', {'0','1', '2', '3', '4', '5'});
    add_fitting_param_control('anis','n_theta_fix','popupmenu','No. Fixed', {'0','1', '2', '3', '4', '5'});
    
    handles.theta_guess_table = uitable('Parent', fit_params_anis_extra_layout);

    set(fit_params_anis_layout,'Sizes',[120 120 300])
    set(fit_params_anis_extra_layout,'Sizes',[92])
    
    % FRET tab
    fit_params_fret_layout = uiextras.HBox( 'Parent', fit_params_panel, 'Spacing', 1, 'Padding', 3 );
    fit_params_fret_label_layout = uiextras.VBox( 'Parent', fit_params_fret_layout, 'Spacing', 1 );
    fit_params_fret_opt_layout = uiextras.VBox( 'Parent', fit_params_fret_layout, 'Spacing', 1 );
    fit_params_fret_extra_layout = uiextras.VBox( 'Parent', fit_params_fret_layout, 'Spacing', 1 );

    add_fitting_param_control('fret','n_fret','popupmenu','No. FRET Species', {'0','1', '2', '3', '4', '5'});
    add_fitting_param_control('fret','n_fret_fix','popupmenu','No. Fixed', {'0','1', '2', '3', '4', '5'});
    add_fitting_param_control('fret','inc_donor','popupmenu','Include donor only', {'No', 'Yes'});
    
    handles.fret_guess_table = uitable('Parent', fit_params_fret_extra_layout);

    set(fit_params_fret_layout,'Sizes',[120 120 300])
    set(fit_params_fret_extra_layout,'Sizes',[92])
    
    % Advanced tab
    fit_params_adv_layout = uiextras.HBox( 'Parent', fit_params_panel, 'Spacing', 1, 'Padding', 3 );
    fit_params_adv_label_layout = uiextras.VBox( 'Parent', fit_params_adv_layout,  'Spacing', 1 );
    fit_params_adv_opt_layout = uiextras.VBox( 'Parent', fit_params_adv_layout,  'Spacing', 1 );

    add_fitting_param_control('adv','n_thread','edit','No. Threads', '4');
    add_fitting_param_control('adv','fitting_algorithm','popupmenu','Algorithm', {'Marquardt' 'Gauss-Newton' 'Grid Search'});
    add_fitting_param_control('adv','live_update','checkbox','Live Fit', '');
    add_fitting_param_control('adv','split_fit','checkbox','Split Fit', '');
    add_fitting_param_control('adv','use_memory_mapping','checkbox','Memory Map Results', '');
    add_fitting_param_control('adv','calculate_errs','checkbox','Calculate Errors', '');
    set(fit_params_adv_layout,'Sizes',[120 120])

    set(fit_params_panel, 'TabNames', {'Fitting Parameters'; 'Anisotropy Parameters'; 'FRET Parameters'; 'Advanced'});
    set(fit_params_panel, 'SelectedChild', 1);

    
    
    function add_fitting_param_control(layout, name, style, label, string)

        label_layout = eval(['fit_params_' layout '_label_layout;']);
        opt_layout = eval(['fit_params_' layout '_opt_layout;']);

        label = uicontrol( 'Style', 'text', 'String', [label '  '], ... 
                           'HorizontalAlignment', 'right', 'Parent', label_layout ); 
        control = uicontrol( 'Style', style, 'String', string, 'Parent', opt_layout);
        
        eval(['handles.' name '_label = label;']);
        eval(['handles.' name '_' style ' = control;']);

        label_layout_sizes = get(label_layout,'Sizes');
        label_layout_sizes(end) = 22;
        
        set(label_layout,'Sizes',label_layout_sizes);
        set(opt_layout,'Sizes',label_layout_sizes);

        
    end

end