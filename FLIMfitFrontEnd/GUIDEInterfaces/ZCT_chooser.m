function varargout = ZCT_chooser(varargin)
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

% Last Modified by GUIDE v2.5 13-Sep-2012 16:16:39

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ZCT_chooser_OpeningFcn, ...
                   'gui_OutputFcn',  @ZCT_chooser_OutputFcn, ...
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
function ZCT_chooser_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ZCT_chooser (see VARARGIN)

%x = ZCT_chooser({3,4,5});
maxdims = cell2mat(varargin{1});
maxZ = maxdims(1);
maxC = maxdims(2);
maxT = maxdims(3);
    set(handles.popupmenu1,'String',(1:maxZ));
    set(handles.popupmenu2,'String',(1:maxC));
    set(handles.popupmenu3,'String',(1:maxT));
handles.choiceZ = 1;
handles.choiceC = 1;
handles.choiceT = 1;
%
handles.output = {handles.choiceZ,handles.choiceC,handles.choiceT};
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes ZCT_chooser wait for user response (see UIRESUME)
uiwait(handles.figure1);

% output
function varargout = ZCT_chooser_OutputFcn(hObject, eventdata, handles)
if ~isempty(handles)
    varargout{1} = handles.output;
    delete(handles.figure1);
else
    varargout{1} = {1,1,1};
end;

% Z
function popupmenu1_Callback(hObject, eventdata, handles)
handles.choiceZ = get(handles.popupmenu1, 'Value');
guidata(hObject,handles)
% Z.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% C
function popupmenu2_Callback(hObject, eventdata, handles)
handles.choiceC = get(handles.popupmenu2, 'Value');
guidata(hObject,handles)
% C
function popupmenu2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% T
function popupmenu3_Callback(hObject, eventdata, handles)
handles.choiceT = get(handles.popupmenu3, 'Value');
guidata(hObject,handles)
% T
function popupmenu3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Set.
function Set_Callback(hObject, eventdata, handles)
handles.output = {handles.choiceZ,handles.choiceC,handles.choiceT};
guidata(hObject,handles);
uiresume(handles.figure1);
