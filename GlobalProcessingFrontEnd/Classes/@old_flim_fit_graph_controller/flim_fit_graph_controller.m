classdef flim_fit_graph_controller < flim_fit_observer
   
    properties
        
        window;
        
        roi_controller;
        
        graph_axes;
        plate_axes;
        graph_independent_popupmenu;
        graph_dependent_popupmenu;
        plate_param_popupmenu;
        
        data_series_list;
        lh = {};
        
        ind_vars;
        dep_vars;
        
        plate_param;
        ind;
        dep;
        
    end
    
    methods
        function obj = flim_fit_graph_controller(handles)
                       
            obj = obj@flim_fit_observer(handles.fit_controller);
            
            assign_handles(obj,handles);

            set(obj.graph_independent_popupmenu,'Callback',@obj.graph_select_update);
            set(obj.graph_dependent_popupmenu,'Callback',@obj.graph_select_update);
            
            set(obj.plate_param_popupmenu,'Callback',@obj.plate_select_update);
            
            addlistener(obj.roi_controller,'roi_mask','PostSet',@obj.roi_update);
            
            obj.update_menus();
            obj.update_graph();
            obj.update_plate();
            
           
            
            graph_cmenu = uicontextmenu('Parent',obj.window);
            uimenu(graph_cmenu,'Label','Export to Powerpoint','Callback',@(~,~,~) obj.update_graph('powerpoint') );
            set(obj.graph_axes,'uicontextmenu',graph_cmenu);
        end
        
        function fit_update(obj)
            obj.update_menus();
            obj.update_graph();
            obj.update_plate();
        end
       
        function update_menus(obj)
            if obj.fit_controller.has_fit
                
                r = obj.fit_controller.fit_result;            
                obj.dep_vars = r.fit_param_list();
                obj.ind_vars = fieldnames(r.metadata);
                
                set(obj.graph_independent_popupmenu,'String',obj.ind_vars);
                set(obj.graph_dependent_popupmenu,'String',obj.dep_vars);
                set(obj.plate_param_popupmenu,'String',obj.dep_vars);
                
                if get(obj.graph_dependent_popupmenu,'Value') > length(obj.dep_vars)
                    set(obj.graph_dependent_popupmenu,'Value',1);
                end
                if get(obj.plate_param_popupmenu,'Value') > length(obj.dep_vars)
                    set(obj.plate_param_popupmenu,'Value',1);
                end

            end
        end
        
        function roi_update(obj,~,~)
            obj.update_graph();
        end
        
        function graph_select_update(obj,~,~)
            ind_idx = get(obj.graph_independent_popupmenu,'Value');
            dep_idx = get(obj.graph_dependent_popupmenu,'Value');
            
            obj.ind = obj.ind_vars{ind_idx};
            obj.dep = obj.dep_vars{dep_idx};
            
            obj.update_graph();
        end
        
        function plate_select_update(obj,~,~)
            plate_idx = get(obj.plate_param_popupmenu,'Value');
            obj.plate_param = obj.dep_vars{plate_idx};
            
            obj.update_plate();
        end
        
    end
    
    
end