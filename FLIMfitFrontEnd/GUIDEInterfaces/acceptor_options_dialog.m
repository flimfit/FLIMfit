function varargout = acceptor_options_dialog(varargin)
% ACCEPTOR_OPTIONS_DIALOG MATLAB code for acceptor_options_dialog.fig
%      ACCEPTOR_OPTIONS_DIALOG, by itself, creates a new ACCEPTOR_OPTIONS_DIALOG or raises the existing
%      singleton*.
%
%      H = ACCEPTOR_OPTIONS_DIALOG returns the handle to a new ACCEPTOR_OPTIONS_DIALOG or the handle to
%      the existing singleton*.
%
%      ACCEPTOR_OPTIONS_DIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ACCEPTOR_OPTIONS_DIALOG.M with the given input arguments.
%
%      ACCEPTOR_OPTIONS_DIALOG('Property','Value',...) creates a new ACCEPTOR_OPTIONS_DIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before acceptor_options_dialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to acceptor_options_dialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help acceptor_options_dialog

% Last Modified by GUIDE v2.5 12-Jun-2013 11:52:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @acceptor_options_dialog_OpeningFcn, ...
                   'gui_OutputFcn',  @acceptor_options_dialog_OutputFcn, ...
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


% --- Executes just before acceptor_options_dialog is made visible.
function acceptor_options_dialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to acceptor_options_dialog (see VARARGIN)

% Choose default command line output for acceptor_options_dialog
handles.output = struct('background',[],'align',false);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes acceptor_options_dialog wait for user response (see UIRESUME)
 uiwait(handles.acceptor_options);


% --- Outputs from this function are returned to the command line.
function varargout = acceptor_options_dialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

    handles.output.align = get(handles.align_checkbox,'Value');
    guidata(hObject, handles);

    varargout{1} = handles.output;
    
    delete(handles.acceptor_options);


% --- Executes on button press in align_checkbox.
function align_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to align_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of align_checkbox
    handles.output.align = get(hObject,'Value');
    guidata(hObject, handles);
    
% --- Executes on button press in ok_pushbutton.
function ok_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ok_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    %fh = ancestor(hObject,'figure');     
    
    uiresume(handles.acceptor_options);
   


% --- Executes on button press in load_pushbutton.
function load_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to load_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [file,path] = uigetfile({'*.tif';'*.tiff'},'Select Background File...',getpref('GlobalAnalysisFrontEnd','DefaultFolder'));
    if file ~= 0

        set(handles.background_text,'String',file);
        handles.output.background = [path file];
        guidata(hObject, handles);
        
    end
    
    
    
