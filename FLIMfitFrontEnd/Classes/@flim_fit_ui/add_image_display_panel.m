function handles = add_image_display_panel(obj,handles,parent)

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
    tab = uitab('Parent', parent, 'Title', 'Images');
    plot_layout = uigridlayout(tab, [1 1], 'Padding', 5);
    handles.plot_panel = uipanel('Parent', plot_layout, 'BorderType', 'none');
    %handles.plot_axes = axes('Parent',handles.plot_panel);
    
    
    % Gallery display
    tab = uitab('Parent', parent, 'Title', 'Gallery');
    gallery_layout = uigridlayout(tab, [2,1], 'RowSpacing', 3, 'Padding', 5, 'RowHeight', {'1x',70});

    gallery_layout_top = uigridlayout(gallery_layout, [1,2], 'Padding', 0, 'ColumnWidth', {'1x', 22});
      
    handles.gallery_panel = uipanel('Parent', gallery_layout_top, 'BorderType', 'none');
    handles.gallery_slider = uislider('Parent', gallery_layout_top, 'Orientation', 'vertical');
        
    bottom_layout = uigridlayout(gallery_layout, [2,6], 'RowSpacing', 3, 'ColumnSpacing', 3, 'Padding', 0, 'RowHeight', {22 22}, 'ColumnWidth', {90 90 90 90 90 90});
    
    uilabel('Text', 'Image', 'Parent', bottom_layout);
    handles.gallery_param_popupmenu = uidropdown('Items', {'-'}, 'Parent', bottom_layout);

    uilabel('Text', 'Intensity Merge', 'Parent', bottom_layout);
    handles.gallery_merge_popupmenu = uidropdown('Items', {'No', 'Yes'}, 'Parent', bottom_layout);

    uilabel('Text', 'Columns', 'Parent', bottom_layout);
    handles.gallery_cols_edit = uieditfield('Value', '6', 'Parent', bottom_layout);
    
    uilabel('Text', 'Text Overlay', 'Parent', bottom_layout);
    handles.gallery_overlay_popupmenu = uidropdown('Items', {'-'}, 'Parent', bottom_layout);
    
    uilabel('Text', 'Unit', 'Parent', bottom_layout);
    handles.gallery_unit_edit = uieditfield('Value', '', 'Parent', bottom_layout);
    
            
        
    
end