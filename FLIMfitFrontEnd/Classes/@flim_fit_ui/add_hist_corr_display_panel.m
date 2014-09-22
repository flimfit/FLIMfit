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


    hist_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.hist_axes = axes('Parent',hist_layout);
    
   
    opt_layout = uiextras.Grid( 'Parent', hist_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Parameter  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Weighting  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    handles.hist_param_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', opt_layout );
    handles.hist_weighting_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'None' 'Intensity Weighted'}, 'Parent', opt_layout );
      
    uicontrol( 'Style', 'text', 'String', 'Classes  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Source Data  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );

    handles.hist_classes_edit = uicontrol( 'Style', 'edit', ...
            'String', '100', 'Parent', opt_layout );
    handles.hist_source_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Selected Image' 'All Filtered'}, 'Parent', opt_layout );
        
    uicontrol( 'Style', 'text', 'String', 'Add False Colour  ', 'Parent', opt_layout, ...
               'HorizontalAlignment', 'right' );
    uiextras.Empty( 'Parent', opt_layout );
        
    handles.hist_addcolour_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'On' 'Off'}, 'Parent', opt_layout );
   uiextras.Empty( 'Parent', opt_layout );
    
    set( hist_layout, 'Sizes', [-1,70] );
    set( opt_layout, 'ColumnSizes', [90 90 90 90 90 90]);
    set( opt_layout, 'RowSizes', [22 22]);


    
    
    corr_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.corr_axes = axes('Parent',corr_layout);
    
    param_layout = uiextras.Grid( 'Parent', corr_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'X Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
           uicontrol( 'Style', 'text', 'String', 'Y Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    handles.corr_param_x_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
    handles.corr_param_y_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
        
    uicontrol( 'Style', 'text', 'String', 'Source Data  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Plot  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
           
    handles.corr_source_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Selected Image' 'All Filtered'}, 'Parent', param_layout );
    handles.corr_display_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Pixels' 'Regions'}, 'Parent', param_layout );
    
    uicontrol( 'Style', 'text', 'String', 'Scale  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Color Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    
    handles.corr_scale_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Linear' 'Logarithmic'}, 'Parent', param_layout );
    handles.corr_independent_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
        
    uiextras.Empty( 'Parent', param_layout);
        
    set( corr_layout, 'Sizes', [-1,70] );
    set( param_layout, 'ColumnSizes', [90 90 90 90 90 90] );
    set( param_layout, 'RowSizes', [22 22] );


end