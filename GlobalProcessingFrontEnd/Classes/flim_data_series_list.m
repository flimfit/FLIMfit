classdef flim_data_series_list < handle & flim_data_series_observer
   
    properties
        handle;
        data_series_table;
        selected;
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
            
            obj.selected = 1; %obj.data_series.selected;
            obj.data_update();
            
        end
        
        function update_selection(obj,src,evtData)
            set(obj.handle,'Value',src.selected)
        end
        
        function list_callback(obj,src,evtData)            
            if ~isempty(evtData.Indices)
                sel = evtData.Indices(1);
                if ~isempty(sel)
                    obj.selected = sel;
                    notify(obj,'selection_updated');
                end
            end
        end
        
        function use_callback(obj,~,~)
           
            data = get(obj.handle,'Data');
            use = data(:,1);
            use = cell2mat(use);
            obj.data_series.use = use;
            
        end
        
        function data_set(obj)
            obj.lh = addlistener(obj.data_series,'use','PostSet',@obj.data_update);
        end
        
        function data_update(obj,~,~)
            if ishandle(obj.handle)
                if ~isempty(obj.data_series) && obj.data_series.init 
                    %obj.selected = obj.data_series.selected;
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
                    
                    if isempty(obj.selected) || obj.selected > obj.data_series.num_datasets  || obj.selected == 0
                        obj.selected = 1;
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