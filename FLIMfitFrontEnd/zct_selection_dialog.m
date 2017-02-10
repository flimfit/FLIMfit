function [Z,C,T,channels] = zct_selection_dialog(zct_size,max_sel,chan_info)

    assert(length(zct_size) == 3)
    
    z = 1:zct_size(1);
    c = 1:zct_size(2);
    t = 1:zct_size(3);

    if nargin >= 3 && numel(chan_info) == zct_size(2)
        c = chan_info;
    end

    fh = figure('NumberTitle','off','Name','Select images to load','MenuBar','none','CloseRequestFcn',@close_fcn);
    
    layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',10);
    sel_layout = uix.HBox('Parent',layout,'Spacing',5);
    button_layout = uix.HBox('Parent',layout,'Spacing',5);
    
    layout.Heights = [-1 22];
    
    
    z_check = checkable_list(uipanel('Parent',sel_layout,'Title','Z'),z);
    t_check = checkable_list(uipanel('Parent',sel_layout,'Title','T'),t);

    c_panel = uipanel('Parent',sel_layout,'Title','C');
    c_layout = uix.VBox('Parent',c_panel);
    c_opt_layout = uix.HBox('Parent',c_layout,'Padding',5,'Spacing',2);
    uicontrol('Style','text','String','Load as:','HorizontalAlignment','left','Parent',c_opt_layout);
    c_type = uicontrol('Style','popupmenu','String',{'Channels','Images'},'Parent',c_opt_layout);

    c_check = checkable_list(c_layout,c);
    
    c_opt_layout.Widths = [50 -1];
    c_layout.Heights = [30 -1];
    uix.Empty('Parent',button_layout)
    uicontrol('Style','pushbutton','String','OK','Parent',button_layout,'Callback',@(~,~) close(fh));
    button_layout.Widths = [-1 200];
    
    uiwait(fh);
        
    function close_fcn(obj,~)
        
        Z = z_check.get_check();
        C = c_check.get_check();
        T = t_check.get_check();
        
        if c_type.Value == 1
            channels = C;
            C = -1;
        else
            channels = -1;
        end
        
        delete(obj);
        
    end

    
end