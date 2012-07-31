classdef control_binder < handle
   
    properties
       
        flh={};
        controls = struct();
        bindings = {};
        
        bound_data_source;
    end
    
    methods
    
        function obj = control_binder(bound_data_source)
            obj.bound_data_source = bound_data_source;
        end
        
        function set_bound_data_source(obj,bound_data_source)
            obj.bound_data_source = bound_data_source;
            
            for i=1:length(obj.lh)
                delete(obj.lh{i});
            end
            obj.flh = cell(1,length(obj.bindings));
            
            
            for i=1:length(obj.bindings)
                bd = obj.bindings{i};
                
                variable_callback =  @(~,~) variable_updated(obj,bd.control,bd.control_type,bd.parameter);
                obj.flh{end+1} = addlistener(obj.bound_data_source,bd.parameter,'PostSet',variable_callback);
                variable_updated(obj,bd.control,bd.control_type,bd.parameter);
            end
        end
            
        function bind_control(obj,source,parameter,control_type)
            control_name = [parameter '_' control_type];
            
            if ~isempty(obj) && isfield(source, control_name)
                control = source.(control_name);
                obj.controls.(control_name) = control;
                control_callback = @(src,~) control_updated(obj,src,control_type,parameter);
                set(control,'Callback',control_callback);
                
                obj.bindings{end+1} = struct('control',control,'control_type',control_type,'parameter',parameter);
                
                if ~isempty(obj.bound_data_source)
                    variable_callback =  @(~,~) variable_updated(obj,control,control_type,parameter);
                    obj.flh{end+1} = addlistener(obj.bound_data_source,parameter,'PostSet',variable_callback);
                end
                
                variable_updated(obj,control,control_type,parameter);
            end
        end
%{
        
        function bind_control(obj,control,control_type,parameter)
            if ~isempty(obj)
                
                control_callback = @(src,~) control_updated(obj,src,control_type,parameter);
                set(control,'Callback',control_callback);
                variable_callback =  @(~,~) variable_updated(obj,control,control_type,parameter);
                obj.flh{end+1} = addlistener(obj.fit_params,parameter,'PostSet',variable_callback);

                variable_updated(obj,control,control_type,parameter);
            end
        end
        
        %}
        
        function variable_updated(obj,control,control_type,parameter)
            
            value = obj.bound_data_source.(parameter);
            
            switch control_type
                case 'edit'
                    set(control,'String',num2str(value,'%11.4g'));
                case 'popupmenu'
                    str = get(control,'String');
                    items = str2double(str);
                    
                    if all(isnan(items)) % we have a popup menu of strings
                        idx = value + 1;
                    else
                        idx = find(items==value,1,'first');
                    end
                    
                    if ~isempty(idx)
                        set(control,'Value',idx)
                    else
                        set(control,'Value',1);
                    end
                case 'checkbox'
                    set(control,'Value',value);
            end
            
            obj.update_controls();
            
            
        end
        
        function control_updated(obj,src,control_type,parameter)
        
            value = [];
            
            switch control_type
                case 'edit'
                    value = str2double(get(src,'String'));
                case 'popupmenu'
                    idx = get(src,'Value');
                    str = get(src,'String');
                    value = str2double(str{idx});
                    
                    if isnan(value) % string value
                        value = idx - 1;
                    end
                case 'checkbox'
                    value = get(src,'Value');
            end
            
            obj.bound_data_source.(parameter) = value;
        
        end
    end
    
    methods(Abstract=true)
        update_controls(obj);
    end
    
end