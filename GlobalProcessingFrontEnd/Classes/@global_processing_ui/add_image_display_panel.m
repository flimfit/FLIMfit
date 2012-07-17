function handles = add_image_display_panel(obj,handles,parent)

    % Plot display
    handles.plot_panel = uipanel( 'Parent', parent );
    
    
    % Gallery display
    
    gallery_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );

    gallery_layout_top = uiextras.HBox( 'Parent', gallery_layout, 'Spacing', 0 );
    
    handles.gallery_panel = uipanel( 'Parent', gallery_layout_top, 'BorderType', 'none' );
    handles.gallery_slider = uicontrol( 'Parent', gallery_layout_top, 'Style', 'slider' );
    
    set( gallery_layout_top, 'Sizes', [-1 22] );
    
    bottom_layout = uiextras.Grid( 'Parent', gallery_layout, 'Spacing', 3 );
    
    uicontrol( 'Style', 'text', 'String', 'Image', 'Parent', bottom_layout );
    uicontrol( 'Style', 'text', 'String', 'Columns', 'Parent', bottom_layout );
    
    handles.gallery_param_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', '-', 'Parent', bottom_layout);
    handles.gallery_cols_edit = uicontrol( 'Style', 'edit', 'String', '6', 'Parent', bottom_layout);
    
    uicontrol( 'Style', 'text', 'String', 'Text Overlay', 'Parent', bottom_layout );
    uicontrol( 'Style', 'text', 'String', 'Unit', 'Parent', bottom_layout );
    
    handles.gallery_overlay_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', '-', 'Parent', bottom_layout);
    handles.gallery_unit_edit = uicontrol( 'Style', 'edit', 'String', '', 'Parent', bottom_layout);
    
    uicontrol( 'Style', 'text', 'String', 'Intensity Merge', 'Parent', bottom_layout );
    uiextras.Empty( 'Parent', bottom_layout );
    
    handles.gallery_merge_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No', 'Yes'}, 'Parent', bottom_layout);
        
    set( bottom_layout, 'ColumnSizes',[90 120 90 120 90 120], 'RowSizes', [22 22] );
    
    
    set(gallery_layout,'Sizes',[-1,60]);
    
    
end