classdef flim_model_controller < handle

    properties
       
        decay_types = {'Multi-Exponential Decay','FRET Decay','Anisotropy Decay'};
        fit_options = {'Fixed','Fitted Locally','Fitted Globally'};
        
        groups;
        model_variables;
        scroll_panel;
        main_layout;
        model;
        n_channel = 1;
        
        channel_controls = {};
        
        title_color = [0.8 0.8 0.8];
        
    end
    
    methods
        
        
        function obj = flim_model_controller(fh)

            obj.model = ff_DecayModel();    
            ff_DecayModel(obj.model,'AddDecayGroup','Multi-Exponential Decay',1);

            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',2,'BackgroundColor','w');

            add_layout = uix.HBox('Parent',layout,'Spacing',5,'BackgroundColor','w');
            uicontrol('Style','text','String','New: ','Parent',add_layout,'BackgroundColor','w');
            add_popup = uicontrol('Style','popupmenu','String',obj.decay_types,'Parent',add_layout);
            uicontrol('Style','pushbutton','String','Add','Callback',{@obj.add_group,add_popup},'Parent',add_layout);
            add_layout.Widths = [75 -1 75];

            obj.scroll_panel = uix.ScrollingPanel('Parent',layout,'BackgroundColor','w');
            obj.main_layout = uix.VBox('Parent',obj.scroll_panel,'Spacing',2,'BackgroundColor','w');
            
            
            layout.Heights = [22 -1];
            obj.draw();
            
        end
        
        function set_n_channel(obj,n_channel)
            obj.n_channel = n_channel;
            ff_DecayModel(obj.model,'SetNumChannel',n_channel);
            obj.draw();
        end
    
        function draw(obj)    

            delete(obj.main_layout.Contents);
            
            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            for i=1:length(obj.groups)
                obj.draw_group(obj.main_layout,obj.groups(i),i);
            end

            uicontrol('Style','text','String','Model Parameters','Parent',obj.main_layout,...
                'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',obj.title_color);

            obj.model_variables = ff_DecayModel(obj.model,'GetModelVariables');
            for i=1:length(obj.model_variables)
                obj.draw_variable(obj.main_layout,0,i,obj.model_variables(i));
            end
            
            uicontrol('Style','text','String','Channel Factors','Parent',obj.main_layout,...
                'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',obj.title_color);

            for i=1:length(obj.groups)
                obj.draw_channel(obj.main_layout,obj.groups(i),i);
            end

            uix.Empty('Parent',obj.main_layout);

            obj.main_layout.Heights = 22*ones(1,length(obj.main_layout.Children));
            obj.main_layout.Heights(end) = -1;
            
            obj.scroll_panel.Heights = 24*length(obj.main_layout.Children);
            
        end

        function draw_group(obj, parent, group, idx)
            layout = uix.HBox('Parent',parent,'BackgroundColor',obj.title_color);

            display_name = ['[' num2str(idx) '] ' group.Name];

            uicontrol('Style','text','String',display_name,'Parent',layout,...
                'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',obj.title_color);
            uicontrol('Style','pushbutton','String','Remove','Parent',layout,'Callback',{@obj.remove_group, idx});
            layout.Widths = [-1 75];

            params = fieldnames(group.Parameters);

            for j=1:length(params)
               obj.draw_parameter(parent, idx, params{j}, group.Parameters.(params{j})); 
            end

            for j=1:length(group.Variables)
               obj.draw_variable(parent, idx, j, group.Variables(j)); 
            end
        end

        function draw_parameter(obj, parent, group_idx, name, value)
            layout = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
            uix.Empty('Parent',layout);
            uicontrol('Style','text','String',name,'Parent',layout,'FontWeight','bold','BackgroundColor','w');

            if ischar(value)
                uicontrol('Style','edit','String',value,'Parent',layout,...
                   'Callback',@(src,evt) obj.update_parameter(group_idx, name, src.String));
            elseif isinteger(value)
                v = arrayfun(@num2str,1:5,'UniformOutput',false);
                uicontrol('Style','popupmenu','String',v,'Value',value,'Parent',layout,...
                   'Callback',@(src,evt) obj.update_parameter(group_idx, name, src.Value));
            elseif islogical(value)
                uicontrol('Style','popupmenu','String',{'No', 'Yes'},'Value',value+1,'Parent',layout,...
                   'Callback',@(src,evt) obj.update_parameter(group_idx, name, src.Value-1));
            elseif isnumeric(value)
                uicontrol('Style','edit','String',num2str(value),'Parent',layout,...
                   'Callback',@(src,evt) obj.update_parameter(group_idx, name, str2double(src.String)));
            else
                uix.Empty('Parent',layout);
            end
            layout.Widths = [75 -1 -1];
        end


        function draw_variable(obj, parent, group_idx, variable_idx, variable)
            layout = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
            uicontrol('Style','text','String',variable.Name,'Parent',layout,'FontWeight','bold','BackgroundColor','w');
            uicontrol('Style','edit','String',num2str(variable.InitialValue),'Parent',layout,...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'InitialValue', str2double(src.String)));

            idx = 1:length(variable.AllowedFittingTypes);
            idx = idx(variable.AllowedFittingTypes == variable.FittingType);

            uicontrol('Style','popupmenu','String',obj.fit_options(variable.AllowedFittingTypes),'Value',idx,'Parent',layout,...
                'Callback',@(src,evt) obj.update_variable_option(group_idx, variable_idx, 'FittingType', variable.AllowedFittingTypes(src.Value)));
            layout.Widths = [75 -1 -1];
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

