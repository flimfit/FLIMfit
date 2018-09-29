function handles = add_table_display_panel(obj,handles,parent)

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

    handles.results_tab = uitab('Parent', parent, 'Title', 'Results');
    layout = uigridlayout(handles.results_tab, [2,1], 'RowSpacing', 5, 'Padding', 5, 'RowHeight', {22,'1x'});
    top_layout = uigridlayout(layout, [1,2], 'ColumnSpacing', 3, 'Padding', 0, 'ColumnWidth', {90, 90});
        
    uilabel('Text', 'Statistic  ', 'Parent', top_layout, 'HorizontalAlignment', 'right');    
    handles.table_stat_popupmenu = uidropdown('Items', {''}, 'Parent', top_layout);     
    
    handles.results_table = uitable('Parent', layout);
        
end