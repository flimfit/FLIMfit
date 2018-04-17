classdef flim_data_series_list < handle & flim_data_series_observer
    
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
    end
    
    events
        selection_updated;
    end
    
    methods
    
        function obj = flim_data_series_list(handles)
                        
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);
            
            obj.handle = obj.data_series_table;

            set(obj.handle,'CellSelectionCallback',@obj.list_callback);
            set(obj.handle,'CellEditCallback',@obj.use_callback);
            
            if ~isempty(obj.data_series_sel_all)
                set(obj.data_series_sel_all,'Callback',@obj.sel_all_callback);
            end

            if ~isempty(obj.data_series_sel_none)
                set(obj.data_series_sel_none,'Callback',@obj.sel_none_callback);
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
                if ~isempty(sel) ... 
                   && evtData.Indices(2) > 1 % don't update on check 
                    obj.selected = sel;
                    
                    notify(obj,'selection_updated');
                end
            end
        end
        
        function use_callback(obj,src,evtData)
           
            data = get(obj.handle,'Data');
            use = data(:,1);
            use = cell2mat(use);
            obj.data_series.use = use;
            
        end
        
        function sel_all_callback(obj,~,~)
            
            flim_data_selector(obj.data_series_controller);
            
            %{
            data = get(obj.handle,'Data');
            use = data(:,1);
            use = cell2mat(use);
            use = true(size(use));
            
            obj.data_series.use = use;
            
            use = num2cell(use);
            data(:,1) = use;
            set(obj.handle,'Data',data);
            %}
            
        end
        
        function sel_none_callback(obj,~,~)
           %{
            data = get(obj.handle,'Data');
            use = data(:,1);
            use = cell2mat(use);
            use = false(size(use));
            
            obj.data_series.use = use;
            
            use = num2cell(use);
            data(:,1) = use;
            set(obj.handle,'Data',data);
            %}
            
        end
        
        function data_set(obj)
            obj.lh = addlistener(obj.data_series,'use','PostSet',@(~,~) EC(@obj.data_update));
        end
        
        function data_update(obj)
            if ishandle(obj.handle)
                if ~isempty(obj.data_series) && obj.data_series.init 
         
                    headers = fieldnames(obj.data_series.metadata);

                    fields = struct2cell(obj.data_series.metadata);

                    for f=1:length(fields)
                        data(f,:) = fields{f};
                    end
                    
                    n_datasets = obj.data_series.n_datasets;
                    n_field = size(data,1);
                    
                    checked = num2cell(obj.data_series.use);

                    
                    set(obj.handle,'Data',[checked data']);
                    set(obj.handle,'ColumnName',[' '; headers]);
                    
                    fmt = [{'logical'} repmat({'char'},[1,n_field])];
                    set(obj.handle,'ColumnFormat',fmt);
                    
                    
                    edit = [true false(1,n_field)];
                    set(obj.handle,'ColumnEditable',edit);
                    
                    w = [24 ones(1,n_field)*40];
                    set(obj.handle,'ColumnWidth',num2cell(w));
                    
                    if isempty(obj.selected) || obj.selected > obj.data_series.n_datasets  || obj.selected == 0
                        
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
        
        %function delete(obj)
            %delete(obj.lh);
        %end
        
    end
end