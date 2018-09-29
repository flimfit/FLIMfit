function handles = add_results_display(obj,parent,handles)

    layout = uigridlayout(parent, [1,2], 'ColumnWidth', {'1x', 0}, 'Padding', 0, 'ColumnSpacing', 3);
            
    display_tabpanel = uitabgroup('Parent', layout);
    handles.display_tabpanel = display_tabpanel;
    
    handles = obj.add_decay_display_panel(handles,display_tabpanel);
    handles = obj.add_table_display_panel(handles,display_tabpanel);
    handles = obj.add_image_display_panel(handles,display_tabpanel);
    handles = obj.add_hist_corr_display_panel(handles,display_tabpanel);
    handles = obj.add_plotter_display_panel(handles,display_tabpanel);
    
    display_params_panel = uigridlayout(layout, [3,1], 'Padding', 0, 'RowHeight', {'1.5x' '1x' 81});
    
    col_names = {'Plot','Display','Merge','Min','Max','Auto'};
    col_width = {60 30 30 50 50 30};
    handles.plot_select_table = uitable('ColumnName', col_names, 'ColumnWidth', col_width, 'RowName', [], 'Parent', display_params_panel);
    handles.filter_table = uitable('Parent', display_params_panel);

    colormap_panel = uigridlayout(display_params_panel, [3,2], 'Padding', 3, 'RowSpacing', 3, 'ColumnSpacing', 3, 'RowHeight', {22 22 22}, 'ColumnWidth', {'1x', '1x'});
    
    uilabel('Text', 'Invert Colorscale? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel);
    handles.invert_colormap_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', colormap_panel);    
    
    uilabel('Text', 'Display Colormap? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel);
    handles.show_colormap_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', colormap_panel, 'Value', 'Yes');

    uilabel('Text', 'Display Limits? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel);
    handles.show_limits_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', colormap_panel, 'Value', 'Yes');
           
    function display_panel_callback(~,src,~)
        if src.NewValue == handles.decay_tab || src.NewValue == handles.results_tab
            widths = {'1x', 0};
        else
            widths = {'1x', 253};
        end
        layout.ColumnWidth = widths;
    end
    
    display_tabpanel.SelectionChangedFcn = @display_panel_callback;
    
end