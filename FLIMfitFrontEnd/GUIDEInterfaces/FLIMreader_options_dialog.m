function options = FLIMreader_options_dialog(max_timebins, dt)

    if nargin < 2
        max_timebins = 256;
        dt = 1;
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
            
    % move to centre
    set(fh, 'Units', 'pixels');
    FigWidth = 320;
    FigHeight = 91;
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

    layout = uiextras.Grid('Parent',fh, 'Spacing', 5, 'Padding', 5);
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
    uicontrol('Style','pushbutton','Parent',layout,'String','OK','Callback',@(~,~) uiresume(fh));

    set(layout,'RowSizes',[22 22 22],'ColumnSizes',[100 200]);

    uiwait(fh);

    options.spatial_binning = 2^(get(spatial_popup,'Value')-1);
    options.num_temporal_bits = ceil(log2(max_timebins)) - get(timebins_popup,'Value') + 1; 
    
    delete(fh);


end