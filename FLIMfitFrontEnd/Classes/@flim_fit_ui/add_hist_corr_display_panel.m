function handles = add_hist_corr_display_panel(obj,handles,parent)

    % Add Histograms controls
    %====================================
    
    
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


    tab = uitab('Parent', parent, 'Title', 'Histogram');
    hist_layout = uigridlayout(tab, [2,1], 'Padding', 5, 'RowSpacing', 3, 'RowHeight', {'1x', 70});
    
    panel = uipanel('Parent', hist_layout, 'BorderType', 'none');
    handles.hist_axes = axes('Parent', panel, 'Visible', false);
       
    opt_layout = uigridlayout(hist_layout, [2,6], 'Padding', 0, 'RowSpacing', 3, 'ColumnSpacing', 3, 'RowHeight', {22 22}, 'ColumnWidth', {90 90 90 90 90 90});
    
    uilabel('Text', 'Parameter  ', 'Parent', opt_layout, 'HorizontalAlignment', 'left');
    handles.hist_param_popupmenu = uidropdown('Items', {''}, 'Parent', opt_layout);
    
    uilabel('Text', 'Weighting  ', 'Parent', opt_layout, 'HorizontalAlignment', 'left');
    handles.hist_weighting_popupmenu = uidropdown('Items', {'Unweighted' 'Intensity Weighted'}, 'Parent', opt_layout);
      
    uilabel('Text', 'Classes  ', 'Parent', opt_layout, 'HorizontalAlignment', 'left');
    handles.hist_classes_edit = uieditfield('Value', '100', 'Parent', opt_layout);
    
    uilabel('Text', 'Source Data  ', 'Parent', opt_layout, 'HorizontalAlignment', 'left');
    handles.hist_source_popupmenu = uidropdown('Items', {'Selected Image' 'All Filtered'}, 'Parent', opt_layout);
        
    uilabel('Text', 'False Colour  ', 'Parent', opt_layout, 'HorizontalAlignment', 'left');
    handles.hist_addcolour_popupmenu = uidropdown('Items', {'On' 'Off'}, 'Parent', opt_layout);
    

    % Correlation tab
    tab = uitab('Parent', parent, 'Title', 'Correlation');    
    corr_layout = uigridlayout(tab, [2,1], 'Padding', 5, 'RowSpacing', 3, 'RowHeight', {'1x', 70});
    
    panel = uipanel('Parent', corr_layout, 'BorderType', 'none');
    handles.corr_axes = axes('Parent', panel, 'Visible', false);
    
    param_layout = uigridlayout(corr_layout, [2,1], 'Padding', 0, 'RowSpacing', 3, 'RowHeight', {22 22}, 'ColumnWidth', {90 90 90 90 90 90});
    
    uilabel('Text', 'X Parameter  ', 'Parent', param_layout, 'HorizontalAlignment', 'left');
    handles.corr_param_x_popupmenu = uidropdown('Items', {''}, 'Parent', param_layout);

    uilabel('Text', 'Y Parameter  ', 'Parent', param_layout, 'HorizontalAlignment', 'left');
    handles.corr_param_y_popupmenu = uidropdown('Items', {''}, 'Parent', param_layout);
        
    uilabel('Text', 'Source Data  ', 'Parent', param_layout, 'HorizontalAlignment', 'left');
    handles.corr_source_popupmenu = uidropdown('Items', {'Selected Image' 'All Filtered'}, 'Parent', param_layout);
    
    uilabel('Text', 'Plot  ', 'Parent', param_layout, 'HorizontalAlignment', 'left');       
    handles.corr_display_popupmenu = uidropdown('Items', {'Pixels' 'Regions'}, 'Parent', param_layout);
    
    uilabel('Text', 'Scale  ', 'Parent', param_layout, 'HorizontalAlignment', 'left');
    handles.corr_scale_popupmenu = uidropdown('Items', {'Linear' 'Logarithmic'}, 'Parent', param_layout);

    uilabel('Text', 'Color Parameter  ', 'Parent', param_layout, 'HorizontalAlignment', 'left');
    handles.corr_independent_popupmenu = uidropdown('Items', {''}, 'Parent', param_layout);

end