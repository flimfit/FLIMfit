function generate_pattern_ui(t, data, irf, T)

    if any(data==0)
        warndlg('Decay contains zeros, please average over a larer region','Warning')
    end

    screen_pos = get(0,'ScreenSize');
    pos = [100 100 screen_pos(3:4) - 200];

    fh = figure('Name','Estimate IRF','NumberTitle','off','Menu','none','Toolbar','none','Position',pos);

    layout = uix.VBox('Parent',fh);
    
    n_chan = size(data,2);

    tabs = uix.TabPanel('Parent',layout);
    
    for i=1:n_chan
        ch_layout = uix.VBox('Parent',tabs);
        
        fit_box = uix.BoxPanel('Parent',ch_layout,'Title','Fit');
        fit_ax(i) = axes('Parent',fit_box);
        
        res_box = uix.BoxPanel('Parent',ch_layout,'Title','Residual');
        res_ax(i) = axes('Parent',res_box);
        
        titles{i} = ['Channel ' num2str(i)];
        ch_layout.Heights = [-2.5 -1];
    end
    tabs.TabTitles = titles;
    
    button_layout = uix.HBox('Parent',layout);
    uix.Empty('Parent',button_layout);
    uicontrol(button_layout,'Style','pushbutton','String','Cancel','Callback', @(~,~) close(fh));
    save_button = uicontrol(button_layout,'Style','pushbutton','String','Save Pattern...','Enable','off','Callback',@save);
    button_layout.Widths = [-1 200 200];
    layout.Heights = [-1 30];

    
    for i=1:n_chan
        tabs.Selection = i;
        
        if irf.is_analytical    
            mu = irf.gaussian_parameters(i).mu;
            sigma = irf.gaussian_parameters(i).sigma;
            pattern{i} = generate_pattern_analytical(t,data(:,i),mu,sigma,T,fit_ax(i),res_ax(i));
        else
            pattern{i} = generate_pattern(t,data(:,i),tirf,irf(:,i),T,fit_ax(i),res_ax(i));
        end
    end
    
    save_button.Enable = 'on';
    
    function save(~,~)
        name = inputdlg('Pattern Name','Pattern Name');
        
        if ~isempty(name)
            pattern_library = getpref('FLIMfit','pattern_library',containers.Map('KeyType','char','ValueType','double'));
            pattern_library(name{1}) = pattern;           
            setpref('FLIMfit','pattern_library',pattern_library);
            close(fh)
        end
    end

end
