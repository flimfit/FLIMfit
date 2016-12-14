function [Z,C,T] = zct_selection_dialog

    z = 1:20;
    t = 1:20;
    c = 1:3;

    fh = figure('NumberTitle','off','Name','Select images to load','MenuBar','none','CloseRequestFcn',@close_fcn);
    
    layout = uix.VBox('Parent',fh,'Padding',5,'Spacing',10);
    sel_layout = uix.HBox('Parent',layout,'Spacing',5);
    button_layout = uix.HBox('Parent',layout,'Spacing',5);
    
    layout.Heights = [-1 22];
    
    
    z_check = add_list(uipanel('Parent',sel_layout,'Title','Z'),z);
    t_check = add_list(uipanel('Parent',sel_layout,'Title','T'),t);

    c_panel = uipanel('Parent',sel_layout,'Title','C');
    c_layout = uix.VBox('Parent',c_panel);
    c_opt_layout = uix.HBox('Parent',c_layout,'Padding',5,'Spacing',2);
    uicontrol('Style','text','String','Load as:','HorizontalAlignment','left','Parent',c_opt_layout);
    uicontrol('Style','popupmenu','String',{'Channels','Images'},'Parent',c_opt_layout);

    c_check = add_list(c_layout,c);
    
    c_opt_layout.Widths = [50 -1];
    c_layout.Heights = [30 -1];
    uix.Empty('Parent',button_layout)
    uicontrol('Style','pushbutton','String','OK','Parent',button_layout,'Callback',@(~,~) close(fh));
    button_layout.Widths = [-1 200];
    
    uiwait(fh);
        
    function close_fcn(obj,evt)
        
        Z = get_check(z_check);
        C = get_check(c_check);
        T = get_check(t_check);
        
        close(obj);
        
    end
    
    function checkboxes = add_list(parent,options)
       
        panel = uipanel('Parent',parent,'BorderType','none');
        sub_layout = uix.HBox('Parent',panel,'Padding',5);
        scroll_panel = uipanel('Parent',sub_layout,'BackgroundColor','w','BorderType','none','Units','pixels');
        check_layout = uix.VBox('Parent',scroll_panel,'Padding',5,'BackgroundColor','w','Units','pixels');
        slider = uicontrol('Style','slider','Parent',sub_layout,'Callback',@update_position);
        for i=1:length(options)
            checkboxes(i) = uicontrol('Style','check','String',num2str(options(i)),'Parent',check_layout,'BackgroundColor','w');
        end
        check_layout.Heights = [20*ones(1,length(options))];
        sub_layout.Widths = [-1 20];
        
        setup_slider(true);
        scroll_panel.ResizeFcn = @(~,~) setup_slider(false);
                
        function setup_slider(first)
            
            p = scroll_panel.Position;
            
            h =  sum(check_layout.Heights) + 2*check_layout.Padding;
            
            pc = [0 p(4)-h p(3) h];
            
            check_layout.Position = pc;
            
            mx = max(1,h-p(4));
      
            slider.Min = 0; 
            slider.Max = mx;
            slider.Value = mx;
                
                        
            if (mx == 1)
                slider.Enable = 'off';
            else 
                slider.Enable = 'on';
            end
            
            if (slider.Max > 20)
                slider.SliderStep = [20 20] / slider.Max;
            else
                slider.SliderStep = [1 1];
            end
        end
                
        function update_position(src,evt)
            %# slider value
            offset = src.Value;
            p = check_layout.Position;
            check_layout.Position = [p(1) -offset p(3) p(4)];
        end
        
    end

    function v = get_check(checkboxes)
        n = 1:length(checkboxes);
        v = logical([checkboxes.Value]);
        v = n(v);
    end

    
end