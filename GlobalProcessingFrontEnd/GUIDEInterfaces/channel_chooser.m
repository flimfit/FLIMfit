function varargout = channel_chooser(varargin)
% ZCT_CHOOSER MATLAB code for ZCT_chooser.fig
%      ZCT_CHOOSER, by itself, creates a new ZCT_CHOOSER or raises the existing
%      singleton*.
%
%      H = ZCT_CHOOSER returns the handle to a new ZCT_CHOOSER or the handle to
%      the existing singleton*.
%
%      ZCT_CHOOSER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ZCT_CHOOSER.M with the given input arguments.
%
%      ZCT_CHOOSER('Property','Value',...) creates a new ZCT_CHOOSER or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ZCT_chooser_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ZCT_chooser_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ZCT_chooser

% Last Modified by GUIDE v2.5 18-Jan-2013 11:54:39

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @channel_chooser_OpeningFcn, ...
                   'gui_OutputFcn',  @channel_chooser_OutputFcn, ...
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

% --- Executes just before ZCT_chooser is made visible.
function channel_chooser_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to channel_chooser (see VARARGIN)

%x = channel_chooser({3,4,5});
maxdims = cell2mat(varargin{1});
maxC = maxdims(1);

    set(handles.popupmenu2,'String',(1:maxC));

handles.choiceC = 1;

%
handles.output = {handles.choiceC};
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes channel_chooser wait for user response (see UIRESUME)
uiwait(handles.figure1);

% output
function varargout = channel_chooser_OutputFcn(hObject, eventdata, handles)
if ~isempty(handles)
    varargout{1} = handles.output;
    delete(handles.figure1);
else
    varargout{1} = {-1};
end;

% C
function popupmenu2_Callback(hObject, eventdata, handles)
handles.choiceC = get(handles.popupmenu2, 'Value');
guidata(hObject,handles)
% C
function popupmenu2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Set.
function Set_Callback(hObject, eventdata, handles)
handles.output = {handles.choiceC};
guidata(hObject,handles);
uiresume(handles.figure1);


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
