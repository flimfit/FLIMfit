function varargout = ZT_selection(varargin)
% ZT_SELECTION MATLAB code for ZT_selection.fig
%      ZT_SELECTION, by itself, creates a new ZT_SELECTION or raises the existing
%      singleton*.
%
%      H = ZT_SELECTION returns the handle to a new ZT_SELECTION or the handle to
%      the existing singleton*.
%
%      ZT_SELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ZT_SELECTION.M with the given input arguments.
%
%      ZT_SELECTION('Property','Value',...) creates a new ZT_SELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ZT_selection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ZT_selection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ZT_selection

% Last Modified by GUIDE v2.5 24-Apr-2013 15:53:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ZT_selection_OpeningFcn, ...
                   'gui_OutputFcn',  @ZT_selection_OutputFcn, ...
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


% --- Executes just before ZT_selection is made visible.
function ZT_selection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ZT_selection (see VARARGIN)

% Choose default command line output for ZT_selection
handles.output = hObject;

ZTSize = varargin{1};
sizeZ = ZTSize(1);
sizeT = ZTSize(2);

handles.sizeZ = sizeZ;
handles.sizeT = sizeT;

ZTMax = varargin{2};
maxZ = ZTMax(1);
maxT = ZTMax(2);

handles.maxZ = maxZ;
handles.maxT = maxT;

ZTMin = varargin{3};
handles.minZ = ZTMin(1);
handles.minT = ZTMin(2);


dataZ(:,1) = num2cell(1:sizeZ);
dataZ(:,2)= num2cell( false(sizeZ,1));
dataZ(1:maxZ,2) = num2cell(true);
set(handles.uitableZ,'Data',dataZ);


dataT(:,1) = num2cell(1:sizeT);
dataT(:,2)= num2cell( false(sizeT,1));
dataT(1:maxT,2) = num2cell(true);
set(handles.uitableT,'Data',dataT);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ZT_selection wait for user response (see UIRESUME)
 uiwait(handles.figure1);
 
 



% --- Outputs from this function are returned to the command line.
function varargout = ZT_selection_OutputFcn(hObject, eventdata, handles) 
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


% --- Executes when entered data in editable cell(s) in uitableZ.
function uitableZ_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableZ (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edite
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'Data'); % get the data cell array of the table
sett = cell2mat(squeeze(data(:,2)));
if eventdata.EditData % if the checkbox was set to true
    if sum(sett) > handles.maxZ
        sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
        first = squeeze(find(sett,1));
        data(first,2) = num2cell(false);  
    end   
else
    if sum(sett) <= handles.minZ
        sett(eventdata.Indices(1) ) = 1;  %eliminate the box just unticked from enquiries
        first = squeeze(find(sett==0,1));
        if isempty(first)
            first = eventdata.Indices(1);   % no choice
        end
        data(first,2) = num2cell(true);  
    end     
end


set(hObject,'Data',data); % now set the table's data to the updated data cell array
% Update handles structure
guidata(hObject, handles);





% --- Executes when entered data in editable cell(s) in uitableT.
function uitableT_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableT (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'Data'); % get the data cell array of the table
sett = cell2mat(squeeze(data(:,2)));
if eventdata.EditData % if the checkbox was set to true
    if sum(sett) > handles.maxT
        sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
        first = squeeze(find(sett,1));
        data(first,2) = num2cell(false);  
    end   
else
    if sum(sett) <= handles.minT
        sett(eventdata.Indices(1) ) = 1;  %eliminate the box just unticked from enquiries
        first = squeeze(find(sett == 0,1));
        if isempty(first)
            first = eventdata.Indices(1);   % no choice
        end
        data(first,2) = num2cell(true);  
    end   
     
end
        

set(hObject,'Data',data); % now set the table's data to the updated data cell array
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in selectButton.
function selectButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataZ = get(handles.uitableZ,'Data');
sel = cell2mat(dataZ(:,2));
nums = cell2mat(dataZ(:,1));
Z = nums(sel ~= 0)';


dataT = get(handles.uitableT,'Data');
sel = cell2mat(dataT(:,2));
nums = cell2mat(dataT(:,1));
T = nums(sel ~= 0)';

handles.output = {Z,T};


guidata(hObject,handles);

uiresume(handles.figure1);
