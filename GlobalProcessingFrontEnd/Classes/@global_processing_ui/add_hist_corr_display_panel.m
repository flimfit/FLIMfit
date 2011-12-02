function handles = add_hist_corr_display_panel(obj,handles,parent)

    hist_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.hist_axes = axes('Parent',hist_layout);
    
    param_layout = uiextras.HBox( 'Parent', hist_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    handles.hist_param_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
    
    handles.hist_prop_table = uitable('RowName', {'Min', 'Max', 'Classes'}, 'ColumnName', {}, ...
                                      'Data', [0;1;100], 'ColumnEditable', true,... 
                                      'Parent', param_layout);
    
    set( hist_layout, 'Sizes', [-1,70] );
    set( param_layout, 'Sizes', [100,200,170] );

    
    
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