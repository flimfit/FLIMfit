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


    layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
    handles.graph_axes = axes('Parent',layout);
    
    param_layout = uiextras.Grid( 'Parent', layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Label  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
           
    handles.graph_independent_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
    handles.graph_dependent_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
        
    uicontrol( 'Style', 'text', 'String', 'Combine  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Error bars  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    
    handles.graph_grouping_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'By Pixel' 'By Region' 'By FOV' 'By Well'}, 'Parent', param_layout );       
    handles.error_type_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Standard Deviation', 'Standard Error', '95% Confidence'}, 'Parent', param_layout );
        
    uicontrol( 'Style', 'text', 'String', 'Display  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
%     uiextras.Empty( 'Parent', param_layout );
    uicontrol( 'Style', 'text', 'String', 'Data cursor  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
           
    handles.graph_display_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Line' 'Line with Scatter' 'Box Plot'}, 'Parent', param_layout );       
%     uiextras.Empty( 'Parent', param_layout );
    handles.graph_dcm_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Off' 'Datatip' 'Window'}, 'Parent', param_layout ); 
    
        
    set( param_layout, 'RowSizes', [22,22] );
    set( param_layout, 'ColumnSizes', [90,90,90,90,90,90] );
    
    set( layout, 'Sizes', [-1 70]) 
    
    
    plate_layout = uiextras.VBox( 'Parent', parent, 'Spacing', 3 );
    
        
    plate_container = uicontainer( 'Parent', plate_layout );
    handles.plate_axes = axes( 'Parent', plate_container );
    
    param_layout = uiextras.Grid( 'Parent', plate_layout, 'Spacing', 3 );
    uicontrol( 'Style', 'text', 'String', 'Parameter  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uicontrol( 'Style', 'text', 'String', 'Mode  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    handles.plate_param_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {''}, 'Parent', param_layout );
    handles.plate_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Well Average','First Image'}, 'Parent', param_layout );
    uicontrol( 'Style', 'text', 'String', 'Intensity merge  ', 'Parent', param_layout, ...
               'HorizontalAlignment', 'right' );
    uiextras.Empty( 'Parent', param_layout);
    handles.plate_merge_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'No','Yes'}, 'Parent', param_layout );
    
    set( param_layout, 'RowSizes', [22,22] );
    set( param_layout, 'ColumnSizes', [100,100,100,100] );
    
    set( plate_layout, 'Sizes', [-1 70])
    
    
    
    

end