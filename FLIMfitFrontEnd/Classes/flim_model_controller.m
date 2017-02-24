classdef flim_model_controller < handle

    properties
       
        decay_types = {'Multi-Exponential Decay','FRET Decay','Anisotropy Decay'};
        fit_options = {'Fixed','Fitted Locally','Fitted Globally'};
        
        groups;
        model_variables;
        scroll_panel;
        
        main_layout;
        group_layout;
        model_layout;
        channel_layout;

        model;
        n_channel = 1;
        
        channel_controls = {};
        
        title_color = [0.8 0.8 0.8];
        
        map = containers.Map('KeyType','uint64','ValueType','any');
                
        touched;
        
    end
    
    methods
        
        
        function obj = flim_model_controller(fh)

            obj.model = ff_DecayModel();    
            ff_DecayModel(obj.model,'AddDecayGroup','Multi-Exponential Decay',1);

            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',2,'BackgroundColor','w');

            add_layout = uix.HBox('Parent',layout,'Spacing',5,'BackgroundColor','w');
            uicontrol('Style','text','String','Add: ','Parent',add_layout,'BackgroundColor','w');
            add_popup = uicontrol('Style','popupmenu','String',obj.decay_types,'Parent',add_layout);
            uicontrol('Style','pushbutton','String','Add','Callback',{@obj.add_group,add_popup},'Parent',add_layout);
            add_layout.Widths = [75 -1 75];

            obj.scroll_panel = uix.ScrollingPanel('Parent',layout,'BackgroundColor','w');
            obj.main_layout = uix.VBox('Parent',obj.scroll_panel,'Spacing',2,'BackgroundColor','w');
            
            obj.group_layout = uix.VBox('Parent',obj.main_layout,'Spacing',2,'BackgroundColor','w');
           
            uicontrol('Style','text','String','Model Parameters','Parent',obj.main_layout,...
                      'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',obj.title_color);
            obj.model_layout = uix.VBox('Parent',obj.main_layout,'Spacing',2,'BackgroundColor','w');
            
            uicontrol('Style','text','String','Channel Factors','Parent',obj.main_layout,...
                      'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',obj.title_color);
            obj.channel_layout = uix.VBox('Parent',obj.main_layout,'Spacing',2,'BackgroundColor','w');

            uix.Empty('Parent',obj.main_layout,'UserData','Empty');

            layout.Heights = [22 -1];
            obj.draw();
            
        end
        
        function set_n_channel(obj,n_channel)
            obj.n_channel = n_channel;
            ff_DecayModel(obj.model,'SetNumChannel',n_channel);
            obj.draw();
        end
    
        function draw(obj)    
            
            obj.touched = [];
            
            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            for i=1:length(obj.groups)
                obj.draw_group(obj.group_layout,obj.groups(i),i);
            end
            
            obj.model_variables = ff_DecayModel(obj.model,'GetModelVariables');
            for i=1:length(obj.model_variables)
                obj.draw_variable(obj.model_layout,0,i,obj.model_variables(i));
            end
            
            delete(obj.channel_layout.Children);
            for i=1:length(obj.groups)
                obj.draw_channel(obj.channel_layout,obj.groups(i),i);
            end

            all_ids = obj.map.keys;
            for i=1:length(all_ids)
                id = all_ids{i};
                if ~any(id == obj.touched)
                    h = obj.map(id);
                    delete(h.box);
                    obj.map.remove(id);
                end
            end
          
            height = get_height(obj.main_layout);
            obj.scroll_panel.Heights = height;
                 
            function height = get_height(object)
                
                if isa(object,'uix.VBox')
                    if isempty(object.Children)
                        height = 0;
                    else
                        heights = arrayfun(@get_height,flipud(object.Children));
                        object.Heights = heights;
                        height = sum(heights(heights>0) + 2) - 2;
                    end
                elseif isa(object,'uix.BoxPanel')
                    height = get_height(object.Children) + 24;
                elseif strcmp(object.UserData,'Empty')
                    height = -1;
                else
                    height = 22;
                end
                
            end
            
        end

        function draw_group(obj, parent, group, idx)
            
            params = fieldnames(group.Parameters);

            if obj.map.isKey(group.id)
                h = obj.map(group.id);
            else
                h.box = uix.BoxPanel('Parent',parent,'BackgroundColor','w');
                h.layout = uix.VBox('Parent',h.box,'Spacing',2,'BackgroundColor','w');
                %h.label = uicontrol('Style','text','Parent',h.layout,...
                %    'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',obj.title_color);
                %h.remove_button = uicontrol('Style','pushbutton','String','Remove','Parent',h.layout,'Callback',{@obj.remove_group, idx});
                %h.layout.Widths = [-1 75];
                
                for j=1:length(params)
                    h.params{j} = obj.draw_parameter(h.layout, group.Parameters.(params{j})); 
                end
            end
            
            h.box.Title = ['[' num2str(idx) '] ' group.Name];
            h.box.CloseRequestFcn = {@obj.remove_group, idx};

            for j=1:length(params)
               obj.refresh_parameter_control(h.params{j}, idx, params{j}, group.Parameters.(params{j})); 
            end

            for j=1:length(group.Variables)
               obj.draw_variable(h.layout, idx, j, group.Variables(j)); 
            end
            
            obj.map(group.id) = h;
            obj.touched(end+1) = group.id;
        end

        function h = draw_parameter(obj, parent, value)
            h.layout = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
            uix.Empty('Parent',h.layout);
            h.label = uicontrol('Style','text','Parent',h.layout,'FontWeight','bold','BackgroundColor','w');

            if ischar(value)
                h.control = uicontrol('Style','edit','Parent',h.layout);
            elseif isinteger(value)
                v = arrayfun(@num2str,1:5,'UniformOutput',false);
                h.control = uicontrol('Style','popupmenu','String',v,'Parent',h.layout);
            elseif islogical(value)
                h.control = uicontrol('Style','popupmenu','String',{'No', 'Yes'},'Parent',h.layout);
            elseif isnumeric(value)
                h.control = uicontrol('Style','edit','Parent',h.layout);
            else
                uix.Empty('Parent',h.layout);
            end
            h.layout.Widths = [75 -1 -1];
        end
        
        
        function refresh_parameter_control(obj, h, group_idx, name, value)
            h.label.String = name;
            if ischar(value)
                set(h.control,'String',value,'Callback',@(src,evt) obj.update_parameter(group_idx, name, src.String));
            elseif isinteger(value)
                set(h.control,'Value',value,'Callback',@(src,evt) obj.update_parameter(group_idx, name, src.Value));
            elseif islogical(value)
                set(h.control,'Value',value+1,'Callback',@(src,evt) obj.update_parameter(group_idx, name, src.Value-1));
            elseif isnumeric(value)
                set(h.control,'String',num2str(value,'Callback',@(src,evt) obj.update_parameter(group_idx, name, str2double(src.String))));
            else
                uix.Empty('Parent',layout);
            end
            layout.Widths = [75 -1 -1];
        end
        
        


        function draw_variable(obj, parent, group_idx, variable_idx, variable)
            if obj.map.isKey(variable.id)
                h = obj.map(variable.id);
            else
                h.box = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
                h.label = uicontrol('Style','text','Parent',h.box,'FontWeight','bold','BackgroundColor','w');
                h.initial_edit = uicontrol('Style','edit','Parent',h.box);
                h.popup = uicontrol('Style','popupmenu','Parent',h.box);
                h.box.Widths = [75 -1 -1];
            end
            
            set(h.label,'String',variable.Name);
            set(h.initial_edit,'String',num2str(variable.InitialValue),...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'InitialValue', str2double(src.String)));

            idx = 1:length(variable.AllowedFittingTypes);
            idx = idx(variable.AllowedFittingTypes == variable.FittingType);

            set(h.popup,'String',obj.fit_options(variable.AllowedFittingTypes),'Value',idx,...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'FittingType', variable.AllowedFittingTypes(src.Value)));
            
            obj.map(variable.id) = h;
            obj.touched(end+1) = variable.id;
        end

        function draw_channel(obj, parent, ~, idx)

            channel_names = ff_DecayModel(obj.model,'GetChannelFactorNames',idx);

            for i=1:length(channel_names)        
                channel_factors = obj.get_channel_factors(idx, i);
                
                layout = uix.HBox('Parent',parent,'Spacing',2,'BackgroundColor','w'); 
                uicontrol('Style','text','String',['[' num2str(idx) '] ' channel_names{i}],'Parent',layout,'BackgroundColor','w');
                for j=1:length(channel_factors)
                    obj.channel_controls{idx}{i}{j} = uicontrol('Style','edit','String',num2str(channel_factors(j)),'Parent',layout,'BackgroundColor','w',...
                        'Callback',@(src,evt) obj.update_channel_factor(idx, i, j, str2double(src.String)));
                end
            end
        end

        function add_group(obj,~,~,add_popup)
            type = add_popup.String{add_popup.Value};
            ff_DecayModel(obj.model,'AddDecayGroup',type);
            obj.draw();
        end

        function remove_group(obj,~,~,idx)
            ff_DecayModel(obj.model,'RemoveDecayGroup',idx);
            obj.draw();
        end

        function update_parameter(obj,group_idx,name,value)
            ff_DecayModel(obj.model,'SetGroupParameter',group_idx,name,value);
            obj.draw();
        end
        
        function update_variable_option(obj, group_idx, variable_idx, opt, value)
            if group_idx == 0
                obj.model_variables.(opt) = value;
                ff_DecayModel(obj.model,'SetModelVariables',group_idx,obj.model_variables);
            else
                obj.groups(group_idx).Variables(variable_idx).(opt) = value;
                ff_DecayModel(obj.model,'SetGroupVariables',group_idx,obj.groups(group_idx).Variables);
            end
            obj.draw();
        end
        
        function channel_factors = get_channel_factors(obj,group_idx,idx)
            channel_factors = ff_DecayModel(obj.model,'GetChannelFactors',group_idx,idx);
            len = length(channel_factors);
            channel_factors = channel_factors(1:min(len,obj.n_channel));
            n_pad = obj.n_channel - len;
            channel_factors = [channel_factors ones([1, n_pad])];
        end
        
        function update_channel_factor(obj,group_idx,factor_idx,channel_idx,value)
            channel_factors = obj.get_channel_factors(group_idx,factor_idx);
            channel_factors(channel_idx) = value;
            ff_DecayModel(obj.model,'SetChannelFactors',group_idx,factor_idx,channel_factors);
            
            for i=1:length(channel_factors)
                obj.channel_controls{group_idx}{factor_idx}{i}.String = num2str(channel_factors(i));
            end
        end
        
        function save(obj,filename)
            ff_DecayModel(obj.model,'SaveModel',filename);
        end
        
        function load(obj,filename)
            ff_DecayModel(obj.model,'LoadModel',filename);
            obj.draw();
        end
        
    end
end

