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
    layout = uigridlayout(obj.window, [1 3], 'ColumnSpacing', 5, 'Padding', 0, 'ColumnWidth', {'1x', 500, '2x'});
    
    dataset_panel = uipanel('Parent', layout, 'Title', 'Dataset');
    dataset_layout = uigridlayout(dataset_panel, [4,1], 'Padding', 3, 'RowSpacing', 5, 'ColumnSpacing', 5, 'RowHeight', {22,'1x','2x',22});%, 'MinimumHeights', [150 0]);
    
    fitting_panel = uipanel('Parent', layout, 'Title', 'Fitting Options');
    fitting_layout = uigridlayout(fitting_panel, [3,1], 'RowSpacing', 5, 'Padding', 0, 'RowHeight', {125,'1x',30});
   
    right_panel = uipanel('Parent', layout);
    right_layout = uigridlayout(right_panel, [2,1], 'RowHeight', {'1x', 110}, 'Padding', 0, 'RowSpacing', 0);

    % Results Panel
    %---------------------------------------
    handles = obj.add_results_display(right_layout, handles);
    
    % Progress Panel
    %---------------------------------------
    progress_panel = uipanel('Parent', right_layout, 'Title', 'Progress');
    progress_layout = uigridlayout(progress_panel, [1 1], 'Padding', 0);
    handles.progress_table = uitable('Parent', progress_layout);
            

    % Intensity View
    %---------------------------------------    
    intensity_opts_layout = uigridlayout(dataset_layout, [1,3], 'Padding', 0, 'ColumnSpacing', 3, 'ColumnWidth', {22, 22, 22, '1x', 200});
    
    handles.tool_roi_rect_toggle = uibutton(intensity_opts_layout,'state','Icon',['Icons' filesep 'rect_icon.png']);
    handles.tool_roi_poly_toggle = uibutton(intensity_opts_layout,'state','Icon',['Icons' filesep 'poly_icon.png']);
    handles.tool_roi_circle_toggle = uibutton(intensity_opts_layout,'state','Icon',['Icons' filesep 'ellipse_icon.png']);
    
    
    handles.intensity_mode_limits_text = uilabel('Text', ' ', 'Parent', intensity_opts_layout, 'HorizontalAlignment', 'left');
    handles.intensity_mode_popupmenu = uidropdown('Items', {'Integrated Intensity','Background','TVB Intensity Map','SV IRF','IRF Shift Map','Intensity Ratio'}, 'Parent', intensity_opts_layout);
            
    intensity_container = uipanel('Parent', dataset_layout, 'AutoResizeChildren', false, 'BorderType', 'none'); 
    handles.intensity_axes = axes('Parent', intensity_container);
    set(handles.intensity_axes,'Units','normalized','Position',[0 0 1 1]);
    
    handles.data_series_table = uitable('Parent', dataset_layout);
    
    handles.data_series_sel_all = uibutton('Text', 'Select Multiple...', 'Parent', dataset_layout);
        
    % Data Transformation Panel
    %---------------------------------------
    handles = obj.add_data_transformation_panel(handles,fitting_layout);
 
    
    % Fitting Params Panel
    %---------------------------------------
    handles = obj.add_fitting_params_panel(handles, fitting_layout);

    fit_button_layout = uigridlayout(fitting_layout, [1,2], 'ColumnSpacing', 3, 'Padding', 3, 'ColumnWidth', {'1x', '2x'});
    
    handles.binned_fit_pushbutton = uibutton('Text', 'Fit Selected Decay', 'Parent', fit_button_layout);
    handles.fit_pushbutton = uibutton('Text', 'Fit Dataset', 'Parent', fit_button_layout);
            
%    set(top_layout,'Widths',[-1, 500, -2],'MinimumWidths',[200, 500, 0]);
    

%    dragzoom([handles.highlight_axes handles.residuals_axes])
       
end