function options = FLIMreader_options_dialog(max_timebins, dt, supports_realignment, bidirectional)

    persistent last_options

    if nargin < 2
        max_timebins = 256;
        dt = 1;
    end
    if nargin < 3
        supports_realignment = false;
    end
    if nargin < 4
        bidirectional = false;
    end
    
    for i=1:4
        num = num2str(2^(i-1));
        binning{i} = [num 'x' num];
    end

    timebin = max_timebins;
    timebins = {};
    t_res = dt;
    while timebin > 2
        timebins{end+1} = [ num2str(ceil(timebin)) '  (' num2str(t_res,'%.0f') ' ps/bin)' ];
        timebin = timebin / 2;
        t_res = t_res * 2;
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
    if bidirectional
        uicontrol('Style','text','String','Bidir. Phase','Parent',layout,'HorizontalAlignment','left');
    end
    
    uiextras.Empty('Parent',layout);
    
    spatial_popup = uicontrol('Style','popupmenu','Parent',layout,'String',binning);
    timebins_popup = uicontrol('Style','popupmenu','Parent',layout,'String',timebins);
    
    if bidirectional
        phase_edit = uicontrol('Style','edit','Parent',layout,'String','0');
        row_size = [22 22 22];
    else 
        row_size = [22 22];
    end
        
    set(layout,'RowSizes',row_size,'ColumnSizes',[100 200]);


    realign_panel = uipanel('Parent',fig_layout,'Title','Realignment');
    realign_layout = uiextras.Grid('Parent', realign_panel, 'Spacing', 5, 'Padding', 5);
    uicontrol('Style','text','String','Realignment','Parent',realign_layout,'HorizontalAlignment','left');
    uicontrol('Style','text','String','Spatial binning','Parent',realign_layout,'HorizontalAlignment','left');
    uicontrol('Style','text','String','Frame binning','Parent',realign_layout,'HorizontalAlignment','left');
    uicontrol('Style','text','String','Points','Parent',realign_layout,'HorizontalAlignment','left');
    realign_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',{'Off','Translation','Rigid Body','Warp'},'Callback',@(x,y) realign_callback());
    realign_spatial_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',binning,'Enable','off','Value',3);
    realign_frame_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',{'1' '2' '3' '4' '5' '6'},'Enable','off','Value',4);
    realign_points_popup = uicontrol('Style','popupmenu','Parent',realign_layout,'String',{'5' '10' '20' '30' '40' '50'},'Enable','off','Value',2);
    set(realign_layout,'RowSizes',[22 22 22],'ColumnSizes',[-1 200]);

    if ~isempty(last_options)
        setPopupByNumber(spatial_popup, last_options.spatial_binning);
        setPopupByNumber(timebins_popup, last_options.timebins);
        setPopupByNumber(realign_spatial_popup, last_options.realignment.spatial_binning);
        setPopupByNumber(realign_frame_popup, last_options.realignment.frame_binning);
        setPopupByNumber(realign_points_popup, last_options.realignment.n_resampling_points);
        set(realign_popup,'Value',last_options.realignment.type + 1);
        if exist('phase_edit','var')
            set(phase_edit,'String',num2str(last_options.phase));
        end
        realign_callback();
    end
    
    fig_sizes = [sum(row_size+5) 130 * supports_realignment 22];
    
    function realign_callback()
        mode = get(realign_popup,'Value');
        enable_spatial = 'off';
        enable_frame = 'off';
        enable_interp = 'off';
        if mode > 1
            enable_spatial = 'on';
            enable_frame = 'on';
        end
        if mode == 4
            set(realign_frame_popup,'Value',1);
            enable_frame = 'off';
            enable_interp = 'on';
        end
        set(realign_spatial_popup,'Enable',enable_spatial);
        set(realign_frame_popup,'Enable',enable_frame);
        set(realign_points_popup,'Enable',enable_interp);
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
    
    if ~isvalid(fh)
        % closed without OK
        options = [];
        return
    end

    options.spatial_binning = getNumberFromPopup(spatial_popup);
    options.num_temporal_bits = ceil(log2(max_timebins)) - get(timebins_popup,'Value') + 1; 
    
    if bidirectional
        options.phase = str2double(get(phase_edit,'String'));
    else
        options.phase = 0;
    end
    if ~isfinite(options.phase)
        options.phase = 0;
    end
    
    options.realignment.type = get(realign_popup,'Value')-1;
    options.realignment.spatial_binning = getNumberFromPopup(realign_spatial_popup);
    options.realignment.frame_binning = getNumberFromPopup(realign_frame_popup);
    options.realignment.n_resampling_points = getNumberFromPopup(realign_points_popup); 
    options.timebins = getNumberFromPopup(timebins_popup);
    
    last_options = options;
    
    delete(fh);
    
    function num = getNumberFromPopup(popup)
        str = get(popup,'String');
        tokens = regexp(str,'^(\d+)','tokens','once');
        tokens = cellfun(@(x) x{1},tokens,'UniformOutput',false);
        v = get(popup,'Value');
        num = str2double(tokens{v});
    end

    function setPopupByNumber(popup,num)
        str = get(popup,'String');
        tokens = regexp(str,'^(\d+)','tokens','once');
        tokens = cellfun(@(x) x{1},tokens,'UniformOutput',false);

        str_v = str2double(tokens);
        idx = find(num==str_v,1);
        if ~isempty(idx)
            set(popup,'Value',idx);
        end
    end


end