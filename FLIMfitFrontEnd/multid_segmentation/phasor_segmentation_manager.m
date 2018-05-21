
function phasor_segmentation_manager(data_series_controller)

    handles = setup_layout();
    
    handles.data_series_controller = data_series_controller; 
    handles.data_series_list = flim_data_series_list(handles);
    handles.segmentation_controller = phasor_segmentation_controller(handles);

    
    function handles = setup_layout()

        handles = struct();
        
        pad = 8;

        screen_pos = get(0,'ScreenSize');
        pos = [100 100 screen_pos(3:4) - 200];

        fh = figure('NumberTitle','off','Name','Segmentation Manager','Toolbar','none','Position',pos,'MenuBar','none');
        handles.figure1 = fh;
        
        layout_all = uix.VBox('Parent',fh,'Padding',pad*1.5,'Spacing',pad);
        layout = uix.HBox('Parent',layout_all,'Spacing',pad);

        buttons_layout = uix.HBox('Parent',layout_all,'Spacing',pad);
        uix.Empty('Parent',buttons_layout);
        handles.cancel_button = uicontrol('Style','pushbutton','String','Cancel','Parent',buttons_layout,'Callback',@(~,~) delete(fh));
        handles.ok_button = uicontrol('Style','pushbutton','String','OK','Parent',buttons_layout,'Callback',@(~,~) delete(fh));
        set(layout_all,'Heights',[-1 22]);
        set(buttons_layout,'Widths',[-1 200 200]);

        handles.data_series_table = uitable('Parent',layout);

        right_layout = uix.HBox('Parent',layout,'Spacing',pad);

        display_panel = uipanel('Parent',right_layout);
        handles.segmentation_axes = axes('Parent',display_panel);
        set(handles.segmentation_axes,'Units','normalized','Position',[0 0 1 1]);

        
        display_panel = uipanel('Parent',right_layout);
        handles.panel_layout = uix.Grid('Parent',display_panel);       

        set(right_layout,'Widths',[-1 -1]);
        set(layout,'Widths',[200,-1]);
        
        menu_file = uimenu(fh,'Label','File');
        %handles.menu_file_load_segmentation = uimenu(menu_file,'Label','Load Segmentation Images...');
        %handles.menu_file_load_single_segmentation = uimenu(menu_file,'Label','Load Single Segmentation Image...');
        %handles.menu_file_save_segmentation = uimenu(menu_file,'Label','Save Segmentation Images...');
        handles.menu_file_export_phasor_images = uimenu(menu_file,'Label','Export Phasor Images...','Separator','on');
        handles.menu_file_export_backgated_image = uimenu(menu_file,'Label','Export Backgated Image...');

    end

end