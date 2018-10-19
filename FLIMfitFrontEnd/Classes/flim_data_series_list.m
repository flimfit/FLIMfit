classdef flim_data_series_list < handle
    
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

   
    properties
        handle;
        data_series_table;
        data_series_sel_all;
        data_series_sel_none;
        selected = 0;
        lh;
        
        data_source;
        has_use;
    end
    
    events
        selection_updated;
    end
    
    methods
    
        function obj = flim_data_series_list(handles,data_source)
                     
            
            assign_handles(obj,handles);
                        
            obj.handle = obj.data_series_table;

            set(obj.handle,'CellSelectionCallback',@obj.list_callback);
            set(obj.handle,'CellEditCallback',@obj.use_callback);
            
            if ~isempty(obj.data_series_sel_all)
                set(obj.data_series_sel_all,'Callback',@obj.sel_all_callback);
            end
            
            if nargin >= 2
                obj.set_source(data_source);
            end

            
            obj.selected = 1;
            obj.data_update();
            
        end
        
        function update_selection(obj,src,evtData)
            set(obj.handle,'Value',src.selected)
        end
        
        function list_callback(obj,src,evtData)            
            if ~isempty(evtData.Indices)
                sel = evtData.Indices(1);
                if ~isempty(sel)
                    if ~obj.has_use || evtData.Indices(2) > 1 % don't update on check 
                        obj.selected = sel;
                        notify(obj,'selection_updated');
                    end
                end
            end
        end
        
        function use_callback(obj,src,evtData)
           
            data = get(obj.handle,'Data');
            use = data(:,1);
            use = cell2mat(use);
            obj.data_source.use = use;
            
        end
        
        function sel_all_callback(obj,~,~)
            flim_data_selector(obj.data_source_controller);
        end
        
        function set_source(obj,data_source)
            obj.data_source = data_source;
            obj.has_use = isprop(obj.data_source, 'use');
            obj.lh = addlistener(obj.data_source,'use','PostSet',@(~,~) EC(@obj.use_update));
            obj.data_update();
        end
        
        function use_update(obj)
            use_new = obj.data_source.use;
            use_old = cell2mat(obj.handle.Data(:,1));
            if all(size(use_new)==size(use_old)) && ~all(use_new == use_old)
                obj.data_update();
            end
        end
        
        function data_update(obj)
            if ishandle(obj.handle)
                if ~isempty(obj.data_source) && ~isempty(obj.data_source.metadata)

                    data = obj.data_source.metadata;
                    n_field = width(data);
                    
                    headers = data.Properties.VariableNames;                    
                    fmt = repmat({'char'},[1,n_field]);                    
                    edit = false(1,n_field);
                    col_width = repmat({'auto'},[1,n_field]);
                    
                    if obj.has_use
                        checked = table(obj.data_source.use,'VariableNames',{'Use'});
                        headers = [{''} headers];
                        data = [checked data];
                        edit = [true edit];
                        fmt = [{'logical'} fmt];
                        col_width = [{24} col_width];
                    end
                    
                    data = table2cell(data);
                    set(obj.handle,'ColumnFormat',fmt,'ColumnEditable',edit,...
                        'ColumnName',headers,'Data',data);

                    wold = get(obj.handle,'ColumnWidth');
                    if ischar(wold) % only set once
                        set(obj.handle,'ColumnWidth',col_width);
                    end
                    
                    if isempty(obj.selected) || obj.selected > size(data,1)  || obj.selected == 0
                        sel = 1;
                        obj.selected = sel;
                        
                        obj.notify('selection_updated');
                    end

                else
                    obj.selected = 0;
                    obj.notify('selection_updated');
                end
            end
        end
        
    end
end