function handles = setup_layout(obj, handles)

    % Start layout
    %---------------------------------------
    main_layout = uiextras.VBoxFlex( 'Parent', obj.window, 'Spacing', 3 );
    top_layout = uiextras.HBoxFlex( 'Parent', main_layout, 'Spacing', 3 );
    left_layout = uiextras.VBoxFlex( 'Parent', top_layout, 'Spacing', 3 );
    

    % Decay Display
    %---------------------------------------
    
    right_layout = uiextras.VBoxFlex( 'Parent', top_layout );
    
    topright_layout = uiextras.HBox( 'Parent', right_layout );
            
    display_panel = uiextras.TabPanel( 'Parent', topright_layout );
    
    handles = obj.add_decay_display_panel(handles,display_panel);
    handles = obj.add_table_display_panel(handles,display_panel);
    handles = obj.add_image_display_panel(handles,display_panel);
    handles = obj.add_hist_corr_display_panel(handles,display_panel);
    handles = obj.add_plotter_display_panel(handles,display_panel);

    set(display_panel, 'TabNames', {'Decay','Parameters','Images','Gallery','Histogram','Correlation','Plotter','Plate'});
    set(display_panel, 'SelectedChild', 1);
    
    display_params_panel = uiextras.VBox( 'Parent', topright_layout );
    
    col_names = {'Plot','Display','Merge','Min','Max','Auto'};
    col_width = {60 30 30 50 50 30};
    handles.plot_select_table = uitable( 'ColumnName', col_names, 'ColumnWidth', col_width, 'RowName', [], 'Parent', display_params_panel );
    handles.filter_table = uitable( 'Parent', display_params_panel );

    colormap_panel = uiextras.Grid( 'Parent', display_params_panel );
    
    uicontrol( 'Style', 'text', 'String', 'Invert Colorscale? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel );
    handles.invert_colormap_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No','Yes'}, 'Parent', colormap_panel );    
    
    set(display_params_panel, 'Sizes', [-1 -1 22] );
    
    set( topright_layout, 'Sizes', [-1, 0] );
   
    function display_panel_callback(~,src,~)
        if src.SelectedChild <= 2
            set( topright_layout, 'Sizes', [-1, 0] )
        else
            set( topright_layout, 'Sizes', [-1, 253] )
        end
    end
    
    set( display_panel, 'Callback', @display_panel_callback );
    
    % Progress Panel
    %---------------------------------------
    progress_panel = uiextras.BoxPanel( 'Parent', right_layout, 'Title', 'Progress' );
    handles.progress_table = uitable( 'Parent', progress_panel );
    
    set( right_layout, 'Sizes', [-1,110] );
    
    % Dataset Panel
    %---------------------------------------
        
    dataset_panel = uiextras.BoxPanel( 'Parent', left_layout, 'Title', 'Dataset' );
    dataset_layout = uiextras.HBox( 'Parent', dataset_panel, 'Padding', 3 );

    dataset_layout_left = uiextras.VBox( 'Parent', dataset_layout, 'Padding', 3 );
    handles.data_series_table = uitable( 'Parent', dataset_layout_left );
    
    handles.data_series_sel_all = uicontrol( 'Style', 'pushbutton', 'String', 'Select Multiple...', 'Parent', dataset_layout_left );
    
    set( dataset_layout_left, 'Sizes', [-1,22] );
    
    % Intensity View
    %---------------------------------------
    
    intensity_layout = uiextras.VBox( 'Parent', dataset_layout, 'Spacing', 3 );
    
    intensity_opts_layout = uiextras.HBox( 'Parent', intensity_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Mode  ', 'Parent', intensity_opts_layout, ...
               'HorizontalAlignment', 'right' );
    handles.intensity_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Integrated Intensity','Background','SV IRF','IRF Shift Map'}, 'Parent', intensity_opts_layout );
    
    set( intensity_opts_layout, 'Sizes', [-1,200] );
    
    
    intensity_container = uicontainer( 'Parent', intensity_layout ); 
    handles.intensity_axes = axes( 'Parent', intensity_container );
    
    set( intensity_layout, 'Sizes', [22,-1] );
    set( dataset_layout, 'Sizes', [150,-1] );

    
    % Data Transformation Panel
    %---------------------------------------
    handles = obj.add_data_transformation_panel(handles,left_layout);
 

    
    %set(main_layout,'Sizes',[-4,-1]);
    
    % Fitting Params Panel
    %---------------------------------------
    handles = obj.add_fitting_params_panel(handles, left_layout);

    fit_button_layout = uiextras.HBox( 'Parent', left_layout, 'Spacing', 3 );
    
    handles.binned_fit_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Fit Selected Decay', 'Parent', fit_button_layout );
    handles.fit_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Fit Dataset', 'Parent', fit_button_layout );

    set(fit_button_layout,'Sizes',[-1,-2]);
    
    set(left_layout,'Sizes',[-1,125,186,30])
    
        
    set(top_layout,'Sizes',[550,-1]);

    dragzoom([handles.highlight_axes handles.residuals_axes])
       
end