function GlobalProcessing(OM_active )


addpath_global_analysis();

if nargin == 0
    global_processing_ui;
else
               
    global_processing_ui(false, OM_active);
    
     
end

%{
debug_info = struct();

debug_info.computer = computer;
debug_info.os = getenv('OS');
debug_info.ver = ver;
debug_info.hostname = getenv('COMPUTERNAME');
debug_info.timestamp = datestr(now,'yyyy-mm-dd--HH-MM-SS');
debug_info.output = evalc('global_processing_ui(true);');


filename = ['DebugLog\' debug_info.hostname '-' debug_info.timestamp '.m'];
%}
%save(filename,'debug_info');

%{
    if ~isdeployed
        addpath_global_analysis()
    end

    global gui
    
    if ~isempty(gui) && ishandle(gui.window)
        close(gui.window);
    end
    
    % Add the contents
    gui = struct();

    % Open a window and add some menus
    gui.window = figure( ...
        'Name', 'GlobalProcessing', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'HandleVisibility', 'off', ...
        'Units','normalized', ...
        'OuterPosition',[0 0 1 1]);
    
    setup_layout(gui);
    setup_menu(gui);
    setup_toolbar(gui);
    
    handles = guidata(gui.window); 
    
    
    handles.use_popup = true;
    handles.fitting_params_controller = flim_fitting_params_controller(handles);
    handles.data_series_controller = flim_data_series_controller(handles);
    handles.data_series_list = flim_data_series_list(handles.data_series_listbox,handles.data_series_controller);
    handles.data_intensity_view = flim_data_intensity_view(handles);
    handles.roi_controller = roi_controller(handles);                                                   
    handles.fit_controller = flim_fit_controller(handles);    
    handles.data_decay_view = flim_data_decay_view(handles);
    handles.data_masking_controller = flim_data_masking_controller(handles);

    
    
    handles.menu_controller = front_end_menu_controller(handles);
%}
end
