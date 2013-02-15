global fh;

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


if ~isempty(fh)
    close(fh)
end

fh = figure();


layout = uiextras.VBox( 'Padding', 3, 'Spacing', 3, 'Parent', fh );

l2 = uiextras.HBox( 'Spacing', 3, 'Padding', 3, 'Parent', layout );

uitable( 'Parent', l2 );
l3 = uiextras.Grid( 'Padding', 3, 'Spacing', 3, 'Parent', l2 );

set(l2,'Sizes',[-1 300]);

uicontrol( 'Style', 'text', 'String', 'Data Type ', 'HorizontalAlignment', 'right', 'Parent', l3 );
uicontrol( 'Style', 'text', 'String', 'Rep Rate (MHz) ', 'HorizontalAlignment', 'right', 'Parent', l3 );
uiextras.Empty( 'Parent', l3 )
uicontrol( 'Style', 'text', 'String', 'Channel ', 'HorizontalAlignment', 'right', 'Parent', l3 );

uicontrol( 'Style', 'popupmenu', 'String', {'TCSPC','Widefield'}, 'Parent', l3 );
uicontrol( 'Style', 'edit', 'String', '80', 'Parent', l3 );
uiextras.Empty( 'Parent', l3 )
uicontrol( 'Style', 'popupmenu', 'String', {''}, 'Parent', l3 );

set( l3, 'RowSizes', [22 22 22], 'ColumnSizes', [100, -1])

%set(layout,'Sizes',[22 -1]);

