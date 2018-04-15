function handles = add_fitting_params_panel(obj,handles,parent)

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

    
    

   
    global_modes = {'Global Binning', 'Global Analysis'};
    

    
    % Fit Params Panel
    %---------------------------------------
    fit_params_panel = uix.TabPanel( 'Parent', parent, 'TabWidth', 80 );
    
    % Main Tab
    fit_params_main_layout = uix.HBox( 'Parent', fit_params_panel, 'Spacing', 3, 'Padding', 3 );
    fit_params_main_label_layout = uix.VBox( 'Parent', fit_params_main_layout, 'Spacing', 1 );
    fit_params_main_opt_layout = uix.VBox( 'Parent', fit_params_main_layout, 'Spacing', 1 );
    fit_params_main_extra_layout = uix.VBox( 'Parent', fit_params_main_layout, 'Spacing', 1 );    
    
    handles.auto_estimate_tau_checkbox = uicontrol( 'Style', 'checkbox', 'String', 'Automatically Estimate Lifetimes', 'Parent', fit_params_main_extra_layout);
    handles.tau_guess_table = uitable('Parent', fit_params_main_extra_layout); 
  
       
    add_fitting_param_control('main','global_fitting','popupmenu','Global Fitting', {'Pixel-wise', 'Image-wise', 'Global'})
    add_fitting_param_control('main','global_variable','popupmenu','Global Variable', {'-'})
    add_fitting_param_control('main','global_algorithm','popupmenu','Global Mode', global_modes);
    add_fitting_param_control('main','n_exp','popupmenu','No. Exp', {'1', '2', '3', '4', '5'});
    add_fitting_param_control('main','n_fix','popupmenu','No. Fixed', {'0', '1', '2', '3', '4', '5'});
    add_fitting_param_control('main','fit_beta','popupmenu','Fit Contributions', {'Fixed', 'Fitted Locally', 'Fitted Globally' 'Fitted Globally (Grouped)'});
    add_fitting_param_control('main','fit_reference','popupmenu','Fit Reference', {'Fixed','Fitted'});
    add_fitting_param_control('main','fit_t0','popupmenu','Fit IRF Shift', {'Fixed','Fitted'});
    
    set(fit_params_main_layout,'Widths',[120 120 300])
    set(fit_params_main_extra_layout,'Heights',[22, -1])
    
    % Stray light tab
    fit_params_stray_layout = uix.HBox( 'Parent', fit_params_panel, 'Spacing', 3, 'Padding', 3 );
    fit_params_stray_label_layout = uix.VBox( 'Parent', fit_params_stray_layout, 'Spacing', 1 );
    fit_params_stray_opt_layout = uix.VBox( 'Parent', fit_params_stray_layout, 'Spacing', 1 );
    fit_params_stray_extra_layout = uix.VBox( 'Parent', fit_params_stray_layout, 'Spacing', 1 );    
    
    fit_params_stray_col2_layout = uix.HBox( 'Parent', fit_params_stray_extra_layout, 'Spacing', 3 );
    fit_params_stray_col2_label_layout = uix.VBox( 'Parent', fit_params_stray_col2_layout, 'Spacing', 1 );
    fit_params_stray_col2_opt_layout = uix.VBox( 'Parent', fit_params_stray_col2_layout, 'Spacing', 1 );

    add_fitting_param_control('stray','fit_offset','popupmenu','Offset',{'Fixed','Fitted Locally','Fitted Globally'});
    add_fitting_param_control('stray_col2','offset','edit','Offset', '0');
    add_fitting_param_control('stray','fit_scatter','popupmenu','Scatter',{'Fixed','Fitted Locally','Fitted Globally'});
    add_fitting_param_control('stray_col2','scatter','edit','Scatter', '0');
    add_fitting_param_control('stray','fit_tvb','popupmenu','TV Background',{'Fixed','Fitted Locally','Fitted Globally'});
    add_fitting_param_control('stray_col2','tvb','edit','TVB', '0');

    set(fit_params_stray_layout,'Widths',[120 120 300])
    set(fit_params_stray_col2_layout,'Widths',[70 120])
    
   
        % Anisotropy tab
        fit_params_anis_layout = uix.HBox( 'Parent', fit_params_panel, 'Spacing', 1, 'Padding', 3 );
        fit_params_anis_label_layout = uix.VBox( 'Parent', fit_params_anis_layout, 'Spacing', 1 );
        fit_params_anis_opt_layout = uix.VBox( 'Parent', fit_params_anis_layout, 'Spacing', 1 );
        fit_params_anis_extra_layout = uix.VBox( 'Parent', fit_params_anis_layout, 'Spacing', 1 );

        add_fitting_param_control('anis','n_theta','popupmenu','No. Decays', {'0','1', '2', '3', '4', '5'});
        add_fitting_param_control('anis','n_theta_fix','popupmenu','No. Fixed', {'0','1', '2', '3', '4', '5'});

        handles.theta_guess_table = uitable('Parent', fit_params_anis_extra_layout);

        set(fit_params_anis_layout,'Widths',[120 120 300])
        set(fit_params_anis_extra_layout,'Heights',[92])

        % FRET tab
        fit_params_fret_layout = uix.HBox( 'Parent', fit_params_panel, 'Spacing', 1, 'Padding', 3 );
        fit_params_fret_label_layout = uix.VBox( 'Parent', fit_params_fret_layout, 'Spacing', 1 );
        fit_params_fret_opt_layout = uix.VBox( 'Parent', fit_params_fret_layout, 'Spacing', 1 );
        fit_params_fret_extra_layout = uix.VBox( 'Parent', fit_params_fret_layout, 'Spacing', 1 );

        add_fitting_param_control('fret','n_fret','popupmenu','No. FRET Species', {'0','1', '2', '3', '4', '5'});
        add_fitting_param_control('fret','n_fret_fix','popupmenu','No. Fixed', {'0','1', '2', '3', '4', '5'});
        add_fitting_param_control('fret','inc_donor','popupmenu','Include donor only', {'No', 'Yes'});

        handles.fret_guess_table = uitable('Parent', fit_params_fret_extra_layout);

        set(fit_params_fret_layout,'Widths',[120 120 300])
        set(fit_params_fret_extra_layout,'Heights',[92])

        % Advanced tab
        fit_params_adv_layout = uix.HBox( 'Parent', fit_params_panel, 'Spacing', 1, 'Padding', 3 );
        fit_params_adv_label_layout = uix.VBox( 'Parent', fit_params_adv_layout,  'Spacing', 1 );
        fit_params_adv_opt_layout = uix.VBox( 'Parent', fit_params_adv_layout,  'Spacing', 1 );
        fit_params_adv_extra_layout = uix.VBox( 'Parent', fit_params_adv_layout,  'Spacing', 1 );

        fit_params_adv_col2_layout = uix.HBox( 'Parent', fit_params_adv_extra_layout, 'Spacing', 3 );
        fit_params_adv_col2_label_layout = uix.VBox( 'Parent', fit_params_adv_col2_layout, 'Spacing', 1 );
        fit_params_adv_col2_opt_layout = uix.VBox( 'Parent', fit_params_adv_col2_layout, 'Spacing', 1 );

        
        add_fitting_param_control('adv','n_thread','edit','No. Threads', '4');
        add_fitting_param_control('adv','fitting_algorithm','popupmenu','Algorithm', {'Variable Projection' 'Maximum Likelihood'});
        add_fitting_param_control('adv','weighting_mode','popupmenu','Weighting Mode', {'Average Data','Pixelwise Data','Model'});
        add_fitting_param_control('adv','pulsetrain_correction','popupmenu','Pulse train correction', {'No','Yes'});
        add_fitting_param_control('adv','use_autosampling','popupmenu','Use Autosampling', {'No','Yes'});
        add_fitting_param_control('adv','image_irf_mode','popupmenu','IRF',{'Single Point', 'Use SV IRF', 'Use IRF Shift Map'});
        
        add_fitting_param_control('adv_col2','live_update','checkbox','', 'Live Fit');
        %add_fitting_param_control('adv_col2','split_fit','checkbox','', 'Split Fit');
        %add_fitting_param_control('adv_col2','use_memory_mapping','checkbox','', 'Memory Map Results');
        add_fitting_param_control('adv_col2','calculate_errs','checkbox','', 'Calculate Errors');
        add_fitting_param_control('adv_col2','use_image_t0_correction','checkbox','', 'Use FOV IRF shift');
        
        set(fit_params_adv_layout,'Widths',[120 120 300])
        set(fit_params_adv_col2_layout,'Widths',[20 -1])
      
        set(fit_params_panel, 'TabTitles', {'Lifetime'; 'Stray Light'; 'Anisotropy'; 'FRET'; 'Advanced'});
        set(fit_params_panel, 'Selection', 1);

    
    
    function add_fitting_param_control(layout, name, style, label, string)

        label_layout = eval(['fit_params_' layout '_label_layout;']);
        opt_layout = eval(['fit_params_' layout '_opt_layout;']);

        label = uicontrol( 'Style', 'text', 'String', [label '  '], ... 
                           'HorizontalAlignment', 'right', 'Parent', label_layout ); 
        control = uicontrol( 'Style', style, 'String', string, 'Parent', opt_layout);
        
        handles.([name '_label']) = label;
        handles.([name '_' style]) = control;
        
        label_layout_sizes = get(label_layout,'Heights');
        label_layout_sizes(end) = 22;
        
        set(label_layout,'Heights',label_layout_sizes);
        set(opt_layout,'Heights',label_layout_sizes);

        
    end

end