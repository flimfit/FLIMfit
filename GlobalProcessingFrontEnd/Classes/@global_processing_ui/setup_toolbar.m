function setup_toolbar(obj)

    load('icons.mat');

    handles = guidata(obj.window);
    
    handles.toolbar = uitoolbar(obj.window);
    handles.tool_roi_rect_toggle = uitoggletool(handles.toolbar,'CData',rect_icon);
    handles.tool_roi_poly_toggle = uitoggletool(handles.toolbar,'CData',poly_icon);
    handles.tool_roi_circle_toggle = uitoggletool(handles.toolbar,'CData',ellipse_icon);
    
    guidata(obj.window,handles);

end