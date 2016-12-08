function model = model_interface(fh)

    decay_types = {'Multi-Exponential Decay','FRET Decay','Anistropy Decay'};
    fit_options = {'Fixed','Fitted Locally','Fitted Globally'};
    
    model = ff_DecayModel();    
    ff_DecayModel(model,'AddDecayGroup','Multi-Exponential Decay',1);
   
    groups = ff_DecayModel(model,'GetGroups');

    draw();
    
    function draw()    
        clf(fh);

        main_layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',2,'BackgroundColor','w');

        add_layout = uix.HBox('Parent',main_layout,'Spacing',5,'BackgroundColor','w');
        uicontrol('Style','text','String','New: ','Parent',add_layout,'BackgroundColor','w');
        add_popup = uicontrol('Style','popupmenu','String',decay_types,'Parent',add_layout);
        uicontrol('Style','pushbutton','String','Add','Callback',{@add_group,add_popup},'Parent',add_layout);
        add_layout.Widths = [75 -1 75];

        
        groups = ff_DecayModel(model,'GetGroups');

        for i=1:length(groups)
            draw_group(main_layout,groups(i),i);
        end

        uix.Empty('Parent',main_layout);
        main_layout.Heights = [22*ones(1,length(main_layout.Children)-1) -1];
        
    end

    function draw_group(parent, group, idx)
        layout = uix.HBox('Parent',parent);
        
        display_name = ['[' num2str(idx) '] ' group.Name];
        
        uicontrol('Style','text','String',display_name,'Parent',layout,...
            'FontSize',10,'FontWeight','bold','HorizontalAlignment','left','BackgroundColor','w');
        uicontrol('Style','pushbutton','String','Remove','Parent',layout,'Callback',{@remove_group, idx});
        layout.Widths = [-1 75];
        
        params = fieldnames(group.Parameters);
        
        for j=1:length(params)
           draw_parameter(parent, idx, params{j}, group.Parameters.(params{j})); 
        end
        
        for j=1:length(group.Variables)
           draw_variable(parent, idx, j, group.Variables(j)); 
        end
    end

    function draw_parameter(parent, group_idx, name, value)
        layout = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
        uix.Empty('Parent',layout);
        uicontrol('Style','text','String',name,'Parent',layout,'FontWeight','bold','BackgroundColor','w');
        
        if ischar(value)
            uicontrol('Style','edit','String',value,'Parent',layout,...
               'Callback',@(src,evt) update_parameter(group_idx, name, src.String));
        elseif isinteger(value)
            v = arrayfun(@num2str,1:5,'UniformOutput',false);
            uicontrol('Style','popupmenu','String',v,'Value',value,'Parent',layout,...
               'Callback',@(src,evt) update_parameter(group_idx, name, src.Value));
        elseif islogical(value)
            uicontrol('Style','popupmenu','String',{'No', 'Yes'},'Value',value+1,'Parent',layout,...
               'Callback',@(src,evt) update_parameter(group_idx, name, src.Value-1));
        elseif isnumeric(value)
            uicontrol('Style','edit','String',num2str(value),'Parent',layout,...
               'Callback',@(src,evt) update_parameter(group_idx, name, str2double(src.String)));
        else
            uix.Empty('Parent',layout);
        end
        layout.Widths = [75 -1 -1];
    end


    function draw_variable(parent, group_idx, variable_idx, variable)
        layout = uix.HBox('Parent',parent,'Spacing',5,'BackgroundColor','w');
        uicontrol('Style','text','String',variable.Name,'Parent',layout,'FontWeight','bold','BackgroundColor','w');
        uicontrol('Style','edit','String',num2str(variable.InitialValue),'Parent',layout,...
            'Callback',@(src,evt) update_initial_value(group_idx, variable_idx, str2double(src.String)));
        
        idx = 1:length(variable.AllowedFittingTypes);
        idx = idx(variable.AllowedFittingTypes == variable.FittingType);
        
        uicontrol('Style','popupmenu','String',fit_options(variable.AllowedFittingTypes),'Value',idx,'Parent',layout,...
            'Callback',@(src,evt) update_fitting_option(group_idx, variable_idx, variable.AllowedFittingTypes(src.Value)));
        layout.Widths = [75 -1 -1];
    end

    function add_group(~,~,add_popup)
        type = add_popup.String{add_popup.Value};
        ff_DecayModel(model,'AddDecayGroup',type);
        draw();
    end

    function remove_group(~,~,idx)
        ff_DecayModel(model,'RemoveDecayGroup',idx);
        draw();
    end

    function update_parameter(group_idx,name,value)
        ff_DecayModel(model,'SetParameter',group_idx,name,value);
        draw();
    end

    function update_initial_value(group_idx, variable_idx, value)
        groups(group_idx).Variables(variable_idx).InitialValue = value;
        update_variables(group_idx);
    end

    function update_fitting_option(group_idx, variable_idx, value)
        groups(group_idx).Variables(variable_idx).FittingType = value;
        update_variables(group_idx);
    end

    function update_variables(group_idx)
       ff_DecayModel(model,'SetVariables',group_idx,groups(group_idx).Variables);
       draw();
    end

end

