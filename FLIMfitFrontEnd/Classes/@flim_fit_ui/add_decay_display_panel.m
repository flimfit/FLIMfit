function handles = add_decay_display_panel(obj,handles,parent)

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


    decay_layout = uix.VBox( 'Parent', parent, 'Spacing', 3 );
    
    decay_display_layout = uix.HBox( 'Parent', decay_layout, 'Spacing', 3 );
    handles.decay_pos_text = uicontrol( 'Style', 'text', 'String', '   ', 'Parent', decay_display_layout, ...
               'HorizontalAlignment', 'left' );
    uicontrol( 'Style', 'text', 'String', 'Show smoothed?  ', 'Parent', decay_display_layout, ...
               'HorizontalAlignment', 'right' );
    handles.display_smoothed_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'No','Yes'}, 'Parent', decay_display_layout );
    uicontrol( 'Style', 'text', 'String', 'Mode  ', 'Parent', decay_display_layout, ...
               'HorizontalAlignment', 'right' );
    handles.highlight_decay_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Intensity Decay','Raw IRF','TV Background','Magic Angle','Anisotropy Decay','G Factor'}, 'Parent', decay_display_layout );
    uicontrol( 'Style', 'text', 'String', 'Display  ', 'Parent', decay_display_layout, ...
               'HorizontalAlignment', 'right' );
    handles.highlight_display_mode_popupmenu = uicontrol( 'Style', 'popupmenu', ...
            'String', {'Linear' 'Logarithmic'}, 'Parent', decay_display_layout );
    
        
    set( decay_display_layout, 'Widths', [-1,50,100,50,100,50,100] );
    
    handles.decay_panel = uipanel( 'Parent', decay_layout );
    set( decay_layout, 'Heights', [22,-1] );
    
end