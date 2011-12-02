function handles = add_table_display_panel(obj,handles,parent)

    layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
        
    % Results Panel
    %---------------------------------------
    handles.results_table = uitable( 'Parent', layout );
    
end