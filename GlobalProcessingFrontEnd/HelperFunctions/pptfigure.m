%{
Copyright (c) 2011, Dmitriy Aronov
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are 
met:

    * Redistributions of source code must retain the above copyright 
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in 
      the documentation and/or other materials provided with the distribution
      
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
%}

function varargout = pptfigure(varargin)
% pptfigure
%   Creates a new Matlab figure with a PowerPoint Export button on the
%   toolbar. Pressing the button exports the figure to PowerPoint with
%   default property settings. After exporting, various features of the
%   figure are automatically edited directly in PowerPoint to allow easy
%   subsequent editing.
%
% pptfigure add
%   Places a PowerPoint Export button on the toolbar of the current figure.
%
% pptfigure delete
%   Removes any existing PowerPoint Export button from the toolbar of the
%   current figure.
%
% pptfigure all
%   Places a PowerPoint Export button on the toolbar of each opened figure.
%
% pptfigure on
%   Turns on the option to automatically place a PowerPoint Export button
%   on each newly created figure in the future. This will effect any Matlab
%   process that creates a new figure.
%
% pptfigure off
%   Turns off the automatic button placement option.
%
% pptfigure(H)
%   Exports Figure H to PowerPoint. Equivalent to clicking the PowerPoint
%   Export button (if available) on the toolbar. If Figure H does not
%   exist, creates a new figure with handle H and a PowerPoint Export
%   button on the toolbar.
%
% pptfigure(H,'PropertyName',PropertyValue,...)
%   Exports Figure H to PowerPoint. Refer to the documentation for accepted
%   property names and values.
%
% pptfigure('PropertyName',PropertyValue,...)
%   Changes default property values used by pptfigure (e.g. when the
%   PowerPoint Export button on the toolbar is pressed). Defaults are
%   stored in a workspace structure variable pptfigureDefaults. Clear this
%   variable to reset all default property values.

% H = pptfigure(...)
%   If buttons were added or removed, returns the handles of all affected
%   figures. If a figure was exported, returns the affected slide number in
%   PowerPoint. Otherwise returns 0.
%
% (c) 2011, by Dmitriy Aronov


% Read defaults, if available
try
    pptfigureDefaults = evalin('base','pptfigureDefaults');
catch %#ok<CTCH>
    % No defaults variable in the workspace
    pptfigureDefaults = struct;
end

if isempty(varargin) || ~isscalar(varargin{1}) || ~ishandle(varargin{1})
    % Various non-exporting functions of pptfigure
    if ~isempty(varargin) && strcmpi(varargin{1},'add')
        % Add an export button to the current figure
        H = gcf;
        toolbar = findall(H,'Type','uitoolbar');
        if isempty(findall(H,'ToolTipString', ...
                'PowerPoint Export')) && ~isempty(toolbar)
            uipushtool(toolbar,'CData',get_ppt_image, ...
                'Separator','on','HandleVisibility','off', ...
                'ToolTipString','PowerPoint Export', ...
                'ClickedCallback', ...
                ['pptfigure(' num2str(H) ');']);
        end
    elseif ~isempty(varargin) && strcmpi(varargin{1},'delete')
        % Delete the export button from the current figure
        H = gcf;
        f = findall(H,'ToolTipString','PowerPoint Export');
        delete(f);
    elseif ~isempty(varargin) && strcmpi(varargin{1},'on')
        % Turn the automatic export button placement on
        set(0,'defaultfigurecreatefcn',@pptfigure);
        H = 0;
    elseif ~isempty(varargin) && strcmpi(varargin{1},'off')
        % Turn the automatic export button placement off
        set(0,'defaultfigurecreatefcn','');
        H = 0;
    elseif ~isempty(varargin) && strcmpi(varargin{1},'all')
        % Place export buttons on all currently opened figures
        figs = findobj('type','figure');
        H = [];
        for hand = figs'
            toolbar = findall(hand,'Type','uitoolbar');
            if isempty(findall(hand,'ToolTipString', ...
                    'PowerPoint Export')) && ~isempty(toolbar)
                H(end+1) = uipushtool(toolbar,'CData',get_ppt_image, ...
                    'Separator','on','HandleVisibility','off', ...
                    'ToolTipString','PowerPoint Export', ...
                    'ClickedCallback', ...
                    ['pptfigure(' num2str(hand) ');']); %#ok<AGROW>
            end
        end
    elseif mod(length(varargin),2)==0
        for c = 1:2:length(varargin)-1
            if ~ischar(varargin{c})
                error('Invalid input to pptfigure: string expected');
            end
            pptfigureDefaults.(varargin{c}) = varargin{c+1};
        end
        assignin('base','pptfigureDefaults',pptfigureDefaults);
        H = 0;
    else
        % Create new figure
        if isempty(varargin)
            H = figure;
        else
            if length(varargin)>1
                error('Invalid number of arguments to pptfigure');
            end
            try
                H = figure(varargin{1});
            catch %#ok<CTCH>
                if isscalar(varargin{1})
                    error(['Invalid input to pptfigure: ' ...
                        num2str(varargin{1}) ...
                        ' is not a valid figure handle']);
                else
                    error(['Invalid input to pptfigure: ' ...
                        'figure handle or recognizable string expected']);
                end
            end
        end
        
        % Add an export button to the toolbar
        toolbar = findall(H,'Type','uitoolbar');
        if isempty(findall(H,'ToolTipString', ...
                'PowerPoint Export')) && ~isempty(toolbar)
            uipushtool(toolbar,'CData',get_ppt_image,'Separator','on',...
                'HandleVisibility','off','ToolTipString', ...
                'PowerPoint Export','ClickedCallback', ...
                ['pptfigure(' num2str(H) ');']);
        end
    end
    if nargout > 0
        varargout{1} = H;
    end
    return
end

% Check that the input handle is a figure
H = varargin{1};
if ~strcmpi(get(H,'type'),'figure')
    error(['Invalid input to pptfigure: handle ' num2str(H) ...
        ' is not a figure']);
end

% If figure is empty, add an export button
if length(varargin)==2 && isempty(varargin{2})
    toolbar = findall(H,'Type','uitoolbar');
    if isempty(findall(H,'ToolTipString', ...
            'PowerPoint Export')) && ~isempty(toolbar)
        uipushtool(toolbar,'CData',get_ppt_image, ...
            'Separator','on','HandleVisibility','off', ...
            'ToolTipString','PowerPoint Export', ...
            'ClickedCallback', ...
            ['pptfigure(' num2str(H) ');']);
    end
    return
end

% Get a list of axes and check that they are 2D
axesList = findall(H,'type','axes');
for c = 1:length(axesList)
    [az el] = view(axesList(c));
    if az~=0 || el~=90
        error(['Invalid figure passed to pptfigure: ' ...
            'all axes must be 2D (azimuth=0, elevation=90)']);
    end
end

% Get axis positions
axesPos = cell(1,length(axesList));
for c = 1:length(axesList)
    axesPos{c} = get(axesList(c),'position');
end

% Find all legends
legends = [];
legendObjects = [];
for indx = 1:length(axesList)
    [legh,obj,~,~] = legend(axesList(indx));
    legends = [legends; legh]; %#ok<AGROW>
    legendObjects = [legendObjects; obj]; %#ok<AGROW>
end

% Check that there is an odd number of arguments
if length(varargin)>1 && mod(length(varargin),2)==0
    error('Invalid number of arguments to pptfigure');
end

% Attach default property values
fields = fieldnames(pptfigureDefaults);
varattach = cell(1,0);
for c = 1:length(fields)
    varattach{end+1} = fields{c}; %#ok<AGROW>
    varattach{end+1} = pptfigureDefaults.(fields{c}); %#ok<AGROW>
end
varargin = [varargin(1) varattach varargin(2:end)];

% Read all property values
prop.autoGroupMin = 5;
prop.groups = {};
prop.height = [];
prop.left = [];
prop.backVisibility = 'auto';
prop.bitmapResolution = [];
prop.metaResolution = 0;
prop.slideNumber = 'append';
prop.switchSlide = true;
prop.top = [];
prop.width = [];
prop.ppt = [];
fields = fieldnames(prop);
for c = 2:2:length(varargin)
    isgood = 0;
    for d = 1:length(fields)
        if strcmpi(varargin{c},fields{d})
            isgood = 1;
            prop.(fields{d}) = varargin{c+1};
        end
    end
    if isgood == 0
        error(['Invalid pptfigure property ''' varargin{c} '''']);
    end
end

% Process group numbers
if ischar(prop.groups)
    prop.groups = eval(prop.groups);
end
if ~iscell(prop.groups)
    prop.groups = {prop.groups};
end
if ischar(prop.bitmapResolution)
    prop.bitmapResolution = eval(prop.bitmapResolution);
end

% Create axes groups if resolution applies to all objects
if ~isempty(prop.bitmapResolution) && isempty(prop.groups)
    for ax = length(axesList):-1:1
        if isempty(find(legends==axesList(ax),1))
            prop.groups{end+1} = get(axesList(ax),'children');
        end
    end
end

% Match resolution values to groups
if ~isempty(prop.bitmapResolution)
    if length(prop.bitmapResolution)==1
        prop.bitmapResolution = repmat(prop.bitmapResolution,1,length(prop.groups));
    else
        if length(prop.bitmapResolution)~=length(prop.groups)
            error('Wrong number of resolution values');
        end
    end
end


% Create automatic groups
prop.groups = prop.groups(:);
groupedObjects = cell2mat(prop.groups);
for ax = 1:length(axesList)
    children = get(axesList(ax),'children');
    if isempty(children)
        continue
    end
    types = get(children,'type');
    if ~iscell(types)
        types = {types};
    end
    typeList = unique(types);
    for indx = 1:length(typeList)
        f = cellfun(@(x)strcmp(x,typeList{indx}),types);
        obj = setdiff(children(f),groupedObjects);
        if length(obj)<2
            continue
        end
        switch typeList{indx}
            case 'line'
                propList = {'Color','LineStyle','LineWidth','Marker', ...
                    'MarkerSize','MarkerEdgeColor','MarkerFaceColor'};
            case 'text'
                propList = {'BackgroundColor','Color','EdgeColor', ...
                    'FontAngle','FontName','FontSize','FontUnits', ...
                    'FontWeight','HorizontalAlignment','LineStyle', ...
                    'LineWidth','Margin','VerticalAlignment'};
            otherwise
                propList = {};
        end
        propValues = zeros(length(obj),length(propList));
        for p = 1:length(propList)
            vals = cellfun(@(x)num2str(x),get(obj,propList{p}), ...
                'uniformoutput',false);
            [~, ~, j] = unique(vals);
            propValues(:,p) = j;
        end
        [~, ~, j] = unique(propValues,'rows');
        for c = 1:max(j)
            f = find(j==c);
            if length(f)>=prop.autoGroupMin
                prop.groups{end+1} = obj(f);
            end
        end
    end
end

% Fill missing resolution values with NaN
prop.bitmapResolution(end+1:length(prop.groups)) = NaN;

% Determine the axis of origin for each bitmap group
bitmapAxis = NaN(size(prop.bitmapResolution));
for indx = 1:length(prop.bitmapResolution)
    if ~isnan(prop.bitmapResolution(indx))
        ax = get(prop.groups{indx},'parent');
        if iscell(ax)
            ax = unique(cell2mat(ax));
            if length(ax)>1
                error('Objects in a bitmap group are from different axes');
            end
        end
        bitmapAxis(indx) = ax;
    end
end

% Connect to PowerPoint

if ~isempty(prop.ppt)
    op = prop.ppt;
else
    ppt = actxserver('PowerPoint.Application');
    % Open current presentation
    if get(ppt.Presentations,'Count')==0
        op = invoke(ppt.Presentations,'Add');
    else
        op = get(ppt,'ActivePresentation');
    end
end

% Set slide object to be the active pane
wind = get(ppt,'ActiveWindow');
panes = get(wind,'Panes');
slide_pane = invoke(panes,'Item',2);
invoke(slide_pane,'Activate');

% Identify current slide
try
    currSlide = wind.Selection.SlideRange.SlideNumber;
catch %#ok<CTCH>
    % No slides
end

% Select the slide to which the figure will be exported
slide_count = int32(get(op.Slides,'Count'));
if strcmpi(prop.slideNumber,'append')
    slide = invoke(op.Slides,'Add',slide_count+1,11);
    shapes = get(slide,'Shapes');
    invoke(slide,'Select');
    invoke(shapes.Range,'Delete');
else
    if strcmpi(prop.slideNumber,'last')
        slideNum = slide_count;
    elseif strcmpi(prop.slideNumber,'current');
        slideNum = get(wind.Selection.SlideRange,'SlideNumber');
    else
        slideNum = prop.slideNumber;
    end
    slide = op.Slides.Item(slideNum);
    invoke(slide,'Select');
end

% Find all objects
objects = [];
for indx = 1:length(axesList)
    objects = [objects; axesList(indx)]; %#ok<AGROW>
    objects = [objects; get(axesList(indx),'title')]; %#ok<AGROW>
    objects = [objects; get(axesList(indx),'xlabel')]; %#ok<AGROW>
    objects = [objects; get(axesList(indx),'ylabel')]; %#ok<AGROW>
    objects = [objects; get(axesList(indx),'children')]; %#ok<AGROW>
end
invisible = zeros(size(objects));
for indx = 1:length(objects)
    invisible(indx) = strcmp(get(objects(indx),'visible'),'off');
end

% List of exported groups
exportedGroups = zeros(1,length(prop.groups));

% Backup axis information
xLimModes = get(axesList,'xlimmode');
if ~iscell(xLimModes)
    xLimModes = {xLimModes};
end
set(axesList,'xlimmode','manual');
yLimModes = get(axesList,'ylimmode');
if ~iscell(yLimModes)
    yLimModes = {yLimModes};
end
set(axesList,'ylimmode','manual');

% Count the number of shapes originally on the slide
originalCount = get(slide.Shapes,'Count');

% Back up axis properties
backupXLabel = cell(1,length(axesList));
backupYLabel = cell(1,length(axesList));
backupTitle = cell(1,length(axesList));
backupColor = cell(1,length(axesList));
xTickLabs = cell(1,length(axesList));
yTickLabs = cell(1,length(axesList));
xTickModes = cell(1,length(axesList));
yTickModes = cell(1,length(axesList));
xTickLabModes = cell(1,length(axesList));
yTickLabModes = cell(1,length(axesList));
for ax = 1:length(axesList)
    backupXLabel{ax} = get(get(axesList(ax),'xlabel'),'string');
    backupYLabel{ax} = get(get(axesList(ax),'ylabel'),'string');
    backupTitle{ax} = get(get(axesList(ax),'title'),'string');
    backupColor{ax} = get(axesList(ax),'color');
    xTickModes{ax} = get(axesList(ax),'xtickmode');
    yTickModes{ax} = get(axesList(ax),'ytickmode');
    xTickLabModes{ax} = get(axesList(ax),'xticklabelmode');
    yTickLabModes{ax} = get(axesList(ax),'yticklabelmode');
    xlabel(axesList(ax),'');
    ylabel(axesList(ax),'');
    title(axesList(ax),'');            
    switch prop.backVisibility
        case 'on'
            % Leave background
        case 'auto'
            if strcmp(num2str(get(axesList(ax),'color')), ...
                    num2str(get(0,'defaultaxescolor'))) && ...
                (strcmp(num2str(get(H,'color')), ...
                    num2str(get(0,'defaultfigurecolor'))) || ...
                strcmp(get(H,'color'),'none'))
                set(axesList(ax),'color','none');
            end
        case 'off'
            set(axesList(ax),'color','none');
    end
end

% Information whether axes are in scientific notation
sciXAxis = zeros(1,length(axesList));
sciYAxis = zeros(1,length(axesList));

% Remove invisible ticks
for ax = 1:length(axesList)
    if strcmp(get(axesList(ax),'xtickmode'),'manual')
        xl = get(axesList(ax),'xlim');
        xtick = get(axesList(ax),'xtick');
        f = find(xtick<xl(1) | xtick>xl(2));
        if strcmp(get(axesList(ax),'xscale'),'log')
            g = find(xtick<=0);
            f(end+1:end+length(g)) = g;
        end
        xtick(f) = [];
        set(axesList(ax),'xtick',xtick);
    end
    if strcmp(get(axesList(ax),'ytickmode'),'manual')
        yl = get(axesList(ax),'ylim');
        ytick = get(axesList(ax),'ytick');
        f = find(ytick<yl(1) | ytick>yl(2));
        if strcmp(get(axesList(ax),'yscale'),'log')
            g = find(ytick<=0);
            f(end+1:end+length(g)) = g;
        end
        ytick(f) = [];
        set(axesList(ax),'ytick',ytick);
    end
end

% Assign code to tick labels
for ax = 1:length(axesList)
    val = get(axesList(ax),'xtick');
    xl = get(axesList(ax),'xlim');
    val = val(val>=xl(1) & val<=xl(2));
    set(axesList(ax),'xtick',val);
    dm = get(axesList(ax),'xticklabel');
    if ~iscell(dm)
        for d = 1:size(dm,1)
            xTickLabs{ax}{d} = deblank(dm(d,:));
        end
    else
        xTickLabs{ax} = dm;
    end
    sz = length(xTickLabs{ax});
    for j = sz+1:length(val)
        if mod(j,sz)==0
            xTickLabs{ax}{j} = xTickLabs{ax}{sz};
        else
            xTickLabs{ax}{j} = xTickLabs{ax}{mod(j,sz)};
        end
    end
    str = repmat('n',length(xTickLabs{ax}),1);
    for j = 1:length(val)
        if val(j)>0 && log10(val(j))==str2double(xTickLabs{ax}(j)) && ...
                strcmp(xTickLabModes{ax},'auto')
            str(j) = 'l';
        end
        if val(j)>0 && strcmp(xTickLabModes{ax},'auto')
            sciXAxis(ax) = -log10(str2double(xTickLabs{ax}(j))/val(j));
            if strcmp(str(j),'l')
                sciXAxis(ax) = 0;
            end
            sciXAxis = round(sciXAxis);
        end
    end
    loc = get(axesList(ax),'xaxislocation');
    
    set(axesList(ax),'xticklabel',[repmat(loc(1),length(val),1) str]);
    
    val = get(axesList(ax),'ytick');
    yl = get(axesList(ax),'ylim');
    val = val(val>=yl(1) & val<=yl(2));
    set(axesList(ax),'ytick',val);
    dm = get(axesList(ax),'yticklabel');
    if ~iscell(dm)
        for d = 1:size(dm,1)
            yTickLabs{ax}{d} = deblank(dm(d,:));
        end
    else
        yTickLabs{ax} = dm;
    end
    sz = length(yTickLabs{ax});
    for j = sz+1:length(val)
        if mod(j,sz)==0
            yTickLabs{ax}{j} = yTickLabs{ax}{sz};
        else
            yTickLabs{ax}{j} = yTickLabs{ax}{mod(j,sz)};
        end
    end
    str = repmat('n',length(yTickLabs{ax}),1);
    for j = 1:length(val)
        if val(j)>0 && log10(val(j))==str2double(yTickLabs{ax}(j)) && ...
                strcmp(yTickLabModes{ax},'auto')
            str(j) = 'l';
        end
        if val(j)>0 && strcmp(yTickLabModes{ax},'auto')
            sciYAxis(ax) = -log10(str2double(yTickLabs{ax}(j))/val(j));
            if strcmp(str(j),'l')
                sciYAxis(ax) = 0;
            end
            sciYAxis = round(sciYAxis);
        end
    end
    loc = get(axesList(ax),'yaxislocation');
    set(axesList(ax),'yticklabel',[repmat(loc(1),length(val),1) str]);
end

% Export coded axes
set(objects,'visible','off');
set(axesList,'visible','on');
set(legends,'visible','off');
set(objects(find(invisible)),'visible','off'); %#ok<FNDSB>
set(H,'PaperPositionMode','manual','Renderer','painters', ...
    'InvertHardcopy','off');
print('-dmeta',['-f' num2str(H)]) %#ok<MCPRT>
pic = invoke(slide.Shapes,'PasteSpecial',3);

% Get figure size
metaWidth = get(pic,'Width');
metaHeight = get(pic,'Height');

% Ungroup objects
anygroup = 1;
while anygroup == 1
    try
        pic = invoke(pic,'Ungroup');
    catch %#ok<CTCH>
        anygroup = 0;
    end
end

% Retrieve code information
codeXY = repmat(' ',1,pic.Count);
codeLog = repmat(' ',1,pic.Count);
codeBox = repmat(' ',1,pic.Count);
for c = 1:pic.Count
    if strcmp(get(pic.Item(c),'HasTextFrame'),'msoTrue')
        txt = get(pic.Item(c).TextFrame.TextRange,'Text');
        if ~isempty(deblank(txt))
            codeXY(c) = txt(1);
            if length(txt)>1
                codeLog(c) = txt(2);
            else
                codeLog(c) = 'n';
            end
        else
            if strcmp(get(pic.Item(c),'Type'),'msoAutoShape')
                isFill = get(pic.Item(c).Fill,'Visible');
                codeBox(c) = isFill(4);
            end
        end
    end
end

% Delete coded axes
invoke(pic,'Delete');

% Return axes labels back to normal
for ax = 1:length(axesList)
    xlabel(axesList(ax),backupXLabel{ax});
    ylabel(axesList(ax),backupYLabel{ax});
    title(axesList(ax),backupTitle{ax});
    set(axesList(ax),'xticklabel',xTickLabs{ax});
    set(axesList(ax),'yticklabel',yTickLabs{ax});
end

txthands = {};
for obj = length(objects):-1:1
    type = get(objects(obj),'type');
    
    % Skip exporting if the object is axes (except legends)
    if strcmp(type,'axes') && isempty(find(legends==objects(obj),1))
        continue
    end

    
    % Check if the object is part of a group
    isPart = cellfun(@(x)~isempty(find(x==objects(obj),1)),prop.groups);
    f = find(isPart==1,1);
    if ~isempty(f) % Object is part of a group
        if exportedGroups(f)==1
            continue
        end
        exportedGroups(f) = 1;
        
        % Hide all other objects
        set(objects,'visible','off');
        set(prop.groups{f},'visible','on');
        set(objects(find(invisible)),'visible','off'); %#ok<FNDSB>
        
        % Set axis positions to original values
        for ax = 1:length(axesList)
            set(axesList(ax),'position',axesPos{ax});
        end
        
        % Export bitmap
        if ~isnan(prop.bitmapResolution(f))
            ax = bitmapAxis(f);
            units = get(ax,'units');
            set(ax,'units','inches');
            sz = get(ax,'position');
            set(ax,'units','normalized');
            pos = get(ax,'position');
            left = pos(1)*metaWidth;
            top = (1-pos(2)-pos(4))*metaHeight;
            width = pos(3)*metaWidth;
            height = pos(4)*metaHeight;
            set(ax,'position',[0 0 1 1]);
            unitsFig = get(H,'units');
            set(H,'units','inches');
            szFig = get(H,'position');
            set(H,'position',[szFig(1:2) sz(3:4)]);
            col = get(H,'color');
            axCol = backupColor{find(axesList==ax)}; %#ok<FNDSB>
            if ~strcmp(axCol,'none')
                set(H,'color',axCol);
            end
            set(H,'PaperPositionMode','auto','Renderer','painters', ...
                'InvertHardcopy','off')
            print('-dtiff','pptfig.tif',['-r' ...
                num2str(prop.bitmapResolution(f))],'-noui'); %#ok<MCPRT>
            set(H,'color',col);
            set(H,'position',szFig);
            set(H,'units',unitsFig);
            set(ax,'position',pos);
            pos = get(ax,'position'); %#ok<NASGU>
            set(ax,'units',units);
            img = invoke(slide.Shapes,'AddPicture',[pwd '\pptfig.tif'], ...
                'msoFalse','msoTrue',left,top,width,height);
            invoke(img,'ZOrder','msoSendToBack');
            continue
        end
        
        % Backup text properties
        grp = setdiff(prop.groups{f},objects(find(invisible))); %#ok<FNDSB>
        if isempty(grp)
            continue
        end
        if (length(unique(get(grp,'type')))==1 || length(grp)==1) && ...
                strcmp(get(grp(1),'type'),'text')
            backgroundColor = get(grp,'backgroundcolor');
            edgeColor = get(grp,'edgecolor');
            lineStyle = get(grp,'linestyle');
            lineWidth = get(grp,'lineWidth');
            txtMargin = get(grp,'margin');
            if length(grp)==1
                backgroundColor = {backgroundColor};
                edgeColor = {edgeColor};
                lineStyle = {lineStyle};
                lineWidth = {lineWidth};
                txtMargin = {txtMargin};
            end
            isUnique = 0;
            if length(unique(cellfun(@(x)num2str(x),backgroundColor, ...
                    'uniformoutput',false)))==1 && ...
                    length(unique(cellfun(@(x)num2str(x),edgeColor, ...
                    'uniformoutput',false)))==1 && ...
                    length(unique(lineStyle))==1 && ...
                    length(unique(cell2mat(lineWidth)))==1 && ...
                    length(unique(cell2mat(txtMargin)))==1
                set(grp,'backgroundcolor','none');
                set(grp,'edgecolor','none');
                set(grp,'linestyle','none');
                isUnique = 1;
            end
        end
        
        % Copy and paste the figure
        set(H,'PaperPositionMode','manual','Renderer','painters')
        print('-dmeta',['-f' num2str(H)], ...
            ['-r' num2str(prop.metaResolution)]) %#ok<MCPRT>
        grpType = get(grp,'type');
        if ~iscell(grpType)
            grpType = {grpType};
        end
        pic = invoke(slide.Shapes,'Paste');
        
        % Return text boxes back to normal
        if length(unique(grpType))==1 && ...
                strcmp(grpType{1},'text')
            for indx = 1:length(grp)
                set(grp(indx),'backgroundcolor',backgroundColor{indx});
                set(grp(indx),'edgecolor',edgeColor{indx});
                set(grp(indx),'linestyle',lineStyle{indx});
            end
        end
        
        % Set position
        set(pic,'Left',0,'Top',0,'Width',metaWidth,'Height',metaHeight);
        
        % Ungroup objects
        anygroup = 1;
        while anygroup == 1
            try
                pic = invoke(pic,'Ungroup');
            catch %#ok<CTCH>
                anygroup = 0;
            end
        end
        
        % Delete back panels
        invoke(pic.Item(1),'Delete');
        if ~strcmp(get(H,'color'),'none')
            invoke(pic.Item(2),'Delete');
        end
        
        % Bulk-change properties of grouped objects
        if length(unique(grpType))==1
            type = grpType{1};
            switch type
                case 'line'
                    lineObj = get(pic,'Line');
                    lineWidth = get(grp,'linewidth');
                    if ~iscell(lineWidth)
                        lineWidth = {lineWidth};
                    end
                    if length(unique(cell2mat(lineWidth)))==1
                        set(lineObj,'Weight',lineWidth{1});
                    end
                    lineStyle = get(grp,'linestyle');
                    if ~iscell(lineStyle)
                        lineStyle = {lineStyle};
                    end
                    if length(unique(lineStyle))==1
                        switch lineStyle{1}
                            case '-'
                                set(lineObj,'DashStyle','msoLineSolid');
                            case '--'
                                set(lineObj,'DashStyle','msoLineDash');
                            case '-.'
                                set(lineObj,'DashStyle','msoLineDashDot');
                            case ':'
                                set(lineObj,'DashStyle', ...
                                    'msoLineSquareDot');
                        end
                    end
                case 'text'
                    frame = get(pic,'TextFrame');
                    range = get(frame,'TextRange');
                    
                    % Align text
                    set(frame,'AutoSize','ppAutoSizeShapeToFitText');
                    
                    verticalAlignment = get(grp,'verticalalignment');
                    if ~iscell(verticalAlignment)
                        verticalAlignment = {verticalAlignment};
                    end
                    if length(unique(verticalAlignment))==1
                        switch verticalAlignment{1}
                            case {'top','cap'}
                                verticalCode = 'msoAnchorTop';
                            case 'middle'
                                verticalCode = 'msoAnchorMiddle';
                            case {'bottom','baseline'}
                                verticalCode = 'msoAnchorBottom';
                        end
                        set(frame,'VerticalAnchor',verticalCode);
                    end
                    
                    horizontalAlignment = get(grp,'horizontalalignment');
                    if ~iscell(horizontalAlignment)
                        horizontalAlignment = {horizontalAlignment};
                    end
                    if length(unique(horizontalAlignment))==1
                        horizontalCode = ['ppAlign' ...
                            horizontalAlignment{1}];
                        set(range.ParagraphFormat, ...
                            'Alignment',horizontalCode);
                    end
                    
                    if isUnique==1
                        backgroundColor = backgroundColor{1};
                        edgeColor = edgeColor{1};
                        lineStyle = lineStyle{1};
                        lineWidth = lineWidth{1};
                        txtMargin = txtMargin{1};
                        
                        set(frame,'MarginLeft',txtMargin, ...
                            'MarginRight',txtMargin, ...
                            'MarginTop',txtMargin, ...
                            'MarginBottom',txtMargin);
                        if ~strcmp(backgroundColor,'none')
                            if ischar(backgroundColor)
                                backgroundColor = ...
                                    str2num(backgroundColor); %#ok<ST2NM>
                            end
                            set(pic.Fill,'Visible','msoTrue');
                            set(pic.Fill.Forecolor,'RGB', ...
                                color2rgb(backgroundColor));
                        end
                        if ~strcmp(edgeColor,'none') && ...
                                ~strcmp(lineStyle,'none')
                            if ischar(edgeColor)
                                edgeColor = str2num(edgeColor); %#ok<ST2NM>
                            end
                            set(pic.Line,'Visible','msoTrue');
                            set(pic.Line.Forecolor, ...
                                'RGB',color2rgb(edgeColor));
                            set(pic.Line,'Weight',lineWidth);
                            switch lineStyle
                                case '-'
                                    pptLine = 'msoLineSolid';
                                case '--'
                                    pptLine = 'msoLineDash';
                                case ':'
                                    pptLine = 'msoLineRoundDot';
                                case '-.'
                                    pptLine = 'msoLineDashDot';
                            end
                            set(pic.Line,'DashStyle',pptLine);
                        end
                        
                    end
            end
        end
        
        % Group items
        try
            invoke(pic,'Group');
        catch %#ok<CTCH>
            % Not a group
        end
        
    else % Object is not part of a group
        
        % Hide all other objects
        set(objects,'visible','off');
        set(objects(obj),'visible','on');
        if ~isempty(find(legends==objects(obj),1))
            set(get(objects(obj),'children'),'visible','on');
        end
        set(objects(find(invisible)),'visible','off'); %#ok<FNDSB>
        
        % Set axis positions to original values
        for ax = 1:length(axesList)
            set(axesList(ax),'position',axesPos{ax});
        end
        
        % Get text information
        if strcmp(type,'text')
            horizontalAlignment = get(objects(obj),'horizontalalignment');
            verticalAlignment = get(objects(obj),'verticalalignment');
            backgroundColor = get(objects(obj),'backgroundcolor');
            edgeColor = get(objects(obj),'edgecolor');
            lineWidth = get(objects(obj),'linewidth');
            lineStyle = get(objects(obj),'linestyle');
            txtString = get(objects(obj),'string');
            txtMargin = get(objects(obj),'margin');
            
            % Disable TEX interpreter
            interpreter = get(objects(obj),'interpreter');
            set(objects(obj),'interpreter','none');
        end
        
        if ~(strcmp(type,'text') && isempty(deblank(txtString))) && ...
                isempty(find(legendObjects==objects(obj),1))            
            % Copy and paste the figure
            set(H,'PaperPositionMode','manual','Renderer','painters')
            print('-dmeta',['-f' num2str(H)], ...
                ['-r' num2str(prop.metaResolution)]) %#ok<MCPRT>
            pic = invoke(slide.Shapes,'Paste');
            
            % Set position
            set(pic,'Left',0,'Top',0, ...
                'Width',metaWidth,'Height',metaHeight);
            
            % Ungroup objects
            anygroup = 1;
            while anygroup == 1
                try
                    pic = invoke(pic,'Ungroup');
                catch %#ok<CTCH>
                    anygroup = 0;
                end
            end
            
            % Delete back panels
            invoke(pic.Item(1),'Delete');
            if ~strcmp(get(H,'color'),'none') || ...
                    ~isempty(find(legends==objects(obj),1))
                invoke(pic.Item(2),'Delete');
            end
            
            % Delete legend corner boxes and middle-anchor all text
            if ~isempty(find(legends==objects(obj),1))
                for c = 3:pic.Count
                    if strcmp(get(pic.Item(c),'Type'),'msoAutoShape')
                        if strcmp(get(pic.Item(c),'HasTextFrame'), ...
                                'msoTrue')
                            txt = get(pic.Item(c).TextFrame.TextRange, ...
                            'Text');
                            if isempty(deblank(txt))
                                invoke(pic.Item(c),'Delete');
                            else
                                legTop = get(pic.Item(c),'Top');
                                set(pic.Item(c).TextFrame, ...
                                    'VerticalAnchor','msoAnchorMiddle');
                                set(pic.Item(c),'Top',legTop);
                            end
                        end
                    end
                end
            end
            
            % Fix line properties
            if strcmp(type,'line') || ...
                    ~isempty(find(legends==objects(obj),1))
                try
                    lineObj = get(pic,'Line');
                    isLine = 1;
                catch %#ok<CTCH>
                    isLine = 0;
                end
                
                if isLine
                    set(lineObj,'Weight',get(objects(obj),'linewidth'));
                    for lineIndx = 3:pic.Count
                        try
                            lineObj = get(pic.Item(lineIndx),'Line');
                            switch get(lineObj,'DashStyle')
                                case 'msoLineSysDash'
                                    set(lineObj,'DashStyle', ...
                                        'msoLineDash');
                                case 'msoLineSysDot'
                                    set(lineObj,'DashStyle', ...
                                        'msoLineSquareDot');
                                case 'msoLineSysDashDot'
                                    set(lineObj,'DashStyle', ...
                                        'msoLineDashDot');
                            end
                        catch %#ok<CTCH>
                            % No line
                        end
                    end
                end
            end
            
            % Find object that contains the text
            ndx = 0;
            if strcmp(type,'text')
                for c = 3:pic.Count
                    if strcmp(get(pic.Item(c),'HasTextFrame'),'msoTrue')
                        str = get(pic.Item(c).TextFrame.TextRange,'Text');
                        if strcmp(str,txtString)
                            ndx = c;
                            txthands{end+1} = pic.Item(c); %#ok<AGROW>
                        else
                            invoke(pic.Item(c),'Delete');
                        end
                    else
                        invoke(pic.Item(c),'Delete');
                    end
                end
            end
            
            if ndx > 0
                frame = pic.Item(ndx).TextFrame;
                range = pic.Item(ndx).TextFrame.TextRange;
                
                % Align text
                if strcmp(type,'text')
                    horizontalCode = ['ppAlign' horizontalAlignment];
                    switch verticalAlignment
                        case {'top','cap'}
                            verticalCode = 'msoAnchorTop';
                        case 'middle'
                            verticalCode = 'msoAnchorMiddle';
                        case {'bottom','baseline'}
                            verticalCode = 'msoAnchorBottom';
                    end
                    set(frame,'AutoSize','ppAutoSizeShapeToFitText', ...
                        'VerticalAnchor',verticalCode);
                    set(range.ParagraphFormat,'Alignment',horizontalCode);
                end
                
                % Set text box colors
                if ~strcmp(backgroundColor,'none')
                    set(pic.Item(ndx).Fill,'Visible','msoTrue');
                    set(pic.Item(ndx).Fill.Forecolor,'RGB', ...
                        color2rgb(backgroundColor));
                end
                if ~strcmp(edgeColor,'none') && ~strcmp(lineStyle,'none')
                    set(pic.Item(ndx).Line,'Visible','msoTrue');
                    set(pic.Item(ndx).Line.Forecolor,'RGB', ...
                        color2rgb(edgeColor));
                    set(pic.Item(ndx).Line,'Weight',lineWidth);
                    switch lineStyle
                        case '-'
                            pptLine = 'msoLineSolid';
                        case '--'
                            pptLine = 'msoLineDash';
                        case ':'
                            pptLine = 'msoLineRoundDot';
                        case '-.'
                            pptLine = 'msoLineDashDot';
                    end
                    set(pic.Item(ndx).Line,'DashStyle',pptLine);
                end
                
                % Set text margin
                set(frame,'MarginLeft',txtMargin, ...
                    'MarginRight',txtMargin, ...
                    'MarginTop',txtMargin, ...
                    'MarginBottom',txtMargin);
                
                % Convert TEX characters to Unicode
                if strcmp(type,'text') && strcmp(interpreter,'tex')
                    % txtString
                    [str, ppt] = tex2ppt(txtString);
                    set(range,'Text',str);
                    for ch = 1:length(str)
                        sel = range.Characters(ch);
                        font = sel.Font;
                        fontName = get(font,'Name');
                        if ~isempty(ppt(ch).unicode)
                            invoke(sel,'InsertSymbol',fontName, ...
                                ppt(ch).unicode,1);
                        end
                        if ~isempty(ppt(ch).color)
                            set(font.Color,'RGB', ...
                                color2rgb(ppt(ch).color));
                        end
                        if ~isempty(ppt(ch).fontname)
                            set(font,'Name',ppt(ch).fontname);
                        end
                        if ~isempty(ppt(ch).fontsize)
                            scale = ppt(ch).fontsize / ...
                                get(objects(obj),'fontsize');
                            fontSize = get(font,'Size');
                            set(font,'Size',fontSize*scale);
                        end
                        if ppt(ch).bold == 1
                            set(font,'Bold','msoTrue');
                        end
                        if ppt(ch).italic == 1
                            set(font,'Italic','msoTrue');
                        end
                        if ~isempty(ppt(ch).offset)
                            totOff = length(ppt(ch).offset);
                            vals = 1-0.6.^(0:totOff);
                            vals = diff(vals);
                            vals = vals.*ppt(ch).offset;
                            bOff = sum(vals);
                            set(font,'BaselineOffset',bOff);
                        end
                    end
                end
            end
            
            % Group items
            if ~(strcmpi(type,'axes') && ...
                    isempty(find(legends==objects(obj),1))) && ...
                    ~strcmpi(type,'text') && ~strcmpi(type,'image') && ...
                    pic.Count > 3
                try
                    invoke(pic,'Group');
                catch %#ok<CTCH>
                    % Not a group
                end
            end
        end
        
        % Return TEX interpreter to normal
        if strcmp(type,'text')
            set(objects(obj),'interpreter',interpreter);
        end
    end
end


% Export real axes
shapeCount = slide.Shapes.Count;
deleted = [];
if ~isempty(setdiff(axesList,objects(find(invisible)))) %#ok<FNDSB>
    set(objects,'visible','off');
    set(axesList,'visible','on');
    set(legends,'visible','off');
    set(objects(find(invisible)),'visible','off'); %#ok<FNDSB>
    
    % Temporarily remove labels
    for ax = 1:length(axesList)
        xlabel(axesList(ax),'');
        ylabel(axesList(ax),'');
        title(axesList(ax),'');
    end
    
    % Set axis positions to original values
    for ax = 1:length(axesList)
        set(axesList(ax),'position',axesPos{ax});
    end
    
    set(H,'PaperPositionMode','manual','Renderer','painters')
    print('-dmeta',['-f' num2str(H)]) %#ok<MCPRT>
    pic = invoke(slide.Shapes,'PasteSpecial',3);
    
    % Return ticks and labels back to normal
    for ax = 1:length(axesList)
        set(axesList(ax),'xtickmode',xTickModes{ax});
        set(axesList(ax),'ytickmode',yTickModes{ax});
        set(axesList(ax),'xticklabelmode',xTickLabModes{ax});
        set(axesList(ax),'yticklabelmode',yTickLabModes{ax});
    end
    
    % Set position
    set(pic,'Left',0,'Top',0,'Width',metaWidth,'Height',metaHeight);
    
    % Ungroup objects
    anygroup = 1;
    while anygroup == 1
        try
            pic = invoke(pic,'Ungroup');
        catch %#ok<CTCH>
            anygroup = 0;
        end
    end
    
    % Return axes back to normal
    for ax = 1:length(axesList)
        xlabel(axesList(ax),backupXLabel{ax});
        ylabel(axesList(ax),backupYLabel{ax});
        title(axesList(ax),backupTitle{ax});
        set(axesList(ax),'color',backupColor{ax});
    end
    
    % Edit text alignment
    feature('COM_SafeArraySingleDim', 1); % for Matlab arrays in PowerPoint
    f = findstr(codeXY,'b')'; % Bottom
    if ~isempty(f)
        txtBoxes = invoke(slide.Shapes,'Range',int32(shapeCount+f));
        set(txtBoxes.TextFrame,'AutoSize','ppAutoSizeShapeToFitText', ...
            'VerticalAnchor','msoAnchorTop');
        set(txtBoxes.TextFrame.TextRange.ParagraphFormat,...
            'Alignment','ppAlignCenter');
    end
    f = findstr(codeXY,'t')'; % Top
    if ~isempty(f)
        txtBoxes = invoke(slide.Shapes,'Range',int32(shapeCount+f));
        set(txtBoxes.TextFrame,'AutoSize','ppAutoSizeShapeToFitText', ...
            'VerticalAnchor','msoAnchorBottom');
        set(txtBoxes.TextFrame.TextRange.ParagraphFormat,...
            'Alignment','ppAlignCenter');
    end
    f = findstr(codeXY,'l')'; % Left
    if ~isempty(f)
        txtBoxes = invoke(slide.Shapes,'Range',int32(shapeCount+f));
        set(txtBoxes.TextFrame,'AutoSize','ppAutoSizeShapeToFitText', ...
            'VerticalAnchor','msoAnchorMiddle');
        set(txtBoxes.TextFrame.TextRange.ParagraphFormat,...
            'Alignment','ppAlignRight');
    end
    f = findstr(codeXY,'r')'; % Right
    if ~isempty(f)
        txtBoxes = invoke(slide.Shapes,'Range',int32(shapeCount+f));
        set(txtBoxes.TextFrame,'AutoSize','ppAutoSizeShapeToFitText', ...
            'VerticalAnchor','msoAnchorMiddle');
        set(txtBoxes.TextFrame.TextRange.ParagraphFormat,...
            'Alignment','ppAlignLeft');
    end
    
    % Edit logarithmic axes
    f = findstr(codeLog,'l');
    for c = 1:length(f)
        obj = pic.Item(f(c)).TextFrame.TextRange;
        txt = get(obj,'Text');
        set(obj,'text',['10' txt]);
        for p = 1:length(txt)
            ch = get(obj.Characters(p+2));
            set(ch.Font,'BaselineOffset',0.6);
        end
    end
    
    % Send axis back panels to back
    f = findstr(codeBox,'T')';
    for c = 1:length(f)
        invoke(pic.Item(f(c)),'ZOrder','msoSendToBack');
    end
    deleted = findstr(codeBox,'F')';
    for c = 1:length(deleted)
        invoke(pic.Item(deleted(c)),'Delete');
    end
    
    % Delete back panels
    if strcmp(prop.backVisibility,'on') && ~strcmp(get(H,'color'),'none')
        set(pic.Item(2).Fill.ForeColor,'RGB',color2rgb(get(H,'color')));
        invoke(pic.Item(2),'ZOrder','msoSendToBack');
    elseif strcmp(prop.backVisibility,'auto') && ...
            ~strcmp(num2str(get(0,'defaultfigurecolor')), ...
            num2str(get(H,'color'))) && ...
            ~strcmp(get(H,'color'),'none')
        set(pic.Item(2).Fill.ForeColor,'RGB',color2rgb(get(H,'color')));
        invoke(pic.Item(2),'ZOrder','msoSendToBack');
    elseif ~strcmp(get(H,'color'),'none')
        invoke(pic.Item(2),'Delete');
        deleted(end+1) = 2;
    end
end

% Return objects back to normal
set(objects,'visible','on');
set(objects(find(invisible)),'visible','off'); %#ok<FNDSB>
for ax = 1:length(axesList)
    set(axesList(ax),'xlimmode',xLimModes{ax});
    set(axesList(ax),'ylimmode',yLimModes{ax});
end

% Add scientific notation boxes
for ax = 1:length(axesList)
    units = get(axesList(ax),'units');
    set(axesList(ax),'units','normalized');
    pos = get(axesList(ax),'position');
    fontUnits = get(axesList(ax),'fontunits');
    set(axesList(ax),'fontunits','pixels');
    
    % X-axis box
    if sciXAxis(ax)~=0 && invisible(find(objects==axesList(ax),1))==0
        x = metaWidth*(pos(1)+pos(3));
        y = metaHeight*(1-pos(2));
        txt = invoke(slide.Shapes,'AddTextbox', ...
            'msoTextOrientationHorizontal',0,0,0,0);
        str = ['×10' num2str(sciXAxis(ax))];
        set(txt.TextFrame.TextRange,'Text',str);
        set(txt.TextFrame.TextRange.Font.Color,'RGB', ...
            color2rgb(get(axesList(ax),'xcolor')));
        set(txt.TextFrame.TextRange.Font, ...
            'Size',get(axesList(ax),'FontSize'), ...
            'Name',get(axesList(ax),'FontName'));
        switch get(axesList(ax),'FontWeight')
            case {'demi','bold'}
                set(txt.TextFrame.TextRange.Font,'Bold','msoTrue');
            otherwise
                set(txt.TextFrame.TextRange.Font,'Bold','msoFalse');
        end
        switch get(axesList(ax),'FontAngle')
            case {'normal'}
                set(txt.TextFrame.TextRange.Font,'Italic','msoFalse');
            otherwise
                set(txt.TextFrame.TextRange.Font,'Italic','msoTrue');
        end
        for c = 4:length(str)
            ch = get(txt.TextFrame.TextRange.Characters(c));
            set(ch.Font,'BaselineOffset',0.6);
        end
        set(txt.TextFrame,'MarginLeft',0,'MarginRight',0,'MarginTop',0, ...
            'MarginBottom',0,'AutoSize','ppAutoSizeShapeToFitText', ...
            'WordWrap','msoFalse','VerticalAnchor','msoAnchorTop');
         set(txt.TextFrame.TextRange.ParagraphFormat, ...
             'Alignment','ppAlignRight');
         set(txt,'Left',x-get(txt,'Width'),'Top',y+1.5*get(txt,'Height'));
         
         txthands{end+1} = txt; %#ok<AGROW>
    end
    
    % Y-axis box
    if sciYAxis(ax)~=0 && invisible(find(objects==axesList(ax),1))==0
        x = metaWidth*pos(1);
        y = metaHeight*(1-pos(2)-pos(4));
        txt = invoke(slide.Shapes,'AddTextbox', ...
            'msoTextOrientationHorizontal',0,0,0,0);
        str = ['×10' num2str(sciYAxis(ax))];
        set(txt.TextFrame.TextRange,'Text',str);
        set(txt.TextFrame.TextRange.Font.Color,'RGB', ...
            color2rgb(get(axesList(ax),'ycolor')));
        set(txt.TextFrame.TextRange.Font, ...
            'Size',get(axesList(ax),'FontSize'), ...
            'Name',get(axesList(ax),'FontName'));
        switch get(axesList(ax),'FontWeight')
            case {'demi','bold'}
                set(txt.TextFrame.TextRange.Font,'Bold','msoTrue');
            otherwise
                set(txt.TextFrame.TextRange.Font,'Bold','msoFalse');
        end
        switch get(axesList(ax),'FontAngle')
            case {'normal'}
                set(txt.TextFrame.TextRange.Font,'Italic','msoFalse');
            otherwise
                set(txt.TextFrame.TextRange.Font,'Italic','msoTrue');
        end
        for c = 4:length(str)
            ch = get(txt.TextFrame.TextRange.Characters(c));
            set(ch.Font,'BaselineOffset',0.6);
        end
        set(txt.TextFrame,'MarginLeft',0,'MarginRight',0,'MarginTop',0, ...
            'MarginBottom',0,'AutoSize','ppAutoSizeShapeToFitText', ...
            'WordWrap','msoFalse','VerticalAnchor','msoAnchorBottom');
         set(txt.TextFrame.TextRange.ParagraphFormat, ...
             'Alignment','ppAlignLeft');
         set(txt,'Left',x,'Top',y-1.25*get(txt,'Height'));
         
         txthands{end+1} = txt; %#ok<AGROW>
    end
    
    set(axesList(ax),'units',units);
    set(axesList(ax),'fontunits',fontUnits);
end

% Group items
obj = invoke(slide.Shapes,'Range', ...
    int32((originalCount+1:get(slide.Shapes,'Count'))'));
try
    grp = invoke(obj,'Group');
catch %#ok<CTCH>
    grp = obj;
end

% Resize figure
if ~isempty(prop.width)
    set(grp,'Width',(prop.width*72/metaWidth)*get(grp,'Width'));
end
if ~isempty(prop.height)
    set(grp,'Height',(prop.height*72/metaHeight)*get(grp,'Height'));
end

% Ungroup
try
    grp = invoke(grp,'Ungroup');
catch %#ok<CTCH>
    % Not a group;
end

% Autosize text boxes
if ~isempty(deblank(codeXY))
    f = setdiff(1:length(codeXY),findstr(codeXY,' '))';
    for c = 1:length(f)
        f(c) = f(c)-length(find(deleted<f(c)));
    end
    try
        txtBoxes = invoke(slide.Shapes,'Range',int32(shapeCount+f));
        set(txtBoxes.TextFrame,'AutoSize','ppAutoSizeShapeToFitText');
    catch %#ok<CTCH>
        % Mismatch (e.g. occurs in polar plots)
    end
end
for c = 1:length(txthands)
    set(txthands{c}.TextFrame,'AutoSize','ppAutoSizeShapeToFitText');
end

% Group items
try
    grp = invoke(grp,'Group');
catch %#ok<CTCH>
    % Not a group
end

% Position figure
if ~isempty(objects)
    slide_h = op.PageSetup.SlideHeight;
    slide_w = op.PageSetup.SlideWidth;
    top = get(grp,'Top');
    left = get(grp,'Left');
    if ~isempty(prop.top)
        set(grp,'Top',prop.top*72+top);
    elseif ~isempty(prop.height)
        set(grp,'Top',(slide_h-prop.height*72)/2+top);
    else
        set(grp,'Top',(slide_h-metaHeight)/2+top);
    end
    if ~isempty(prop.left)
        set(grp,'Left',prop.left*72+left);
    elseif ~isempty(prop.width)
        set(grp,'Left',(slide_w-prop.width*72)/2+left);
    else
        set(grp,'Left',(slide_w-metaWidth)/2+left);
    end
end

% Return to current slide
if ~prop.switchSlide
    try
        invoke(op.Slides.Item(currSlide),'Select');
    catch %#ok<CTCH>
        % No slides
    end
end

% Return slide number
H = wind.Selection.SlideRange.SlideNumber;
if nargout > 0
    varargout{1} = H;
end

function img = get_ppt_image
% Image for the PowerPoint toolbar button

img(:,:,1) = [
    239 240 240 241 240 240 240 240 240 240 239 240 239 240 241 240
    238 232 231 230 235 235 239 240 240 241 240 243 240 241 239 240
    240 228 231 228 230 229 226 231 235 233 237 239 239 241 240 240
    240 237 229 231 230 230 229 229 230 228 230 230 231 237 237 241
    240 240 240 238 238 238 236 234 233 235 232 228 230 230 238 239
    240 239 234 228 230 233 237 239 240 241 239 234 228 230 234 240
    241 242 228 229 227 229 230 241 240 240 240 240 233 229 229 239
    240 237 232 230 228 231 229 237 240 241 240 239 235 230 231 237
    240 242 232 230 228 229 230 235 240 239 239 239 232 230 228 240
    239 240 236 230 229 229 226 235 237 235 228 229 229 230 238 239
    240 239 238 229 230 229 226 234 239 232 230 230 233 239 241 239
    240 241 240 229 230 230 229 229 238 239 240 243 240 240 240 239
    239 241 239 232 229 228 229 228 238 239 241 239 240 241 237 240
    239 240 241 234 229 228 229 231 237 239 242 240 240 239 239 241
    243 239 241 240 235 231 233 233 240 240 236 240 241 241 239 241
    240 240 239 239 240 239 236 240 241 241 239 240 240 240 238 241];

img(:,:,2) = [
    241 232 227 237 242 240 240 240 240 240 241 240 240 240 241 240
    228 161 139 154 176 197 217 230 239 241 240 239 239 239 239 240
    214 129 119 118 118 119 127 141 159 181 203 221 238 240 240 240
    236 188 147 136 127 122 119 117 118 120 120 128 153 204 238 241
    240 240 233 211 202 203 195 178 167 150 136 124 118 125 197 239
    242 238 182 133 133 161 223 239 240 237 232 199 133 118 149 232
    239 225 133 117 119 119 153 232 240 240 240 240 168 117 130 219
    240 230 138 118 118 118 124 212 240 241 240 241 183 118 127 211
    240 238 162 118 118 118 118 190 240 234 226 211 145 118 136 223
    241 240 187 119 117 117 118 166 222 149 133 125 119 122 184 239
    240 241 212 125 118 118 118 148 217 150 141 153 174 204 237 240
    240 240 229 140 117 118 119 130 222 236 231 238 240 240 240 239
    241 241 239 164 118 118 117 122 206 239 239 240 240 240 241 240
    241 240 239 195 121 117 117 127 214 240 240 240 240 240 240 240
    239 240 240 232 173 135 138 188 239 240 240 240 241 240 240 239
    240 240 239 240 239 225 229 239 239 239 241 240 238 240 239 239];

img(:,:,3) = [
    238 229 221 234 241 240 242 240 238 240 240 240 242 238 241 240
    219 109  76 102 136 174 203 221 237 243 240 236 237 240 241 240
    201  61  43  43  42  44  59  81 110 144 178 207 236 238 238 242
    235 156  89  72  60  49  42  43  44  47  45  62 104 185 240 241
    240 242 227 192 178 181 167 141 119  96  75  53  44  57 175 237
    239 236 145  67  65 111 212 237 238 236 226 171  65  42  94 229
    240 217  67  43  46  44 101 225 238 240 238 242 126  41  63 208
    240 224  74  44  41  42  56 192 242 241 240 240 146  44  54 196
    240 239 113  42  43  46  42 159 238 230 217 199  91  42  73 213
    238 240 155  40  41  41  43 124 215  92  69  52  42  50 150 237
    240 240 195  52  44  46  45  91 204  92  81  99 134 185 238 242
    242 238 223  80  41  44  44  63 209 231 226 235 242 242 238 241
    240 241 241 115  39  43  41  48 183 239 240 242 238 238 240 240
    240 240 240 166  46  45  43  56 198 244 241 240 238 242 242 238
    238 242 236 229 134  74  72 157 237 238 239 240 243 238 242 240
    242 238 237 242 237 214 221 237 240 240 238 240 241 238 241 240];
img = img/255;


function rgb = color2rgb(col)
% Converts Matlab 1x3 color vector to PowerPoint RGB number

col = round(col*255);
rgb = col(1)+256*col(2)+256^2*col(3);

function [str, ppt] = tex2ppt(str)
% Converts TEX string into a formatted PowerPoint box

emptyPPT.unicode = [];
emptyPPT.bold = [];
emptyPPT.italic = [];
emptyPPT.color = [];
emptyPPT.fontname = [];
emptyPPT.fontsize = [];
emptyPPT.offset = [];
ppt = repmat(emptyPPT,1,length(str));

% Substitute backslash character
backSlash = regexp(str,'\\\\');
for indx = length(backSlash):-1:1
    str(backSlash(indx)+1) = [];
    ppt(backSlash(indx)+1) = [];    
    str(backSlash(indx)) = '-';
    ppt(backSlash(indx)).unicode = 92;
end

% Convert special characters to Unicode
TEX = {'alpha','upsilon','sim','beta','phi','leq','gamma','chi', ...
    'infty','delta','psi','clubsuit','epsilon','omega','diamondsuit', ...
    'zeta','Gamma','heartsuit','eta','Delta','spadesuit','theta', ...
    'Theta','leftrightarrow','vartheta','Lambda','leftarrow','iota', ...
    'Xi','uparrow','kappa','Pi','rightarrow','lambda','Sigma', ...
    'downarrow','mu','Upsilon','circ','nu','Phi','pm','xi','Psi','geq', ...
    'pi','Omega','propto','rho','forall','partial','sigma','exists', ...
    'bullet','varsigma','ni','div','tau','cong','neq','equiv','approx', ...
    'aleph','Im','Re','wp','otimes','oplus','oslash','cap','cup', ...
    'supseteq','supset','subseteq','subset','int','in','o','rfloor', ...
    'lceil','nabla','lfloor','cdot','ldots','perp','neg','prime', ...
    'wedge','times','0','rceil','surd','mid','vee','varpi','copyright', ...
    'langle','rangle','^','_','{','}'};
code = [945 965 126 946 966 8804 947 967 8734 948 968 9827 603 969 9830 ...
    950 915 9829 951 916 9824 952 920 8596 977 923 8592 953 926 8593 ...
    954 928 8594 955 931 8595 181 978 186 957 934 177 958 936 8805 960 ...
    937 8733 961 8704 8706 963 8707 8226 962 8717 247 964 8773 8800 ...
    8801 8776 8501 8465 8476 8472 8855 8853 8709 8745 8746 8839 8835 ...
    8838 8834 8747 8712 959 8971 8968 8711 8970 183 8230 8869 172 180 ...
    8743 215 8709 8969 8730 124 8744 982 169 10216 10217 94 95 123 125];

for c = 1:length(TEX)
    [st en] = regexp(str,['\\' TEX{c}]);
    for indx = length(st):-1:1
        str(st(indx)+1:en(indx)) = [];
        ppt(st(indx)+1:en(indx)) = [];
        str(st(indx)) = '-';
        ppt(st(indx)).unicode = code(c);
    end
end

% Identify colors
[st en] = regexp(str,'\\color\{[^[\{\}]]*\}');
for indx = length(st):-1:1
    ppt(st(indx)).color = str(st(indx)+7:en(indx)-1);
    str(st(indx)+1:en(indx)) = [];
    ppt(st(indx)+1:en(indx)) = [];
end

% Identify RGB colors
[st en] = regexp(str,'\\color\[rgb\]\{[^[\{\}\[\]]]*\}');
for indx = length(st):-1:1
    ppt(st(indx)).color = str(st(indx)+12:en(indx)-1);
    str(st(indx)+1:en(indx)) = [];
    ppt(st(indx)+1:en(indx)) = [];
end

% Fix colors
for c = 1:length(ppt)
    if isempty(ppt(c).color)
        continue
    end
    val = str2num(ppt(c).color); %#ok<ST2NM>
    if ~isempty(val)
        ppt(c).color = val;
    else
        switch ppt(c).color
            case 'black'
                col = [0 0 0];
            case 'red'
                col = [1 0 0];
            case 'green'
                col = [0 1 0];
            case 'blue'
                col = [0 0 1];
            case 'yellow'
                col = [1 1 0];
            case 'magenta'
                col = [1 0 1];
            case 'cyan'
                col = [0 1 1];
            case 'white'
                col = [1 1 1];
        end
        ppt(c).color = col;
    end
end

% Identify font names
[st en] = regexp(str,'\\fontname\{[^[\{\}\[\]]]*\}');
for indx = length(st):-1:1
    ppt(st(indx)).fontname = str(st(indx)+10:en(indx)-1);
    str(st(indx)+1:en(indx)) = [];
    ppt(st(indx)+1:en(indx)) = [];
end

% Identify font sizes
[st en] = regexp(str,'\\fontsize\{[^[\{\}\[\]]]*\}');
for indx = length(st):-1:1
    ppt(st(indx)).fontsize = str2double(str(st(indx)+10:en(indx)-1));
    str(st(indx)+1:en(indx)) = [];
    ppt(st(indx)+1:en(indx)) = [];
end

% Identify bold formatting
st = strfind(str,'\bf');
for indx = length(st):-1:1
    str(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)).bold = 1;
end

% Identify italic formatting
st = strfind(str,'\it');
for indx = length(st):-1:1
    str(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)).italic = 1;
end
st = strfind(str,'\sl');
for indx = length(st):-1:1
    str(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)).italic = 1;
end

% Identify normal formatting
st = strfind(str,'\rm');
for indx = length(st):-1:1
    str(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)+1:st(indx)+2) = [];
    ppt(st(indx)).bold = 0;
    ppt(st(indx)).italic = 0;
end

% Encode subscript and superscript symbols
f = strfind(str,'^');
for c = length(f):-1:1
    if strcmp(str(f(c)+1),'{')
        str(f(c):f(c)+1) = '{\';
    else
        str = [str(1:f(c)-1) '{\' str(f(c)+1) '}' str(f(c)+2:end)];
        ppt = [ppt(1:f(c)-1) emptyPPT ppt(f(c):f(c)+1) ...
            emptyPPT ppt(f(c)+2:end)];
    end
    ppt(f(c)+1).offset = 1;
end
f = strfind(str,'_');
for c = length(f):-1:1
    if strcmp(str(f(c)+1),'{')
        str(f(c):f(c)+1) = '{\';
    else
        str = [str(1:f(c)-1) '{\' str(f(c)+1) '}' str(f(c)+2:end)];
        ppt = [ppt(1:f(c)-1) emptyPPT ppt(f(c):f(c)+1) ...
            emptyPPT ppt(f(c)+2:end)];
    end
    ppt(f(c)+1).offset = -1;
end

% Apply TEX formatting
[str, ppt, ~] = apply_tex_format(str, ppt, emptyPPT);


function [str, ppt, emptyPPT] = apply_tex_format(str, ppt, emptyPPT)

f = strfind(str,'{');
while ~isempty(f)
    f = f(1);
    % Find matching brace
    isBrace = zeros(size(str));
    isBrace(strfind(str,'{')) = 1;
    isBrace(strfind(str,'}')) = -1;
    level = cumsum(isBrace);
    level(1:f-1) = inf;
    match = find(level==0,1);
    [strN, pptN, emptyPPT] = apply_tex_format(str(f+1:match-1), ...
        ppt(f+1:match-1),emptyPPT);
    str = [str(1:f-1) strN str(match+1:end)];
    ppt = [ppt(1:f-1) pptN ppt(match+1:end)];
    f = strfind(str,'{');
end

% No more braces
currForm = emptyPPT;
for c = 1:length(str)
    if strcmp(str(c),filesep)
        if ~isempty(ppt(c).color)
            currForm.color = ppt(c).color;
        end
        if ~isempty(ppt(c).fontname)
            currForm.fontname = ppt(c).fontname;
        end
        if ~isempty(ppt(c).fontsize)
            currForm.fontsize = ppt(c).fontsize;
        end
        if ~isempty(ppt(c).bold)
            currForm.bold = ppt(c).bold;
        end
        if ~isempty(ppt(c).italic)
            currForm.italic = ppt(c).italic;
        end
        if ~isempty(ppt(c).offset)
            currForm.offset = ppt(c).offset;
        end
    else
        if isempty(ppt(c).color)
            ppt(c).color = currForm.color;
        end
        if isempty(ppt(c).fontname)
            ppt(c).fontname = currForm.fontname;
        end
        if isempty(ppt(c).fontsize)
            ppt(c).fontsize = currForm.fontsize;
        end
        if isempty(ppt(c).bold)
            ppt(c).bold = currForm.bold;
        end
        if isempty(ppt(c).italic)
            ppt(c).italic = currForm.italic;
        end
        ppt(c).offset = [currForm.offset ppt(c).offset];
    end
end

% Remove backslashes
f = strfind(str,filesep);
str(f) = [];
ppt(f) = [];