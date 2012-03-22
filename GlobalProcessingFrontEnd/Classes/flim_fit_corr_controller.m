classdef flim_fit_corr_controller < flim_fit_observer
   
    properties
        corr_axes;
        corr_param_x_popupmenu;
        corr_param_y_popupmenu;
        corr_prop_table;
        
        corr_x_lim = [0; 1000];
        corr_y_lim = [0; 1000];
        
        param_x;
        param_y;
        
        data_series_list;
        selected;
    end
    
    methods
        function obj = flim_fit_corr_controller(handles)
            obj = obj@flim_fit_observer(handles.fit_controller);
            assign_handles(obj,handles);
            
            set(obj.corr_prop_table,'CellEditCallback',@obj.table_updated);
            set(obj.corr_param_x_popupmenu,'Callback',@obj.param_updated);
            set(obj.corr_param_y_popupmenu,'Callback',@obj.param_updated);
            
            addlistener(obj.data_series_list,'selection_updated',@obj.selection_updated);
            
            obj.selected = obj.data_series_list.selected;
            
            obj.update_table();
            obj.update_param_list();
            obj.update_correlation();
        end
        
        function selection_updated(obj,~,~)
            obj.selected = obj.data_series_list.selected;
            obj.update_correlation();
        end
        
        function fit_update(obj)
            obj.update_param_list();
            obj.update_correlation();
        end
        
        function table_updated(obj,~,~)
            table_data = get(obj.corr_prop_table,'Data');
            obj.corr_x_lim = table_data(:,1);
            obj.corr_y_lim = table_data(:,2);
            obj.update_correlation();
        end
        
        function update_param_list(obj)
            if obj.fit_controller.has_fit
                params = obj.fit_controller.fit_result.fit_param_list();
                params = [{'-'} params];
                set(obj.corr_param_x_popupmenu,'String',params);
                set(obj.corr_param_y_popupmenu,'String',params);
                set(obj.corr_param_x_popupmenu,'Value',1);
                set(obj.corr_param_y_popupmenu,'Value',1);

                obj.param_updated()
            end
        end
        
        function param_updated(obj,~,~)
            params = obj.fit_controller.fit_result.fit_param_list();
            px = get(obj.corr_param_x_popupmenu,'Value');
            py = get(obj.corr_param_y_popupmenu,'Value');
            if px > 1
                obj.param_x = params{px-1};
            else
                obj.param_x = [];
            end
            if py > 1
                obj.param_y = params{py-1};
            else
                obj.param_y = [];
            end
            obj.update_correlation();
        end
        
        function update_table(obj)
            table_data = zeros(2,2);
            table_data(:,1) = obj.corr_x_lim;
            table_data(:,2) = obj.corr_y_lim;
            set(obj.corr_prop_table,'Data',table_data);
        end
        
                
        function update_correlation(obj)
            if obj.fit_controller.has_fit && ~isempty(obj.param_x) && ~isempty(obj.param_y)
                
                r = obj.fit_controller.fit_result;
                
                param_data_x = r.get_image(obj.selected,obj.param_x);
                param_data_y = r.get_image(obj.selected,obj.param_y);

                obj.corr_x_lim = r.default_lims.(obj.param_x);
                obj.corr_y_lim = r.default_lims.(obj.param_y);
                
                sel = param_data_x >= obj.corr_x_lim(1) & param_data_x <= obj.corr_x_lim(2) ...
                    & param_data_y >= obj.corr_y_lim(1) & param_data_y <= obj.corr_y_lim(2);      
                
                param_data_x = param_data_x( sel );
                param_data_y = param_data_y( sel );
                

                %{
                if ~isempty(param_data_x) && ~isempty(param_data_y)
                    createContour([param_data_x param_data_y]);
                end
                %}
                scatter(obj.corr_axes,param_data_x,param_data_y);
                xlabel(obj.corr_axes,obj.param_x);
                ylabel(obj.corr_axes,obj.param_y);
            else
                cla(obj.corr_axes);
            end
        end
        
    end
    
end


