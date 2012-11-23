function varargout = yuiry_segmentation_manager(varargin)
% YUIRY_SEGMENTATION_MANAGER M-file for yuiry_segmentation_manager.fig
%      YUIRY_SEGMENTATION_MANAGER, by itself, creates a new YUIRY_SEGMENTATION_MANAGER or raises the existing
%      singleton*.
%
%      H = YUIRY_SEGMENTATION_MANAGER returns the handle to a new YUIRY_SEGMENTATION_MANAGER or the handle to
%      the existing singleton*.
%
%      YUIRY_SEGMENTATION_MANAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in YUIRY_SEGMENTATION_MANAGER.M with the given input arguments.
%
%      YUIRY_SEGMENTATION_MANAGER('Property','Value',...) creates a new YUIRY_SEGMENTATION_MANAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before yuiry_segmentation_manager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to yuiry_segmentation_manager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help yuiry_segmentation_manager

% Last Modified by GUIDE v2.5 29-Oct-2012 12:29:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @yuiry_segmentation_manager_OpeningFcn, ...
                   'gui_OutputFcn',  @yuiry_segmentation_manager_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before yuiry_segmentation_manager is made visible.
function yuiry_segmentation_manager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to yuiry_segmentation_manager (see VARARGIN)

% Choose default command line output for yuiry_segmentation_manager
handles.output = hObject;

handles.data_series_controller = varargin{1};

handles.data_series_list = flim_data_series_list(handles);

handles.segmentation_controller = segmentation_controller(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes yuiry_segmentation_manager wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = yuiry_segmentation_manager_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in algorithm_popup.
function algorithm_popup_Callback(hObject, eventdata, handles)
% hObject    handle to algorithm_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns algorithm_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from algorithm_popup


% --- Executes during object creation, after setting all properties.
function algorithm_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to algorithm_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fh = ancestor(hObject,'figure');     
    delete(fh);


% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fh = ancestor(hObject,'figure');         
    delete(fh);

% --- Executes on selection change in data_series_listbox.
function data_series_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to data_series_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns data_series_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from data_series_listbox


% --- Executes during object creation, after setting all properties.
function data_series_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to data_series_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in yuiry_segment_button.
function yuiry_segment_button_Callback(hObject, eventdata, handles)
% hObject    handle to yuiry_segment_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function parameter_table_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to parameter_table (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in replicate_mask_checkbox.
function replicate_mask_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to replicate_mask_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of replicate_mask_checkbox


% --- Executes on selection change in algorithm_popup.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to algorithm_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns algorithm_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from algorithm_popup


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to algorithm_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in yuiry_segment_button.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to yuiry_segment_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(handles.segmentation_controller);
delete(hObject);




% --- Executes on button press in delete_all_button.
function delete_all_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_all_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in copy_to_all_button.
function copy_to_all_button_Callback(hObject, eventdata, handles)
% hObject    handle to copy_to_all_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_load_segmentation_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load_segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    try
        default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
    catch %#ok
        addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
        default_path = 'C:\';
    end

     pathname = uigetdir(default_path,'Choose the folder containing the segmented images');
    
    if ~isempty(pathname)
        handles.segmentation_controller.load_segmentation(pathname);
    end


% --------------------------------------------------------------------
function menu_file_save_segmentation_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save_segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    try
        default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
    catch %#ok
        addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
        default_path = 'C:\';
    end

     pathname = uigetdir(default_path,'Choose the folder to save the segmented images');
    
    if ~isempty(pathname)
        handles.segmentation_controller.save_segmentation(pathname);
    end


% --------------------------------------------------------------------
function menu_file_load_single_segmentation_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load_single_segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    try
        default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
    catch %#ok
        addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
        default_path = 'C:\';
    end

    [filename, pathname, filterindex] = uigetfile( ...
                 {'*.tif', 'TIFF image (*.tif)'},...
                 'Select file name',default_path);
    
    if ~isempty(filename)
        handles.segmentation_controller.load_single_segmentation([pathname filename])
    end


% --- Executes on button press in trim_outliers_checkbox.
function trim_outliers_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to trim_outliers_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of trim_outliers_checkbox


% --- Executes on button press in yuiry_segment_selected_button.
function yuiry_segment_selected_button_Callback(hObject, eventdata, handles)
% hObject    handle to yuiry_segment_selected_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in apply_filtering_pushbutton.
function apply_filtering_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to apply_filtering_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in combine_regions_checkbox.
function combine_regions_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to combine_regions_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of combine_regions_checkbox
