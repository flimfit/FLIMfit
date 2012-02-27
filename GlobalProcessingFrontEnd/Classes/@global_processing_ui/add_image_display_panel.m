function handles = add_image_display_panel(obj,handles,parent)

    % Plot display

    %image_layout = uiextras.HBox( 'Parent', parent, 'Spacing', 3 );
    
    %left_layout = uiextras.VBox( 'Parent', image_layout, 'Spacing', 3 );
    %{
    col_names = {'Plot','Display','Merge','Min','Max','Auto'};
    col_width = {60 30 30 50 50 30};
    handles.plot_select_table = uitable( 'ColumnName', col_names, 'ColumnWidth', col_width, 'RowName', [], 'Parent', left_layout );
    %}   
    handles.plot_panel = uipanel( 'Parent', parent );
    
    %set(image_layout,'Sizes',[253,-1]);
    
    
    % Gallery display
    
    gallery_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.gallery_panel = uipanel( 'Parent', gallery_layout );
    
    
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