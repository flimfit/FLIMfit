function varargout = ZCT_selection(varargin)
% ZCT_SELECTION MATLAB code for ZCT_selection.fig
%      ZCT_SELECTION, by itself, creates a new ZCT_SELECTION or raises the existing
%      singleton*.
%
%      H = ZCT_SELECTION returns the handle to a new ZCT_SELECTION or the handle to
%      the existing singleton*.
%
%      ZCT_SELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ZCT_SELECTION.M with the given input arguments.
%
%      ZCT_SELECTION('Property','Value',...) creates a new ZCT_SELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ZCT_selection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ZCT_selection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ZCT_selection

% Last Modified by GUIDE v2.5 15-Jan-2014 19:52:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ZCT_selection_OpeningFcn, ...
                   'gui_OutputFcn',  @ZCT_selection_OutputFcn, ...
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


% --- Executes just before ZCT_selection is made visible.
function ZCT_selection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ZCT_selection (see VARARGIN)

% Choose default command line output for ZCT_selection
handles.output = hObject;

set(handles.uitablePerp,'Visible','off');

ZCTSize = varargin{1};
sizeZ = ZCTSize(1);
sizeC = ZCTSize(2);
sizeT = ZCTSize(3);

handles.sizeZ = sizeZ;
handles.sizeC = sizeC;
handles.sizeT = sizeT;

ZCTMax = varargin{2};
maxZ = ZCTMax(1);
maxC = ZCTMax(2);
maxT = ZCTMax(3);

handles.maxZ = maxZ;
handles.maxC = maxC;
handles.maxT = maxT;

ZCTMin = varargin{3};
handles.minZ = ZCTMin(1);
handles.minC = ZCTMin(2);
handles.minT = ZCTMin(3);

pol_resolved = varargin{4};
handles.pol_resolved = pol_resolved;


dataZ(:,1) = num2cell(1:sizeZ);
dataZ(:,2)= num2cell( false(sizeZ,1));
dataZ(1:handles.minZ,2) = num2cell(true);
set(handles.uitableZ,'Data',dataZ);

dataC(:,1) = num2cell(1:sizeC);
dataC(:,2)= num2cell( false(sizeC,1));
dataC(1:handles.minC,2) = num2cell(true);

if nargin > 7
    chan_info = varargin{5};
    if length(chan_info) == sizeC
        dataC(:,3) = chan_info;
    end
end
set(handles.uitableC,'Data',dataC);

dataT(:,1) = num2cell(1:sizeT);
dataT(:,2)= num2cell( false(sizeT,1));
dataT(1:handles.minT,2) = num2cell(true);
set(handles.uitableT,'Data',dataT);


if pol_resolved
    maxC = 1;
    handles.maxC = 1;
    set(handles.uitablePerp,'Visible','on');
    name{1} = '';
    name{2} = 'Parallel';
    set(handles.uitableC,'ColumnName',name);
    
    dataPerp(:,1) = num2cell(1:sizeC);
    dataPerp(:,2)= num2cell( false(sizeC,1));
    dataPerp(2,2) = num2cell(true);
    set(handles.uitablePerp,'Data',dataPerp);
    
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ZCT_selection wait for user response (see UIRESUME)
 uiwait(handles.figure1);
 
 



% --- Outputs from this function are returned to the command line.
function varargout = ZCT_selection_OutputFcn(hObject, eventdata, handles) 
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
    if sum(sett) < handles.minZ
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


% --- Executes when entered data in editable cell(s) in uitableC.
function uitableC_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableC (see GCBO)
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
    if sum(sett) > handles.maxC
        sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
        first = squeeze(find(sett,1));
        data(first,2) = num2cell(false);  
    end 
    % if polarisation check for clashes between channels
    if handles.pol_resolved
        dataPerp = get(handles.uitablePerp,'Data');
        settPerp = cell2mat(squeeze(dataPerp(:,2)));
        firstPerp = squeeze(find(settPerp,1));
        if firstPerp == eventdata.Indices(1)
            dataPerp(eventdata.Indices(1),2) = num2cell(false);
            set(handles.uitablePerp,'Data',dataPerp);
        end
    end
    
 else
    if sum(sett) < handles.minC
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
    if sum(sett) < handles.minT
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

% --- Executes when entered data in editable cell(s) in uitablePerp.
function uitablePerp_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableC (see GCBO)
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
    % check whether this clashes with parallel chan
    dataC = get(handles.uitableC,'Data');
    settC = cell2mat(squeeze(dataC(:,2)));
    firstC = squeeze(find(settC,1));
    if firstC == eventdata.Indices(1)
        data(eventdata.Indices(1),2) = num2cell(false);
    else
        if sum(sett) > handles.maxC
            sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
            first = squeeze(find(sett,1));
            data(first,2) = num2cell(false);  
        end 
    end
 else
    if sum(sett) < handles.minC
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



% --- Executes on button press in selectButton.
function selectButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataZ = get(handles.uitableZ,'Data');
sel = cell2mat(dataZ(:,2));
nums = cell2mat(dataZ(:,1));
Z = nums(sel ~= 0)';

dataC = get(handles.uitableC,'Data');
sel = cell2mat(dataC(:,2));
nums = cell2mat(dataC(:,1));
C = nums(sel ~= 0)';

dataT = get(handles.uitableT,'Data');
sel = cell2mat(dataT(:,2));
nums = cell2mat(dataT(:,1));
T = nums(sel ~= 0)';

if handles.pol_resolved
    dataPerp = get(handles.uitablePerp,'Data');
    sel = cell2mat(dataPerp(:,2));
    nums = cell2mat(dataPerp(:,1));
    P = nums(sel ~= 0)';
    C = [C P];
end

handles.output = {Z,C,T};


guidata(hObject,handles);

uiresume(handles.figure1);
