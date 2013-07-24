function varargout = chi2_display(varargin)
% CHI2_DISPLAY MATLAB code for chi2_display.fig
%      CHI2_DISPLAY, by itself, creates a new CHI2_DISPLAY or raises the existing
%      singleton*.
%
%      H = CHI2_DISPLAY returns the handle to a new CHI2_DISPLAY or the handle to
%      the existing singleton*.
%
%      CHI2_DISPLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CHI2_DISPLAY.M with the given input arguments.
%
%      CHI2_DISPLAY('Property','Value',...) creates a new CHI2_DISPLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before chi2_display_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to chi2_display_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help chi2_display

% Last Modified by GUIDE v2.5 04-Nov-2010 11:57:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @chi2_display_OpeningFcn, ...
                   'gui_OutputFcn',  @chi2_display_OutputFcn, ...
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


% --- Executes just before chi2_display is made visible.
function chi2_display_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to chi2_display (see VARARGIN)

% Choose default command line output for chi2_display
handles.output = hObject;

handles.fit_controller = varargin{1};

handles.chi2_display_controller = flim_chi2_display_controller(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes chi2_display wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = chi2_display_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in calculate_button.
function calculate_button_Callback(hObject, eventdata, handles)
% hObject    handle to calculate_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function display_factor_edit_Callback(hObject, eventdata, handles)
% hObject    handle to display_factor_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of display_factor_edit as text
%        str2double(get(hObject,'String')) returns contents of display_factor_edit as a double


% --- Executes during object creation, after setting all properties.
function display_factor_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to display_factor_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

handles.chi2_display_controller = [];

delete(hObject);
