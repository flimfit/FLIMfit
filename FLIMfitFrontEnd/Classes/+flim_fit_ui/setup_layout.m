function handles = setup_layout(window, handles)

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


    % Start layout
    %---------------------------------------
    top_layout = uix.HBoxFlex( 'Parent', window, 'Spacing', 5, 'Padding', 0, 'DividerMarkings', 'on' );
    mid_layout = uix.VBoxFlex( 'Parent', top_layout, 'Spacing', 5, 'Padding', 0, 'DividerMarkings', 'on' );
    
    fitting_panel = uix.BoxPanel( 'Parent', top_layout, 'Title', 'Fitting Options' );
    left_layout = uix.VBox( 'Parent', fitting_panel, 'Spacing', 5, 'Padding', 0 );
    

    % Decay Display
    %---------------------------------------
    
    right_layout = uix.VBoxFlex( 'Parent', top_layout );
    
    topright_layout = uix.HBox( 'Parent', right_layout );
            
    display_tabpanel = uix.TabPanel( 'Parent', topright_layout, 'TabWidth', 80 );
    handles.display_tabpanel = display_tabpanel;
    
    handles = flim_fit_ui.add_decay_display_panel(handles,display_tabpanel);
    handles = flim_fit_ui.add_table_display_panel(handles,display_tabpanel);
    handles = flim_fit_ui.add_image_display_panel(handles,display_tabpanel);
    handles = flim_fit_ui.add_hist_corr_display_panel(handles,display_tabpanel);
    handles = flim_fit_ui.add_plotter_display_panel(handles,display_tabpanel);

    set(display_tabpanel, 'TabTitles', {'Decay','Parameters','Images','Gallery','Histogram','Correlation','Plotter','Plate'});
    set(display_tabpanel, 'Selection', 1);
    
    display_params_panel = uix.VBox( 'Parent', topright_layout );
    
    col_names = {'Plot','Display','Merge','Min','Max','Auto'};
    col_width = {60 30 30 50 50 30};
    handles.plot_select_table = uitable( 'ColumnName', col_names, 'ColumnWidth', col_width, 'RowName', [], 'Parent', display_params_panel );
    handles.filter_table = uitable( 'Parent', display_params_panel );

    colormap_panel = uix.Grid( 'Parent', display_params_panel, 'Spacing', 0 );
    
    uicontrol( 'Style', 'text', 'String', 'Invert Colorscale? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel );
    uicontrol( 'Style', 'text', 'String', 'Display Colormap? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel );
    uicontrol( 'Style', 'text', 'String', 'Display Limits? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel );
    handles.invert_colormap_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No','Yes'}, 'Parent', colormap_panel );    
    handles.show_colormap_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No','Yes'}, 'Parent', colormap_panel, 'Value', 2 );    
    handles.show_limits_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No','Yes'}, 'Parent', colormap_panel, 'Value', 2 );    
    
    set(colormap_panel, 'Widths', [-1 -1], 'Heights', [22 22 22]);
    set(display_params_panel, 'Heights', [-1.5 -1 76] );
    
    set( topright_layout, 'Widths', [-1, 0] );
   
    function display_panel_callback(~,src,~)
        
        
        %kluge! setting topright layout to -1 0  seems to  hide platemap when colored
        %histograms are selected ??
        
        if src.NewValue < 8 
            % don't set platemap in this way
            set( topright_layout, 'Widths', [-1, 0] )
        end
        
        
        if src.NewValue > 2
      
            set( topright_layout, 'Widths', [-1, 253] )
        end
    end
    
    set( display_tabpanel, 'SelectionChangedFcn', @display_panel_callback );
    
    % Progress Panel
    %---------------------------------------
    progress_panel = uix.BoxPanel( 'Parent', right_layout, 'Title', 'Progress' );
    handles.progress_table = uitable( 'Parent', progress_panel );
    
    set( right_layout, 'Heights', [-1,110] );
    
    % Dataset Panel
    %---------------------------------------
        
    dataset_panel = uix.BoxPanel( 'Parent', mid_layout, 'Title', 'Dataset' );
    dataset_layout = uix.VBoxFlex( 'Parent', dataset_panel, 'Padding', 3, 'Spacing', 5 );

    % Intensity View
    %---------------------------------------
    intensity_layout = uix.VBox( 'Parent', dataset_layout, 'Spacing', 3 );
    
    intensity_opts_layout = uix.HBox( 'Parent', intensity_layout, 'Spacing', 3 );
    handles.intensity_mode_limits_text = uicontrol( 'Style', 'text', 'String', ' ', 'Parent', intensity_opts_layout, ...
               'HorizontalAlignment', 'left' );
    uicontrol( 'Style', 'text', 'String', 'Mode ', 'Parent', intensity_opts_layout, ...
               'HorizontalAlignment', 'right' );
    handles.intensity_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Integrated Intensity','Background','TVB Intensity Map','SV IRF','IRF Shift Map','Intensity Ratio'}, 'Parent', intensity_opts_layout );
    
    set( intensity_opts_layout, 'Widths', [80,-1,200] );
    
    
    intensity_container = uicontainer( 'Parent', intensity_layout ); 
    handles.intensity_axes = axes( 'Parent', intensity_container );
    set(handles.intensity_axes,'Units','normalized','Position',[0.02 0.02 0.94 0.94]);
    set( intensity_layout, 'Heights', [22,-1] );

    
    
    dataset_layout_left = uix.VBox( 'Parent', dataset_layout, 'Padding', 3 );
    handles.data_series_table = uitable( 'Parent', dataset_layout_left );
    
    handles.data_series_sel_all = uicontrol( 'Style', 'pushbutton', 'String', 'Select Multiple...', 'Parent', dataset_layout_left );
    
    set( dataset_layout_left, 'Heights', [-1,22] );
    
    set( dataset_layout, 'Heights', [-1,-2], 'MinimumHeights', [150 0] );

    
    % Data Transformation Panel
    %---------------------------------------
    handles = flim_fit_ui.add_data_transformation_panel(handles,left_layout);
 
    
    % Fitting Params Panel
    %---------------------------------------
    handles = flim_fit_ui.add_fitting_params_panel(handles, left_layout);

    fit_button_layout = uix.HBox( 'Parent', left_layout, 'Spacing', 3 );
    
    handles.binned_fit_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Fit Selected Decay', 'Parent', fit_button_layout );
    handles.fit_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Fit Dataset', 'Parent', fit_button_layout );

    set(fit_button_layout,'Widths',[-1,-2]);
    
    set(left_layout,'Heights',[125,-1,30])
    
        
    set(top_layout,'Widths',[-1, 500, -2],'MinimumWidths',[200, 500, 0]);
    

%    dragzoom([handles.highlight_axes handles.residuals_axes])
       
end