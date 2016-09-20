
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
        
        layout_all = uiextras.VBox('Parent',fh,'Padding',pad*1.5,'Spacing',pad);
        layout = uiextras.HBox('Parent',layout_all,'Spacing',pad);

        buttons_layout = uiextras.HBox('Parent',layout_all,'Spacing',pad);
        uiextras.Empty('Parent',buttons_layout);
        handles.cancel_button = uicontrol('Style','pushbutton','String','Cancel','Parent',buttons_layout,'Callback',@(~,~) delete(fh));
        handles.ok_button = uicontrol('Style','pushbutton','String','OK','Parent',buttons_layout,'Callback',@(~,~) delete(fh));
        set(layout_all,'Sizes',[-1 22]);
        set(buttons_layout,'Sizes',[-1 200 200]);



        handles.data_series_table = uitable('Parent',layout);

        right_layout = uiextras.VBox('Parent',layout,'Spacing',pad);
        top_layout = uiextras.HBox('Parent',right_layout,'Spacing',pad);
        bottom_layout = uiextras.HBox('Parent',right_layout,'Spacing',pad);

        seg_panel = uipanel('Title','Automatic Segmentation','Parent',top_layout);
        seg_layout = uiextras.VBox('Parent',seg_panel,'Spacing',pad,'Padding',pad);

        alg_layout = uiextras.HBox('Parent',seg_layout,'Spacing',pad);
        uicontrol('Style','text','String','Algorithm','HorizontalAlignment','left','Parent',alg_layout);
        handles.algorithm_popup = uicontrol('Style','popupmenu','String',{''},'Parent',alg_layout);
        set(alg_layout,'Sizes',[50 -1]);

        handles.parameter_table = uitable('Parent',seg_layout);

        seg_button_layout = uiextras.HBox('Parent',seg_layout,'Spacing',pad);
        uiextras.Empty('Parent',seg_button_layout);
        handles.segment_selected_button = uicontrol('Style','pushbutton','String','Segment Selected','Parent',seg_button_layout);
        handles.segment_all_button = uicontrol('Style','pushbutton','String','Segment All','Parent',seg_button_layout);
        set(seg_button_layout,'Sizes',[-1 100 100])
        set(seg_layout,'Sizes',[22 -1 22])

        filter_panel = uipanel('Title','Region Filtering','Parent',top_layout);
        filter_layout = uiextras.VBox('Parent',filter_panel,'Padding',pad,'Spacing',pad);

        handles.region_filter_table = uitable('Parent',filter_layout,'ColumnName',[],...
                                    'ColumnFormat',{'logical','char','numeric'},'ColumnEditable',[true false true],...
                                    'RowName',[],'ColumnWidth',{40 'auto' 100});

        filter_button_layout = uiextras.HBox('Parent',filter_layout,'Spacing',pad);
        handles.combine_regions_checkbox = uicontrol('Style','checkbox','String','Combine all regions','Parent',filter_button_layout);
        handles.apply_filtering_pushbutton = uicontrol('Style','pushbutton','String','Apply','Parent',filter_button_layout);
        set(filter_layout,'Sizes',[-1 22])

        handles.segmentation_axes = axes('Parent',bottom_layout);

        options_layout = uiextras.VBox('Parent',bottom_layout,'Spacing',pad/2);

        handles.replicate_mask_checkbox = uicontrol('Style','checkbox','String','Apply manual regions to all','Parent',options_layout);
        handles.trim_outliers_checkbox = uicontrol('Style','checkbox','String','Trim outliers for display','Parent',options_layout);

        handles.seg_results_table = uitable('Parent',options_layout,'ColumnName',{'Region','Area (px)','Del.'},...
                                    'ColumnFormat',{'char','numeric','logical'},'ColumnEditable',[false false true],...
                                    'RowName',[],'ColumnWidth',{60 98 40});

        handles.copy_to_all_button = uicontrol('Style','pushbutton','String','Copy to all images','Parent',options_layout);
        handles.delete_all_button = uicontrol('Style','pushbutton','String','Delete all regions','Parent',options_layout);

        set(options_layout,'Sizes',[22 22 -1 22 22])
        set(right_layout,'Sizes',[150 -1]);
        set(bottom_layout,'Sizes',[-1 200]);
        set(layout,'Sizes',[200,-1]);
        
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
        handles.tool_roi_circle_toggle = uitoggletool(handles.toolbar,'CData',icons.ellipse_icon,'ToolTipString','Ellipse');
        handles.tool_roi_paint_toggle = uitoggletool(handles.toolbar,'CData',icons.paintbrush_icon,'ToolTipString','Ellipse');
        handles.tool_roi_erase_toggle = uitoggletool(handles.toolbar,'CData',icons.eraser_icon,'ToolTipString','Erase');

        
    end
end