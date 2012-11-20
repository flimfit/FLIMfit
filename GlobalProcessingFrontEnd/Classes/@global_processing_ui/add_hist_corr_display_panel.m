function handles = add_hist_corr_display_panel(obj,handles,parent)

    hist_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.hist_axes = axes('Parent',hist_layout);
    
   
    opt_layout = uiextras.Grid( 'Parent', hist_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Parameter  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Weighting  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    handles.hist_param_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', opt_layout );
    handles.hist_weighting_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'None' 'Intensity Weighted'}, 'Parent', opt_layout );
      
    uicontrol( 'Style', 'text', 'String', 'Classes  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    uiextras.Empty( 'Parent', opt_layout );

    handles.hist_classes_edit = uicontrol( 'Style', 'edit', ...
            'String', '100', 'Parent', opt_layout );
    uiextras.Empty( 'Parent', opt_layout );


    
    set( hist_layout, 'Sizes', [-1,70] );
    set( opt_layout, 'ColumnSizes', [90 90 90 90]);
    set( opt_layout, 'RowSizes', [22 22]);


    
    
    corr_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.corr_axes = axes('Parent',corr_layout);
    
    param_layout = uiextras.Grid( 'Parent', corr_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'X Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
           uicontrol( 'Style', 'text', 'String', 'Y Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    handles.corr_param_x_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
    handles.corr_param_y_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
    
    
    set( corr_layout, 'Sizes', [-1,70] );
    set( param_layout, 'RowSizes', [22,22] );
    set( param_layout, 'ColumnSizes', [100,200] );


end