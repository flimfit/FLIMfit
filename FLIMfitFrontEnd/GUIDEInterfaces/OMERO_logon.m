function varargout = OMERO_logon(varargin)
% OMERO_LOGON M-file for OMERO_logon.fig
%      OMERO_LOGON, by itself, creates a new OMERO_LOGON or raises the existing
%      singleton*.
%
%      H = OMERO_LOGON returns the handle to a new OMERO_LOGON or the handle to
%      the existing singleton*.
%
%      OMERO_LOGON('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OMERO_LOGON.M with the given input arguments.
%
%      OMERO_LOGON('Property','Value',...) creates a new OMERO_LOGON or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OMERO_logon_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OMERO_logon_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OMERO_logon

% Last Modified by GUIDE v2.5 28-Jul-2013 19:52:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OMERO_logon_OpeningFcn, ...
                   'gui_OutputFcn',  @OMERO_logon_OutputFcn, ...
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


% --- Executes just before OMERO_logon is made visible.
function OMERO_logon_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OMERO_logon (see VARARGIN)

% Choose default command line output for OMERO_logon
handles.output = hObject;

handles.server = '??';
handles.userName = '??';
handles.passwd = [];

handles.output = {'??', '??', '??'};

try
    login_details = getpref('GlobalAnalysisFrontEnd','OMEROlogin');
    handles.server = login_details{1};
    handles.userName = login_details{2};
    
    set(handles.Server,'string',login_details{1});
    set(handles.UserName,'string',login_details{2});
    
    % Set focus to password
    uicontrol(handles.Passwd);
    
catch 
    addpref('GlobalAnalysisFrontEnd','OMEROlogin',{'',''})
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OMERO_logon wait for user response (see UIRESUME)
 uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = OMERO_logon_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    varargout{1} = [];
else
 varargout{1} = handles.output;
 delete(handles.figure1);

end






% --- Executes during object creation, after setting all properties.
function Server_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Server (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Server_Callback(hObject, eventdata, handles)
% hObject    handle to Server (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Server as text
%        str2double(get(hObject,'String')) returns contents of Server as a double
server = get(hObject,'String');

% Save the new  value
handles.server = server;
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function UserName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UserName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function UserName_Callback(hObject, eventdata, handles)
% hObject    handle to UserName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of UserName as text
%        str2double(get(hObject,'String')) returns contents of UserName as a double
userName = get(hObject,'String');

% Save the new  value
handles.userName = userName;
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function Passwd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Passwd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white') ;
end





function Passwd_Callback(hObject, eventdata, handles)
% hObject    handle to Passwd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Passwd as text
%        str2double(get(hObject,'String')) returns contents of Passwd as a double

%
% Save the new  value
%handles.Passwd = Passwd;
%guidata(hObject,handles);




% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

server = handles.server;
userName = handles.userName;
passwd = handles.passwd;

handles.output = {server, userName, passwd};

setpref('GlobalAnalysisFrontEnd','OMEROlogin',{server,userName});

guidata(hObject,handles);


uiresume(handles.figure1);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on Passwd and none of its controls.
function Passwd_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to Passwd (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

key = eventdata.Key;
switch key
    case 'backspace'
        handles.passwd = handles.passwd(1:end-1); % Delete the last character in the password
    case 'return'  % This cannot be done through callback without making tab to the same thing
        % do nothing
    case 'shift'
        % do nothing
    otherwise
        handles.passwd = [handles.passwd eventdata.Character];
        
end


asterisk(1,1:length(handles.passwd)) = '*'; % Create a string of asterisks the same size as the password
set(hObject,'String',asterisk) % Set the text in the password edit box to the asterisk string
guidata(hObject,handles);


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

server = '??';
userName = '??';
passwd = [];

handles.output = {server, userName, passwd};

guidata(hObject,handles);


uiresume(handles.figure1);


