function flim_data_selector(data_series_controller)

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


    fig = figure('Toolbar','none','Name','Select Data');
    
    handles = struct('data_series_controller',data_series_controller);
    
    layout = uix.HBox( 'Parent', fig );
    
    handles.data_series_table = uitable( 'Parent', layout );

    right_layout = uix.VBox( 'Parent', layout );

    button_layout_top = uix.HBox( 'Parent', right_layout );    
    handles.sel_all_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Select All', 'Parent', button_layout_top );
    handles.desel_all_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Deselect All', 'Parent', button_layout_top );

    
    handles.filter_table = uitable( 'Parent', right_layout );

    button_layout_bottom = uix.HBox( 'Parent', right_layout );    
    handles.sel_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Select', 'Parent', button_layout_bottom );
    handles.desel_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Deselect', 'Parent', button_layout_bottom );
    
    set(handles.sel_pushbutton,'Callback',@select_filtered);
    set(handles.desel_pushbutton,'Callback',@deselect_filtered);
    set(handles.sel_all_pushbutton,'Callback',@select_all);
    set(handles.desel_all_pushbutton,'Callback',@deselect_all);
    
    uix.Empty('Parent', right_layout);
    
    set(layout,'Widths',[-1 250])
    set(right_layout,'Heights',[30 250 30 -1])
    
    handles.flim_data_series_list = flim_data_series_list(handles);
   
    
    empty_data = repmat({'','',''},[10 1]);                
    set(handles.filter_table,'ColumnName',{'Param','Type','Value'})
    set(handles.filter_table,'Data',empty_data)
    set(handles.filter_table,'ColumnEditable',true(1,3));
    %set(handles.filter_table,'CellEditCallback',@filter_table_updated);
    set(handles.filter_table,'RowName',[]);
    
    update_filter_table();
    
    function update_filter_table()
                  
        data_series = handles.data_series_controller.data_series;
        md = data_series.metadata;

        set(handles.filter_table,'ColumnFormat',{[{'-'} fieldnames(md)'],{'=','!=','<','>'},'char'})
        
    end

    function select_filtered(obj,~,~)
        d = handles.data_series_controller.data_series;
        d.use = d.use | get_sel();
    end

    function deselect_filtered(obj,~,~)
        d = handles.data_series_controller.data_series;
        d.use = d.use & ~get_sel();
    end

    function select_all(obj,~,~)
        d = handles.data_series_controller.data_series;
        d.use = true(size(d.use));
    end

    function deselect_all(obj,~,~)
        d = handles.data_series_controller.data_series;
        d.use = false(size(d.use));
    end

    function sel = get_sel()

        data = get(handles.filter_table,'Data');
        d = handles.data_series_controller.data_series;
        
        sel = ones(1,d.n_datasets);

        md = d.metadata;

        for i=1:size(data,1)

            if all(cellfun(@isempty,data(i,:)))==0 && ~strcmp(data{i,1},'-')

                field = data{i,1};
                op_str = data{i,2};
                val = data{i,3};

                m = md.(field);
                var_is_numeric = all(cellfun(@isnumeric,m));

                if var_is_numeric

                    m = cell2mat(m);
                    val = str2double(val);

                    switch op_str
                        case '='
                            op = @eq;
                        case '!='
                            op = @ne;
                        case '<'
                            op = @lt;
                        case '>'
                            op = @gt;
                        otherwise
                            op = [];
                    end

                    if ~isempty(op)
                        sel = sel & op(m,val);
                    end
                else

                    switch op_str
                        case '='
                            op = @strcmp;
                        case '!='
                            op = @(x,y) (1-strcmp(x,y));
                        otherwise
                            op = [];
                    end

                    if ~isempty(op)
                        sel = sel & cellfun(@(x)op(val,x),m);
                    end

                end



            end

        end
        
        sel = sel';

    end
    
end