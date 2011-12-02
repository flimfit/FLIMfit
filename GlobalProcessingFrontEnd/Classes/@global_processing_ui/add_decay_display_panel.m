function handles = add_decay_display_panel(obj,handles,parent)

    decay_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    decay_display_layout = uiextras.HBox( 'Parent', decay_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Mode  ', 'Parent', decay_display_layout, ...
               'HorizontalAlignment', 'right' );
    handles.highlight_decay_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Decay','Raw IRF','TV Background','Magic Angle','Anisotropy Decay','G Factor'}, 'Parent', decay_display_layout );
    uicontrol( 'Style', 'text', 'String', 'Display  ', 'Parent', decay_display_layout, ...
               'HorizontalAlignment', 'right' );
    handles.highlight_display_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Linear' 'Logarithmic'}, 'Parent', decay_display_layout );
    set( decay_display_layout, 'Sizes', [-1,100,50,100] );
    
    handles.highlight_axes = axes('Parent', decay_layout);
    handles.residuals_axes = axes('Parent', decay_layout);
    set( decay_layout, 'Sizes', [22,-3,-1] );
    
end