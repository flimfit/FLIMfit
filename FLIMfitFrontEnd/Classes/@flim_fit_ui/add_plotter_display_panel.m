function handles = add_plotter_display_panel(obj,handles,parent)

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

    tab = uitab('Parent', parent, 'Title', 'Plotter');
    layout = uigridlayout(tab, [2,1], 'Padding', 5, 'RowSpacing', 3, 'RowHeight', {'1x', 70});
    
    panel = uipanel('Parent', layout, 'BorderType', 'none');
    handles.graph_axes = axes('Parent', panel, 'Visible', false);
    
    param_layout = uigridlayout(layout, [2,8], 'Padding', 0, 'RowSpacing', 3, 'ColumnSpacing', 3, 'RowHeight', {22 22}, 'ColumnWidth', {90,90,90,90,90,90,90,90});
    
    uilabel('Text', 'Label  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.graph_independent_popupmenu = uidropdown('Items', {''}, 'Parent', param_layout);
    
    uilabel('Text', 'Parameter  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.graph_dependent_popupmenu = uidropdown('Items', {''}, 'Parent', param_layout);
        
    uilabel('Text', 'Combine  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.graph_grouping_popupmenu = uidropdown('Items', {'By Pixel' 'By Region' 'By FOV' 'By Well'}, 'Parent', param_layout);       
    
    uilabel('Text', 'Weighting  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.graph_weighting_popupmenu = uidropdown('Items', {'None','Intensity Weighted'}, 'Parent', param_layout);       
        
    uilabel('Text', 'Error bars  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.error_type_popupmenu = uidropdown('Items', {'Standard Deviation', 'Standard Error', '95% Confidence'}, 'Parent', param_layout);
    
    uilabel('Text', 'Display  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.graph_display_popupmenu = uidropdown('Items', {'Line' 'Line with Scatter' 'Box Plot'}, 'Parent', param_layout);       
    
    uilabel('Text', 'Data cursor  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.graph_dcm_popupmenu = uidropdown('Items', {'Off' 'Datatip' 'Window'}, 'Parent', param_layout); 
    
    % Plate display
    tab = uitab('Parent', parent, 'Title', 'Plate');
    plate_layout = uigridlayout(tab, [2,1], 'Padding', 5, 'RowSpacing', 3, 'RowHeight', {'1x', 70});
        
    plate_container = uipanel('Parent', plate_layout, 'BorderType', 'none');
    handles.plate_axes = axes('Parent', plate_container, 'Visible', false);
    
    param_layout = uigridlayout(plate_layout, [2,4], 'Padding', 0, 'RowSpacing', 3, 'ColumnSpacing', 3, 'RowHeight', {22 22}, 'ColumnWidth', {100 100 100 100});

    uilabel('Text', 'Parameter  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.plate_param_popupmenu = uidropdown('Items', {''}, 'Parent', param_layout);
    
    uilabel('Text', 'Mode  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.plate_mode_popupmenu = uidropdown('Items', {'Well Average','First Image'}, 'Parent', param_layout);
    
    uilabel('Text', 'Intensity merge  ', 'Parent', param_layout, 'HorizontalAlignment', 'right');
    handles.plate_merge_popupmenu = uidropdown('Items', {'No','Yes'}, 'Parent', param_layout);
    
end