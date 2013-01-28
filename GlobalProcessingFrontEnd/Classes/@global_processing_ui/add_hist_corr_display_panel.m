function handles = add_hist_corr_display_panel(obj,handles,parent)

    % Add Histograms controls
    %====================================

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
    uicontrol( 'Style', 'text', 'String', 'Source Data  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );

    handles.hist_classes_edit = uicontrol( 'Style', 'edit', ...
            'String', '100', 'Parent', opt_layout );
    handles.hist_source_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Selected Image' 'All Filtered'}, 'Parent', opt_layout );

    
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
        
    uicontrol( 'Style', 'text', 'String', 'Source Data  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Plot  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
           
    handles.corr_source_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Selected Image' 'All Filtered'}, 'Parent', param_layout );
    handles.corr_display_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Pixels' 'Regions'}, 'Parent', param_layout );
    
    uicontrol( 'Style', 'text', 'String', 'Scale  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Color Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    
    handles.corr_scale_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Linear' 'Logarithmic'}, 'Parent', param_layout );
    handles.corr_independent_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
        
    uiextras.Empty( 'Parent', param_layout);
        
    set( corr_layout, 'Sizes', [-1,70] );
    set( param_layout, 'ColumnSizes', [90 90 90 90 90 90] );
    set( param_layout, 'RowSizes', [22 22] );


end