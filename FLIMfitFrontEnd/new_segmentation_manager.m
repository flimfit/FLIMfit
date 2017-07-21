
function new_segmentation_manager(data_series_controller)

    handles = setup_layout();
    
    handles.data_series_controller = data_series_controller; 
    handles.data_series_list = flim_data_series_list(handles);
    handles.segmentation_controller = segmentation_controller(handles);
    
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
        
        options_layout = uix.VBox('Parent',right_layout,'Spacing',pad/2);

        seg_panel = uipanel('Title','Automatic Segmentation','Parent',options_layout);
        seg_layout = uix.VBox('Parent',seg_panel,'Spacing',pad,'Padding',pad);

        alg_layout = uix.HBox('Parent',seg_layout,'Spacing',pad);
        uicontrol('Style','text','String','Algorithm','HorizontalAlignment','left','Parent',alg_layout);
        handles.algorithm_popup = uicontrol('Style','popupmenu','String',{''},'Parent',alg_layout);
        set(alg_layout,'Widths',[50 -1]);

        handles.parameter_table = uitable('Parent',seg_layout);

        seg_button_layout = uix.HBox('Parent',seg_layout,'Spacing',pad);
        uix.Empty('Parent',seg_button_layout);
        handles.segment_selected_button = uicontrol('Style','pushbutton','String','Segment Selected','Parent',seg_button_layout);
        handles.segment_button = uicontrol('Style','pushbutton','String','Segment All','Parent',seg_button_layout);
        set(seg_button_layout,'Widths',[-1 100 100])
        set(seg_layout,'Heights',[22 -1 22])

        
        filter_panel = uipanel('Title','Region Filtering','Parent',options_layout);
        filter_layout = uix.VBox('Parent',filter_panel,'Padding',pad,'Spacing',pad);

        handles.region_filter_table = uitable('Parent',filter_layout,'ColumnName',[],...
                                    'ColumnFormat',{'logical','char','numeric'},'ColumnEditable',[true false true],...
                                    'RowName',[],'ColumnWidth',{40 'auto' 100});

        filter_button_layout = uix.HBox('Parent',filter_layout,'Spacing',pad);
        handles.combine_regions_checkbox = uicontrol('Style','checkbox','String','Combine all regions','Parent',filter_button_layout);
        handles.apply_filtering_pushbutton = uicontrol('Style','pushbutton','String','Apply','Parent',filter_button_layout);
        set(filter_layout,'Heights',[-1 22])
        
        check_panel = uipanel('Title','Options','Parent',options_layout);
        check_layout = uix.VBox('Parent',check_panel,'Padding',pad);
        handles.replicate_mask_checkbox = uicontrol('Style','checkbox','String','Apply manual regions to all','Parent',check_layout);
        handles.trim_outliers_checkbox = uicontrol('Style','checkbox','String','Trim outliers for display','Value',1,'Parent',check_layout);

        brush_layout = uix.HBox('Parent',check_layout);
        uicontrol('Style','text','String','Brush Width','Parent',brush_layout);
        handles.brush_width_popup = uicontrol('Style','popupmenu','String',{'1','2','3','4','5','6','7','8','9','10'},'Parent',brush_layout,'Value',6);
        set(brush_layout,'Width',[70 -1]);
        uix.Empty('Parent',check_layout);
        
        set(check_layout,'Heights',[22 22 22 -1])
        
        handles.seg_results_table = uitable('Parent',options_layout,'ColumnName',{'Region','Area (px)','Del.'},...
                                    'ColumnFormat',{'char','numeric','logical'},'ColumnEditable',[false false true],...
                                    'RowName',[],'ColumnWidth',{60 98 40});

        handles.copy_to_all_button = uicontrol('Style','pushbutton','String','Copy to all images','Parent',options_layout);
        handles.delete_all_button = uicontrol('Style','pushbutton','String','Delete all regions','Parent',options_layout);

        set(options_layout,'Heights',[250 180 100 -1 22 22])
        set(right_layout,'Widths',[-1 300]);
        set(layout,'Widths',[200,-1]);
        
        menu_file = uimenu(fh,'Label','File');
        handles.menu_file_load_segmentation = uimenu(menu_file,'Label','Load Segmentation Images...');
        handles.menu_file_load_single_segmentation = uimenu(menu_file,'Label','Load Single Segmentation Image...');
        handles.menu_file_save_segmentation = uimenu(menu_file,'Label','Save Segmentation Images...');

        menu_OMERO = uimenu(fh,'Label','OMERO');
        handles.OMERO_Load_Segmentation_Images = uimenu(menu_OMERO,'Label','Load Segmentation Images...');
        handles.OMERO_Save_Segmentation_Images = uimenu(menu_OMERO,'Label','Save Segmentation Images...','Separator','on');
        handles.OMERO_Remove_Segmentation = uimenu(menu_OMERO,'Label','Remove Segmentation Image...');
        handles.OMERO_Remove_All_Segmentations = uimenu(menu_OMERO,'Label','Remove All Segmentation Images...');
       
        icons = load('icons.mat');
    
        handles.toolbar = uitoolbar(fh);
        handles.tool_roi_rect_toggle = uitoggletool(handles.toolbar,'CData',icons.rect_icon,'ToolTipString','Rectangle');
        handles.tool_roi_poly_toggle = uitoggletool(handles.toolbar,'CData',icons.poly_icon,'ToolTipString','Polygon');
        handles.tool_roi_freehand_toggle = uitoggletool(handles.toolbar,'CData',icons.freehand_icon,'ToolTipString','Freehand');
        handles.tool_roi_circle_toggle = uitoggletool(handles.toolbar,'CData',icons.ellipse_icon,'ToolTipString','Ellipse');
        handles.tool_roi_paint_toggle = uitoggletool(handles.toolbar,'CData',icons.paintbrush_icon,'ToolTipString','Paintbrush');
        handles.tool_roi_erase_toggle = uitoggletool(handles.toolbar,'CData',icons.eraser_icon,'ToolTipString','Erase');

        
    end
end