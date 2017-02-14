classdef flim_model_controller < handle

    properties
       
        decay_types = {'Multi-Exponential Decay','FRET Decay','Anisotropy Decay'};
        fit_options = {'Fixed','Fitted Locally','Fitted Globally'};
        
        groups;
        main_layout;
        model;
        n_channel = 1;
        
        channel_controls = {};
        
    end
    
    methods
        
        
        function obj = flim_model_controller(fh)

            obj.model = ff_DecayModel();    
            ff_DecayModel(obj.model,'AddDecayGroup','FRET Decay',1);

            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            obj.main_layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',2,'BackgroundColor','w');

            obj.draw();
            
        end
        
        function set_n_channel(obj,n_channel)
            obj.n_channel = n_channel;
            ff_DecayModel(obj.model,'SetNumChannel',n_channel);
            obj.draw();
        end
    
        function draw(obj)    

            delete(obj.main_layout.Contents);

            add_layout = uix.HBox('Parent',obj.main_layout,'Spacing',5,'BackgroundColor','w');
            uicontrol('Style','text','String','New: ','Parent',add_layout,'BackgroundColor','w');
            add_popup = uicontrol('Style','popupmenu','String',obj.decay_types,'Parent',add_layout);
            uicontrol('Style','pushbutton','String','Add','Callback',{@obj.add_group,add_popup},'Parent',add_layout);
            add_layout.Widths = [75 -1 75];

            obj.groups = ff_DecayModel(obj.model,'GetGroups');

            for i=1:length(obj.groups)
                obj.draw_group(obj.main_layout,obj.groups(i),i);
            end

            uicontrol('Style','text','String','Channel Factors','Parent',obj.main_layout,...
                'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor','w');


            for i=1:length(obj.groups)
                obj.draw_channel(obj.main_layout,obj.groups(i),i);
            end

            uix.Empty('Parent',obj.main_layout);

            obj.main_layout.Heights = [22*ones(1,length(obj.main_layout.Children)-1) -1];

        end

        function draw_group(obj, parent, group, idx)
            layout = uix.HBox('Parent',parent);

            display_name = ['[' num2str(idx) '] ' group.Name];

            uicontrol('Style','text','String',display_name,'Parent',layout,...
                'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor','w');
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
                'Callback',@(src,evt) obj.update_initial_value(group_idx, variable_idx, str2double(src.String)));

            idx = 1:length(variable.AllowedFittingTypes);
            idx = idx(variable.AllowedFittingTypes == variable.FittingType);

            uicontrol('Style','popupmenu','String',obj.fit_options(variable.AllowedFittingTypes),'Value',idx,'Parent',layout,...
                'Callback',@(src,evt) obj.update_fitting_option(group_idx, variable_idx, variable.AllowedFittingTypes(src.Value)));
            layout.Widths = [75 -1 -1];
        end

        function draw_channel(obj, parent, group, idx)

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
            ff_DecayModel(obj.model,'SetParameter',group_idx,name,value);
            obj.draw();
        end

        function update_initial_value(obj,group_idx, variable_idx, value)
            obj.groups(group_idx).Variables(variable_idx).InitialValue = value;
            obj.update_variables(group_idx);
        end

        function update_fitting_option(obj,group_idx, variable_idx, value)
            obj.groups(group_idx).Variables(variable_idx).FittingType = value;
            obj.update_variables(group_idx);
        end

        function update_variables(obj,group_idx)
           ff_DecayModel(obj.model,'SetVariables',group_idx,obj.groups(group_idx).Variables);
           obj.draw();
        end
        
        function channel_factors = get_channel_factors(obj,group_idx,idx)
            channel_factors = ff_DecayModel(obj.model,'GetChannelFactors',group_idx,idx);
            len = length(channel_factors);
            channel_factors = channel_factors(1:min(len,obj.n_channel));
            n_pad = obj.n_channel - len;
            channel_factors = [channel_factors ones([n_pad, 1])];
        end
        
        function update_channel_factor(obj,group_idx,factor_idx,channel_idx,value)
            channel_factors = obj.get_channel_factors(group_idx,factor_idx);
            channel_factors(channel_idx) = value;
            ff_DecayModel(obj.model,'SetChannelFactors',group_idx,factor_idx,channel_factors);
            
            for i=1:length(channel_factors)
                obj.channel_controls{group_idx}{factor_idx}{i}.String = num2str(channel_factors(i));
            end
            
        end
        
    end
end

