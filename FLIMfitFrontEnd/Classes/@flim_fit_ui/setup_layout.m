function handles = setup_layout(obj, handles)

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
    top_layout = uigridlayout('Parent', obj.window, 'ColumnSpacing', 5, 'Padding', 0, 'ColumnWidth', {'1x', 500, '2x'});
    mid_layout = uigridlayout('Parent', top_layout, 'RowSpacing', 5, 'Padding', 0); % 'DividerMarkings', 'on');
    
    fitting_panel = uipanel('Parent', top_layout, 'Title', 'Fitting Options');
    left_layout = uigridlayout('Parent', fitting_panel, 'RowSpacing', 5, 'Padding', 0, 'RowHeight', {125,'1x',30});
    

    % Decay Display
    %---------------------------------------
    
    right_layout = uigridlayout('Parent', top_layout, 'RowHeight', {'1x',110});
    topright_layout = uigridlayout('Parent', right_layout, 'ColumnWidth', {'1x', 0});
            
    display_tabpanel = uitabgroup('Parent', topright_layout);
    handles.display_tabpanel = display_tabpanel;
    
    handles = obj.add_decay_display_panel(handles,display_tabpanel);
    handles = obj.add_table_display_panel(handles,display_tabpanel);
    handles = obj.add_image_display_panel(handles,display_tabpanel);
    handles = obj.add_hist_corr_display_panel(handles,display_tabpanel);
    handles = obj.add_plotter_display_panel(handles,display_tabpanel);

    %set(display_tabpanel, 'Selection', 1);
    
    display_params_panel = uigridlayout('Parent', topright_layout, 'RowHeight', {'1.5x' '1x' 76});
    
    col_names = {'Plot','Display','Merge','Min','Max','Auto'};
    col_width = {60 30 30 50 50 30};
    handles.plot_select_table = uitable('ColumnName', col_names, 'ColumnWidth', col_width, 'RowName', [], 'Parent', display_params_panel);
    handles.filter_table = uitable('Parent', display_params_panel);

    colormap_panel = uigridlayout('Parent', display_params_panel, 'RowSpacing', 0, 'ColumnSpacing', 0, 'RowHeight', {22 22 22}, 'ColumnWidth', {'1x', '1x'});
    
    uilabel('Text', 'Invert Colorscale? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel);
    uilabel('Text', 'Display Colormap? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel);
    uilabel('Text', 'Display Limits? ', 'HorizontalAlignment', 'right', 'Parent', colormap_panel);
    handles.invert_colormap_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', colormap_panel);    
    handles.show_colormap_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', colormap_panel, 'Value', 'Yes');
    handles.show_limits_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', colormap_panel, 'Value', 'Yes');
           
    function display_panel_callback(~,src,~)
        
        
        %kluge! setting topright layout to -1 0  seems to  hide platemap when colored
        %histograms are selected ??
        
        if src.NewValue < 8 
            % don't set platemap in this way
            set(topright_layout, 'Widths', [-1, 0])
        end
        
        
        if src.NewValue > 2
      
            set(topright_layout, 'Widths', [-1, 253])
        end
    end
    
    set(display_tabpanel, 'SelectionChangedFcn', @display_panel_callback);
    
    % Progress Panel
    %---------------------------------------
    progress_panel = uipanel('Parent', right_layout, 'Title', 'Progress');
    handles.progress_table = uitable('Parent', progress_panel);
        
    % Dataset Panel
    %---------------------------------------       
    dataset_panel = uipanel('Parent', mid_layout, 'Title', 'Dataset');
    dataset_layout = uigridlayout('Parent', dataset_panel, 'Padding', 3, 'RowSpacing', 5, 'ColumnSpacing', 5, 'RowHeight', {'1x','2x'});%, 'MinimumHeights', [150 0]);

    % Intensity View
    %---------------------------------------
    intensity_layout = uigridlayout('Parent', dataset_layout, 'RowSpacing', 3, 'RowHeight', {22, '1x'});
    
    intensity_opts_layout = uigridlayout('Parent', intensity_layout, 'ColumnSpacing', 3, 'ColumnWidth', {80, '1x', 200});
    handles.intensity_mode_limits_text = uilabel('Text', ' ', 'Parent', intensity_opts_layout, 'HorizontalAlignment', 'left');
    uilabel('Text', 'Mode ', 'Parent', intensity_opts_layout, 'HorizontalAlignment', 'right');
    handles.intensity_mode_popupmenu = uidropdown('Items', {'Integrated Intensity','Background','TVB Intensity Map','SV IRF','IRF Shift Map','Intensity Ratio'}, 'Parent', intensity_opts_layout);
            
    intensity_container = uipanel('Parent', intensity_layout); 
    handles.intensity_axes = axes('Parent', intensity_container);
    set(handles.intensity_axes,'Units','normalized','Position',[0.02 0.02 0.94 0.94]);
    
    
    dataset_layout_left = uigridlayout('Parent', dataset_layout, 'Padding', 3, 'RowHeight', {'1x', 22});
    handles.data_series_table = uitable('Parent', dataset_layout_left);
    
    handles.data_series_sel_all = uibutton('Text', 'Select Multiple...', 'Parent', dataset_layout_left);
        
    
    % Data Transformation Panel
    %---------------------------------------
    handles = obj.add_data_transformation_panel(handles,left_layout);
 
    
    % Fitting Params Panel
    %---------------------------------------
    handles = obj.add_fitting_params_panel(handles, left_layout);

    fit_button_layout = uigridlayout('Parent', left_layout, 'ColumnSpacing', 3, 'ColumnWidth', {'1x', '2x'});
    
    handles.binned_fit_pushbutton = uibutton('Text', 'Fit Selected Decay', 'Parent', fit_button_layout);
    handles.fit_pushbutton = uibutton('Text', 'Fit Dataset', 'Parent', fit_button_layout);
        
        
%    set(top_layout,'Widths',[-1, 500, -2],'MinimumWidths',[200, 500, 0]);
    

%    dragzoom([handles.highlight_axes handles.residuals_axes])
       
end