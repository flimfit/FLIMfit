function options = FLIMreader_options_dialog(max_timebins, dt, supports_realignment)

    if nargin < 2
        max_timebins = 256;
        dt = 1;
    end
    if nargin < 3
        supports_realignment = false;
    end
    
    fh = figure('Name','Loading Options','NumberTitle',...
                'off','MenuBar','none','WindowStyle','modal','KeyPress',@keypress);

    function keypress(obj,evt)
        switch evt.Key
            case 'return'
                uiresume(obj);
            case 'escape'
                uiresume(obj);
        end
    end
            
    fig_layout = uiextras.VBox('Parent',fh, 'Spacing', 5, 'Padding', 5);
    
    layout = uiextras.Grid('Parent', fig_layout, 'Spacing', 5);
    uicontrol('Style','text','String','Spatial binning','Parent',layout,'HorizontalAlignment','left');
    uicontrol('Style','text','String','Time bins','Parent',layout,'HorizontalAlignment','left');
    uiextras.Empty('Parent',layout);

    for i=1:4
        num = num2str(2^(i-1));
        binning{i} = [num 'x' num];
    end

    timebin = max_timebins;
    timebins = {};
    t_res = dt;
    while timebin > 2
        timebins{end+1} = [ num2str(timebin) '  (' num2str(t_res,'%.0f') ' ps/bin)' ];
        timebin = timebin / 2;
        t_res = t_res * 2;
    end
    
    spatial_popup = uicontrol('Style','popupmenu','Parent',layout,'String',binning);
    timebins_popup = uicontrol('Style','popupmenu','Parent',layout,'String',timebins);
    
    set(layout,'RowSizes',[22 22],'ColumnSizes',[100 200]);


    realign_panel = uipanel('Parent',fig_layout,'Title','Realignment');
    realign_layout = uiextras.Grid('Parent', realign_panel, 'Spacing', 5, 'Padding', 5);
    uicontrol('Style','text','String','Realignment','Parent',realign_layout,'HorizontalAlignment','left');
    uicontrol('Style','text','String','Spatial binning','Parent',realign_layout,'HorizontalAlignment','left');
    uicontrol('Style','text','String','Frame binning','Parent',realign_layout,'HorizontalAlignment','left');
    realign_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',{'Off','Translation','Rigid Body'},'Callback',@realign_callback);
    realign_spatial_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',binning,'Enable','off','Value',3);
    realign_frame_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',{'1' '2' '3' '4' '5' '6'},'Enable','off','Value',4);
    set(realign_layout,'RowSizes',[22 22 22],'ColumnSizes',[-1 200]);

    if supports_realignment      
        fig_sizes = [49 105 22];
    else
        fig_sizes = [49 0 22];
    end
    
    
    function realign_callback(~,~)
        if get(realign_popup,'Value') > 1
            enable_str = 'on';
        else
            enable_str = 'off';
        end
        set(realign_spatial_popup,'Enable',enable_str);
        set(realign_frame_popup,'Enable',enable_str);
    end   
    
    uicontrol('Style','pushbutton','Parent',fig_layout,'String','OK','Callback',@(~,~) uiresume(fh));

    
    set(fig_layout,'Sizes',fig_sizes)
    
    
    
    % move to centre
    set(fh, 'Units', 'pixels');
    FigWidth = 320;
    FigHeight = sum(fig_sizes) + 20;
    if isempty(gcbf)
        ScreenUnits=get(0,'Units');
        set(0,'Units','pixels');
        ScreenSize=get(0,'ScreenSize');
        set(0,'Units',ScreenUnits);

        FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
        FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
    else
        GCBFOldUnits = get(gcbf,'Units');
        set(gcbf,'Units','pixels');
        GCBFPos = get(gcbf,'Position');
        set(gcbf,'Units',GCBFOldUnits);
        FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                       (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
    end
    FigPos(3:4)=[FigWidth FigHeight];
    set(fh, 'Position', FigPos);
    
    
    
    uiwait(fh);

    options.spatial_binning = 2^(get(spatial_popup,'Value')-1);
    options.num_temporal_bits = ceil(log2(max_timebins)) - get(timebins_popup,'Value') + 1; 
    options.realignment.use_realignment = get(realign_popup,'Value') > 1;
    options.realignment.use_rotation = get(realign_popup,'Value') == 3;
    options.realignment.spatial_binning = 2^(get(realign_spatial_popup,'Value')-1);
    options.realignment.frame_binning = get(realign_frame_popup,'Value');
    delete(fh);


end