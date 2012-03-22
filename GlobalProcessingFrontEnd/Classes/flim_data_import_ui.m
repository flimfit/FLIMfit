global fh;

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

