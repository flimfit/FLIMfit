function model_library_ui

    f = figure('Name','Model Library','MenuBar','none','Toolbar','none','NumberTitle','off');
    
    model_folder = [prefdir filesep 'FLIMfit_models' filesep];
               
    layout = uix.HBox('Parent',f,'Padding',5,'Spacing',5);
    left_layout = uix.VBox('Parent',layout,'Spacing',5);
    handles.list = uicontrol(left_layout,'Style','listbox','Callback',@list_updated);
    
    uicontrol(left_layout,'Style','pushbutton','String','-','Callback',@(~,~) remove_model);
    
    right_layout = uix.VBox('Parent',layout,'Spacing',5);

    top_layout = uix.HBox('Parent',right_layout,'Spacing',5);
    uicontrol(top_layout,'Style','text','String','Name');
    handles.name = uicontrol(top_layout,'Style','edit','String','X');
    
    handles.panel = uipanel(right_layout);
    handles.save = uicontrol(right_layout,'Style','pushbutton','String','Save','Callback',@(~,~) save_model);
    
    layout.Widths = [200 -1];
    left_layout.Heights = [-1 22];
    right_layout.Heights = [22 -1 22];
    top_layout.Widths = [80 -1];
    model_controller = flim_model_controller(handles.panel); 

    get_models();
    
    
    function list_updated(~,~)
        if handles.list.Value <= length(handles.list.String)
           model_name = handles.list.String{handles.list.Value};
           name = [model_folder model_name '.xml'];
           handles.name.String = model_name;
           model_controller.load(name);
        end
    end

    function get_models()
        current_sel = [];
        if handles.list.Value <= length(handles.list.String)
            current_sel = handles.list.String{handles.list.Value};
        end
        if ~exist(model_folder,'dir')
            mkdir(model_folder)
        end
        models = dir([model_folder '*.xml']);
        models = {models.name};
        models = strrep(models,'.xml','');
        handles.list.String = models;
        
        idx = find(strcmp(models,current_sel),1);
        if ~isempty(idx)
            handles.list.Value = idx;
        end
    end
   
    function save_model
        name = [model_folder handles.name.String '.xml'];
        model_controller.save(name);
        get_models();
    end

    function remove_model
        if handles.list.Value <= length(handles.list.String)
           model_name = handles.list.String{handles.list.Value};
           name = [model_folder model_name '.xml'];
           choice = questdlg(['Are you sure you want delete ' model_name '?'],'Confirm Delete','Delete','Cancel','Delete');
           if strcmp(choice,'Delete')
               delete(name);
           end
        end
        get_models();
    end

end