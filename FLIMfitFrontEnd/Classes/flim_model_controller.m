classdef flim_model_controller < handle

    properties
       
        decay_types = {'Multi-Exponential Decay','FRET Decay','Anisotropy Decay','Pattern','Background Light'};
        fit_options = {'Fixed','Fitted Locally','Fitted Globally'};
        
        groups;
        model_variables;
        model_parameters;
        scroll_panel;
        
        model_param_controls;
        
        main_layout;
        group_layout;
        model_layout;
        channel_layout;

        model;
        n_channel = 1;
        
        channel_controls = {};
        
        title_color = [0.8 0.8 0.8];
        
        map;
                
        touched;
        
    end
    
    methods
        
        
        function obj = flim_model_controller(fh)
            
            obj.map = containers.Map('KeyType','uint64','ValueType','any');
            
            obj.new_model();
            ff_DecayModel(obj.model,'AddDecayGroup','Multi-Exponential Decay',1);

            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',2,'BackgroundColor','w');

            add_layout = uix.HBox('Parent',layout,'Spacing',5,'BackgroundColor','w');
            
            uicontrol('Style','pushbutton','String','L','Parent',add_layout,'Callback',@(~,~) obj.load_from_library);
            uicontrol('Style','pushbutton','String','+','Parent',add_layout,'Callback',@(~,~) obj.add_to_library);
            
            
            uicontrol('Style','text','String','Add: ','Parent',add_layout,'BackgroundColor','w');
            add_popup = uicontrol('Style','popupmenu','String',obj.decay_types,'Parent',add_layout);
            uicontrol('Style','pushbutton','String','Add','Callback',{@obj.add_group,add_popup},'Parent',add_layout);
            add_layout.Widths = [22 22 75 -1 75];

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
            ff_DecayModel(obj.model,'SetNumChannels',n_channel);
            obj.draw();
        end
    
        function draw(obj)    
            
            obj.touched = [];
            
            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            for i=1:length(obj.groups)
                obj.draw_group(obj.group_layout,obj.groups(i),i);
            end
            
            obj.model_parameters = ff_DecayModel(obj.model,'GetModelParameters');
            params = fieldnames(obj.model_parameters);
            if isempty(obj.model_param_controls)
                for i=1:length(params)
                    obj.model_param_controls{i} = obj.draw_parameter(obj.model_layout, obj.model_parameters.(params{i})); 
                end
            else                
                params = fieldnames(obj.model_parameters);
                for i=1:length(params)
                   obj.refresh_parameter_control(obj.model_param_controls{i}, 0, params{i}, obj.model_parameters.(params{i})); 
                end
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
                h.box = uix.VBox('Parent',parent,'BackgroundColor','w');
                title_layout = uix.HBox('Parent',h.box);
                h.title = uicontrol('Parent',title_layout,'Style','text','String','','BackgroundColor',obj.title_color,...
                    'FontSize',10,'FontWeight','bold','HorizontalAlignment','left');
                h.rename_button = uicontrol('Parent',title_layout,'Style','pushbutton','String','Rename');
                h.close_button = uicontrol('Parent',title_layout,'Style','pushbutton','String','x');
                title_layout.Widths = [-1, 60, 22];
                
                h.layout = uix.VBox('Parent',h.box,'Spacing',2,'BackgroundColor','w');
                
                for j=1:length(params)
                    h.params{j} = obj.draw_parameter(h.layout, group.Parameters.(params{j})); 
                end
            end
            
            h.title.String = ['[' num2str(idx) '] ' group.Name];
            h.close_button.Callback = {@obj.remove_group, idx};
            h.rename_button.Callback = {@obj.rename_group, idx, group.Name};

            for j=1:length(params)
               obj.refresh_parameter_control(h.params{j}, idx, params{j}, group.Parameters.(params{j})); 
            end

            for j=1:length(group.Variables)
               var_layout(j) = obj.draw_variable(h.layout, idx, j, group.Variables(j)); 
            end
            
            % Make sure variables are in order
            pos = arrayfun(@(vl) find(h.layout.Children==vl), var_layout);
            new_pos = sort(pos,'descend');
            if ~all(pos==new_pos)
                h.layout.Children(new_pos) = h.layout.Children(pos);
            end
            
            obj.map(group.id) = h;
            obj.touched(end+1) = group.id;
        end

        function h = draw_parameter(~, parent, value)
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
            h.layout.Widths = [102 -1 -1];
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
                set(h.control,'String',num2str(value),'Callback',@(src,evt) obj.update_parameter(group_idx, name, str2double(src.String)));
            else
                uix.Empty('Parent',h.layout);
            end
            h.layout.Widths = [102 -1 -1];
        end
        
        


        function box = draw_variable(obj, parent, group_idx, variable_idx, variable)
            if obj.map.isKey(variable.id)
                h = obj.map(variable.id);
            else
                h.box = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
                h.label = uicontrol('Style','text','Parent',h.box,'FontWeight','bold','BackgroundColor','w');
                h.search_check = uicontrol('Style','checkbox','Parent',h.box,'BackgroundColor','w');
                h.initial_edit = uicontrol('Style','edit','Parent',h.box);
                h.initial_min_edit = uicontrol('Style','edit','Parent',h.box);
                h.initial_max_edit = uicontrol('Style','edit','Parent',h.box);
                h.popup = uicontrol('Style','popupmenu','Parent',h.box);
                h.box.Widths = [75 22 -1 -1 -1 -1];
            end
            
            set(h.label,'String',variable.Name);

            set(h.search_check,'Value',variable.InitialSearch,...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'InitialSearch', logical(src.Value), h));
            
            set(h.initial_edit,'String',num2str(variable.InitialValue),...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'InitialValue', str2double(src.String), h));
            set(h.initial_min_edit,'String',num2str(variable.InitialMin),...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'InitialMin', str2double(src.String), h));
            set(h.initial_max_edit,'String',num2str(variable.InitialMax),...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'InitialMax', str2double(src.String), h));

            idx = 1:length(variable.AllowedFittingTypes);
            idx = idx(variable.AllowedFittingTypes == variable.FittingType);

            set(h.popup,'String',obj.fit_options(variable.AllowedFittingTypes),'Value',idx,...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'FittingType', variable.AllowedFittingTypes(src.Value), h));
            
            obj.update_variable_display(variable, h);
            
            obj.map(variable.id) = h;
            obj.touched(end+1) = variable.id;
            box = h.box;
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
            if strcmp(type,'Pattern')
               [pattern,name] = get_library_pattern();
               pattern = mat2cell(pattern,size(pattern,1),ones(1,size(pattern,2)));
               if ~isempty(pattern)
                   ff_DecayModel(obj.model,'AddDecayGroup',type,pattern,name);
               end
            else
                ff_DecayModel(obj.model,'AddDecayGroup',type)
            end            
            obj.draw();
        end

        function remove_group(obj,~,~,idx)
            ff_DecayModel(obj.model,'RemoveDecayGroup',idx);
            obj.draw();
        end

        function rename_group(obj,~,~,idx,cur_name)
            
            name = inputdlg('Group Name','Rename Group',1,{cur_name});
            
            ff_DecayModel(obj.model,'SetDecayGroupName',idx,name{1});
            obj.draw();
        end

        
        function update_parameter(obj,group_idx,name,value)
            if group_idx == 0
                ff_DecayModel(obj.model,'SetModelParameter',name,value);
            else
                ff_DecayModel(obj.model,'SetGroupParameter',group_idx,name,value);
            end
            obj.draw();
        end
        
        function update_variable_option(obj, group_idx, variable_idx, opt, value, h)
            if group_idx == 0
                obj.model_variables(variable_idx).(opt) = value;
                ff_DecayModel(obj.model,'SetModelVariables',group_idx,obj.model_variables);
                var = obj.model_variables(variable_idx);
            else
                obj.groups(group_idx).Variables(variable_idx).(opt) = value;
                ff_DecayModel(obj.model,'SetGroupVariables',group_idx,obj.groups(group_idx).Variables);
                var = obj.groups(group_idx).Variables(variable_idx);
            end
            
            obj.update_variable_display(var, h);
            obj.draw();
        end
        
        function update_variable_display(obj, var, h)
            if var.FittingType == 3
                h.search_check.Visible = 'on';
            else
                h.search_check.Visible = 'off';
            end
            
            if var.InitialSearch && var.FittingType == 3
                h.initial_min_edit.Visible = 'on';
                h.initial_max_edit.Visible = 'on';
                h.initial_edit.Visible = 'off';
            elseif var.FittingType ~= 2
                h.initial_min_edit.Visible = 'off';
                h.initial_max_edit.Visible = 'off';
                h.initial_edit.Visible = 'on';    
            else
                h.initial_min_edit.Visible = 'off';
                h.initial_max_edit.Visible = 'off';
                h.initial_edit.Visible = 'off';    
            end
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
        
        function load_from_library(obj)
            model_folder = [prefdir filesep 'FLIMfit_models' filesep];
            models = dir([model_folder '*.xml']);
            models = {models.name};
            models = strrep(models,'.xml','');
            
            if isempty(models)
                warndlg('No models found, please create or import a model first','Model Library')
                ok = false;
            else
                [selection,ok] = listdlg('ListString',models,'SelectionMode','single',...
                    'Name','Load Model','PromptString','Select Model');
            end
            
            if ok
                if ~isdeployed % so we can dynamically unload mex file
                    obj.new_model();
                end
                obj.load([model_folder models{selection} '.xml']);
            end
        end
        
        function add_to_library(obj)
            model_folder = [prefdir filesep 'FLIMfit_models' filesep];
            name = inputdlg('Model Name','Add to Library');
            
            if ~isempty(name)
                obj.save([model_folder name{1} '.xml']);
            end
        end
        
        function clear_model(obj)
            ff_DecayModel(obj.model,'Release');
            obj.model = [];
        end
        
        function new_model(obj)
            obj.model = ff_DecayModel();    
        end
        
    end
end

