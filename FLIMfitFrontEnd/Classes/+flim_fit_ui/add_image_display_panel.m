function handles = add_image_display_panel(handles,parent)

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


    % Plot display
    handles.plot_panel = uipanel( 'Parent', parent );
    handles.plot_axes = axes('Parent',handles.plot_panel);
    
    
    % Gallery display
    
    gallery_layout = uix.VBox( 'Parent', parent, 'Spacing', 3 );

    gallery_layout_top = uix.HBox( 'Parent', gallery_layout, 'Spacing', 0 );
    
    handles.gallery_panel = uipanel( 'Parent', gallery_layout_top, 'BorderType', 'none' );
    handles.gallery_slider = uicontrol( 'Parent', gallery_layout_top, 'Style', 'slider' );
    
    set( gallery_layout_top, 'Widths', [-1 22] );
    
    bottom_layout = uix.Grid( 'Parent', gallery_layout, 'Spacing', 3 );
    
    uicontrol( 'Style', 'text', 'String', 'Image', 'Parent', bottom_layout );
    uicontrol( 'Style', 'text', 'String', 'Columns', 'Parent', bottom_layout );
    
    handles.gallery_param_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', '-', 'Parent', bottom_layout);
    handles.gallery_cols_edit = uicontrol( 'Style', 'edit', 'String', '6', 'Parent', bottom_layout);
    
    uicontrol( 'Style', 'text', 'String', 'Text Overlay', 'Parent', bottom_layout );
    uicontrol( 'Style', 'text', 'String', 'Unit', 'Parent', bottom_layout );
    
    handles.gallery_overlay_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', '-', 'Parent', bottom_layout);
    handles.gallery_unit_edit = uicontrol( 'Style', 'edit', 'String', '', 'Parent', bottom_layout);
    
    uicontrol( 'Style', 'text', 'String', 'Intensity Merge', 'Parent', bottom_layout );
    uix.Empty( 'Parent', bottom_layout );
    
    handles.gallery_merge_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No', 'Yes'}, 'Parent', bottom_layout);
        
    set( bottom_layout, 'Widths',[90 90 90 90 90 90], 'Heights', [22 22] );
    
    
    set(gallery_layout,'Heights',[-1,70]);
    
    
end