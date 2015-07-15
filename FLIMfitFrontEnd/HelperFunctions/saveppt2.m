Copyright (c) 2009, Jedediah Frey
Copyright (c) 2010, Jedediah Frey
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


% SAVEPPT2 saves plots to PowerPoint.
% SAVEPPT2(save_file,<additional parameters>)
%  Saves the current Matlab figure window or Simulink model window to a PowerPoint
%  file designated by save_file.  If save_file is omitted, the user is prompted to enter
%  one via UIPUTFILE.  If the path is omitted from filespec, the
%  PowerPoint file is created in the current Matlab working directory.
%
% powerpoint_object=SAVEPPT2(save_file,'close',false);
%   Return the PowerPoint presentation object if it isn't to be closed.
%
% Batch Processing:
% powerpoint_object=SAVEPPT2(save_file,'init')
%   Initializes a powerpoint object for use with batch processing.
% SAVEPPT2('ppt',powerpoint_object);
%   Saves the current Matlab figure to the opened PowerPoint Object
% SAVEPPT2(save_file,'ppt',powerpoint_object,'close');
%   Saves and closes the PowerPoint object.
%
% SAVEPPT2 also accepts numerous additional optional parameters, they can
% be called from the matlab command line or in function form. All options
% can be preceded with a '-', but this is not required. Short and Long
% named options are listed on the same line.
%
% % Annotation:
% 'n' 'notes'          - Add information to notes section.
% 'text' 'textbox'     - Add text box.
% 'comment' 'comments' - Add comment. (Only works if PowerPoint is visible)
%     - \t and \n are converted to tab and new line, respectively.
% 't' 'title' - Add a title or add a blank title so that one may be added later. Title is placed at the top of the presentation unless a padding is specified.
% If 'title' or 'textbox' is specified alone a blank placeholder will be added.
%
% % Figure Options
% 'f' 'fig' 'figure'     - Use the specified figure handle. Also accepts an array of figures. More than 4 figures is not recommended as it makes it difficult to see in the plot. Default: gcf
%                          If figure is 0, a blank page is added. If a title is specified then a title page is added.
% 'd' 'driver' 'drivers' - [meta, bitmap]. Send figure to clipboard Metafile or Bitmap format. See also print help.
% 'r' 'render'           - [painters,zbuffer,opengl]. Choose print render mode. See also print help.
% 'res' 'resolution'     - Dots-per-inch resolution. Default: 90 for Simulink, 150 for figures. See also print help.
%
% % Slide Layout
% 'st' 'stretch'      - Used only with scale, stretch the figure to fill all remaining space (taking into account padding and title). Default: on
% 's' 'sc' 'scale'    - Scale the figure to remaining space on the page while maintaining aspect ratio, takes into account padding and title spacing. Default: on
% 'h' 'halign'        - ['left','center','right']. Horizontally align figure. Default: center
% 'v' 'valign'        - ['top','center','bottom']. Vertically align the graph. Default: center
% 'p' 'pad' 'padding' - Place a padding around the figure that is used for alignment and scaling. Can be one number to be applied equally or an array in the format of [left right top bottom]. Useful when plotting to template files. Default: 0
% 'c' 'col' 'columns' - Number of columns to place multiple plots in. Default: 2
%
% % PowerPoint Control
% 'i' 'init' - Initialize PowerPoint presentation for use in batch mode. Returns a PowerPoint Presentation Object.
% 'close'    - Close PowerPoint presentation. Default: true
% 'save'     - Save PowerPoint Presentation. Useful for saves in batch mode.
% 'ppt'      - Call saveppt2 with specified PowerPoint Presentation object.
% 'visible'  - Make PowerPoint visible.
% 'template' - Use template file specified. Is only used if the save file does not already exist.
%
% For binary options use: 'yes','on' ,'true' ,true  to enable
%                         'no', 'off','false',false to disable
% Examples:
% % Simplest Call
% plot(rand(1,100),rand(1,100),'*');
% saveppt2
%
% % Add a title "Hello World"
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','title','Hello World');
% saveppt2('test.ppt','t','Hello World');
% saveppt2 test.ppt -title 'Hello World'
% saveppt2 test.ppt -t 'Hello World'
%
% % Add a note
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','notes','Lorem ipsum dolor sit amet, consectetur adipiscing elit.');
%
% % Add multiline note
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','notes','Lifetime, relational competence.\n\tTactical, integrated solution');
% note=sprintf('Latest Quarter Sales: %%fM',rand(1,1)*100);
% saveppt2('test.ppt','notes',note);
%
% Add a TextBox
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','texbox','Totally, groupwide mindset');
%
% % Add a comment (PowerPoint must be visible)
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','visible','comment','Virtual, logic-based culture');
%
% % Scaling & Stretching the plot to fill the page.
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','note','Scaling & Stretching On (Default)');
% saveppt2('test.ppt','stretch','false','Stretching Off');
% saveppt2('test.ppt','scale',off,'note','Scaling Off');
%
% % Stretching the plot to fill the page.
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','Stretching On');
%
% saveppt2('test.ppt','stretch',false);
% saveppt2 test.ppt -stretch off
%
% % copy the plot as both a meta and bitmap.
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','driver','meta','scale','stretch');
% saveppt2('test.ppt','driver','bitmap','scale','stretch');
%
% % scale the plot to fill the page, ignoring aspect ratio, with 150 pixels
% % of padding on all sides
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','scale','stretch','Padding',150);
% saveppt2('test.ppt','scale',true,'stretch',true,'Padding',150);
%
% % scale the plot to fill the page, ignoring aspect ratio, with 150 pixels
% % of padding on left and right sides
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','scale','stretch','Padding',[150 150 0 0]);
% saveppt2('test.ppt','scale',true,'stretch',true,'Padding',[150 150 0 0]);
%
% % scale the plot to fill the page, ignoring aspect ratio add blank title
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','scale','stretch','title');
% saveppt2('test.ppt','scale',true,'stretch',true,'title',true);
%
% % Align the figure in the upper left corner
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','halign','left','valign','top');
%
% % Align the figure in the upper left corner
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','halign','right','valign','bottom');
%
% % Use the template 'Group Report.ppt'
% plot(rand(1,100),rand(1,100),'*');
% saveppt2('test.ppt','template','Group Report.ppt');
%
% % Plot 4 figures horizontally aligned left with 2 columns
% a=figure('Visible','off');plot(1:10);
% b=figure('Visible','off');plot([1:10].^2);
% c=figure('Visible','off');plot([1:10].^3);
% d=figure('Visible','off');plot([1:10].^4);
% saveppt2('test.ppt','figure',[a b c d],'columns',2,'title','Hello World!','halign','left')
%
% % Create blank title page.
% figure('test.ppt','figure',0,'title','New Section');
%
% % Create blank page.
% figure('test.ppt','figure',0);
%
% % Plot figures in batch mode. Faster than opening a new powerpoint object each time
% ppt=saveppt2('batch.ppt','init');
% for i=1:10
%     plot(rand(1,100),rand(1,100),'*');
%     saveppt2('ppt',ppt)
%     if mod(i,5)==0 % Save half way through incase of crash
%       saveppt2('ppt',ppt,'save')
%     end
% end
% saveppt2('batch.ppt','ppt',ppt,'close');
%
% More flexibility is built in, but it is impossible to show all possible
% calling combinations, you may check out the source or Test_SavePPT2.m
%
% See also print, saveppt, validateInput

% Ver 2.2, Copyright 2005, Mark W. Brown, mwbrown@ieee.org
%  changed slide type to include title.
%  added input parameter for title text.
%  added support for int32 and single data types for Matlab 6.0
%  added comments about changing bitmap resolution (for large images only)
%  swapped order of opening PPT and copying to clipboard (thanks to David Abraham)
%  made PPT invisible during save operations (thanks to Noah Siegel)
%
% Ver 3.5, Copyright 2010, Jed Frey, frey_jed@cat.com
%  Added template & notes features
%  Added multiple calling functions
%  Restructured calling sequence

function varargout=saveppt2(varargin)
%% Establish valid save file name:
if nargin<1
    [fname, fpath] = uiputfile('*.ppt');
    if fpath == 0; return; end
    filespec = fullfile(fpath,fname);
elseif strcmp(varargin{1},'ppt')
    % If the first input is the Powerpoint COM object
else
    % Otherwise the first input is the desired filename.
    filespec=varargin{1};
    varargin(1)='';
    % If the path is empty, use current working directory. If the extension
    % is blank, add .ppt then create full windows path.
    [fpath,fname,fext] = fileparts(filespec);
    if isempty(fpath); fpath = pwd; end
    if isempty(fext); fext = '.ppt'; end
    filespec = fullfile(fpath,[fname,fext]);
end

%% Process additional parameters
if numel(varargin)>0
    % Set up valid parameters list
    validParameters={ ...
        {'figure','fig','f'}, ... % Figure & driver settings
        {'init','i'},'close','save','ppt','visible','template', ... % Power Point Control.
        {'notes','n'},{'text','textbox'}, {'comments','comment'}, ... % Notes, textbox & comments settings
        {'stretch','st'},{'scale','s','sc'},{'title','t'}, ... % Stretch, Scale & Title settings
        {'driver','drivers','d'},{'resolution','res'},{'render','r'},... % Title, Resolution and Render Calls
        {'halign','h'},{'valign','v'},{'padding','pad','p'},{'columns','col','c'}}; % Align, padding and column calls.
    % Validate additional input
    addlParms=validateInput(varargin,validParameters);
else
    % Just make addlParms an empty struct so that 'isfield' doesn't error
    % out.
    addlParms=struct;
end

%% Parameter Sanity Checks

% PowerPoint File & Init cannot both be specified at the same time.
if isfield(addlParms,'init')&&isfield(addlParms,'ppt')
    error('Both init and ppt can not be specified at the same time. Call init first, then use ppt');
end
% PowerPoint Close & Init cannot both be specified at the same time
if isfield(addlParms,'init')&&isfield(addlParms,'close')
    warning('saveppt2:InitQuit','Both init and quit should not be specified at the same time, ignoring close.');
    addlParms=rmfield(addlParms,'close');
end
% If close is specified, force to save the powerpoint.
if isfield(addlParms,'close')
    addlParms.save=true;
end
%% Initialize PowerPoint
% If the user has passed a previous PowerPoint session:
if isfield(addlParms,'ppt')
    % Validate that the PPT object passed is actually a PPT object
    % Try 10 times to get parameters from the ppt object, waiting on
    % ActiveX to catch up.
    op=-1;
    for i=1:10
        try
            % Make sure it's a valid object.
            addlParms.ppt.ReadOnly;
            op=addlParms.ppt;
            break;
        catch
            pause(2);
        end
    end
    if op==-1
        error('Failed invoking object. Verify that it is a PPT object as returned from a saveppt2(file,''init'') function.');
    end
    % Otherwise assign it to the 'open presentation' variable and get the
    % powerpoint application object.
    ppt=op.Application;
    % If save or close is set
    if checkParm(addlParms,'save')
        % Save the file
        if ~exist(filespec,'file')
            % Save file as new if the file doesn't exist:
            invoke(op,'SaveAs',filespec,1);
        else
            % Save existing file:
            invoke(op,'Save');
        end
        % If close is specified, close the powerpoint.
        if checkParm(addlParms,'close')
            invoke(op,'Close');
            % If there are no more open powerpoint presentations, quit the
            % application
            if ppt.Presentations.Count==0
                invoke(ppt,'Quit');
            end
        end
        return;
    end
else
    % If a powerpoint object isn't passed, open one.
    ppt=-1;
    % Try 10 times to open powerpoint ActiveX with a 2 second pause in between.
    % Sometimes the OS and ActiveX controls take a few seconds to
    % 'catch up'
    for i=1:10
        try
            ppt = actxserver('PowerPoint.Application');
            ppt.visible;
            break;
        catch
            pause(2);
        end
    end
    if ppt==-1
        error('Error opening PowerPoint');
    end
    % Check if the savefile exists.
    if exist(filespec,'file')
        % If the save file already exists, the template cannot be applied.
        if isfield(addlParms,'template')
            addlParms=rmfield(addlParms,'template');
            warning('saveppt2:fileexist','Save file exists, skipping opening template');
        end
        % Try 10 times to open the file with a 2 second pause in between.
        % Sometimes the OS and ActiveX controls take a few seconds to
        % 'catch up'
        op=-1;
        for i=1:10
            try
                op = invoke(ppt.Presentations,'Open',filespec,[],[],0);
                break;
            catch
                pause(2);
            end
        end
        if op==-1
            error('Error opening file: %s',filespec);
        end
    else
        % If a template is specified
        if isfield(addlParms,'template')
            % Check that the file exists
            if ~exist(addlParms.template,'file');
                warning('saveppt2:notemplate','Template file does not exist, skipping.');
                op = invoke(ppt.Presentations,'Add');
            else
                % Open the template file
                op = invoke(ppt.Presentations,'Open',addlParms.template,[],[],0);
            end
        else
            op = invoke(ppt.Presentations,'Add');
        end
    end
    % If saveppt2 was just called to init the plots, return the PowerPoint
    % presentation object.
    if isfield(addlParms,'init')&&addlParms.init
        varargout{1}=op;
        return;
    end
end

% Set Visibility.
if checkParm(addlParms,'visible')
    ppt.visible=1;
end
%% Additional Parameter Sanity Checks
% Validate that halign is a valid setting
if isfield(addlParms,'halign')&&~any(strcmpi(addlParms.halign,{'left','center','right'}))
    warning('saveppt2:InvalidHalign','Invalid horizontal align "%s" specified, ignoring',addlParms.halign);
    addlParms=rmfield(addlParms,'halign');
end
% Validate that valign is a valid setting
if isfield(addlParms,'valign')&&~any(strcmpi(addlParms.valign,{'top','center','bottom'}))
    warning('saveppt2:InvalidValign','Invalid vertical align "%s" specified, ignoring',addlParms.valign);
    addlParms=rmfield(addlParms,'valign');
end
% If there is more than 1 figure, scale must be enabled so that all of the
% figures will fit on a slide.
if isfield(addlParms,'figure')&&length(addlParms.figure)>1
    if isfield(addlParms,'scale')&&addlParms.scale==false
        warning('saveppt2:ScaleForced','More than one figure given, scaling forced to enable so that the plots will fit');
    end
    addlParms.scale=true;
end
% Stretch only makes sense when used with scale. Ignore otherwise
if ~checkParm(addlParms,'scale')&&checkParm(addlParms,'stretch')
    warning('saveppt2:ScaleForcedStretch','Stretch is enabled, scaling forced to enabled.');
    addlParms.scale=true;
end
% Comments only works when the PowerPoint is visible.
if ~checkParm(addlParms,'visible')&&checkParm(addlParms,'comments')
    error('Visibility must be enabled to use comments.');
end
% Validate padding input
if isfield(addlParms,'padding')
    % Make sure that padding is a number
    if ~isnumeric(addlParms.padding)
        addlParms=rmfield(addlParms,'padding');
        warning('saveppt2:IncorrectPadding','Padding non-numeric. Must be [l, r, t, b] or a single number, ignoring.')
        % Validate padding size
    elseif ~any(size(addlParms.padding,2)==[1 4])
        addlParms=rmfield(addlParms,'padding');
        warning('saveppt2:IncorrectPaddingSize','Incorrect Padding Size. Must be [l, r, t, b] or a single number, ignoring.')
        % If padding is just one number, fill in so that all of the numbers are
        % the same
    elseif size(addlParms.padding,2)==1
        addlParms.padding=repmat(addlParms.padding,1,4);
    end
end

%% Set up defaults
% If no text for title is specified, set it to blank
if checkParm(addlParms,'title');
    addlParms.title='';
end
% If no text for textbox is specified, set it to blank
if checkParm(addlParms,'text');
    addlParms.text='';
end
% If no text for comment is specified, set it to blank
if checkParm(addlParms,'comments');
    addlParms.comments='';
end
% If no note is specified, clear it and give a warning
if checkParm(addlParms,'notes');
    warning('saveppt2:NoNoteGiven','No note was specified');
    addlParms=rmfield(addlParms,'notes');
end
% Stretch was not specified
if ~isfield(addlParms,'stretch');
    addlParms.stretch=true;
end
% Scale was not specified
if ~isfield(addlParms,'scale');
    addlParms.scale=true;
end
% Comments only work when the PowerPoint slide is visible.
if ~checkParm(addlParms,'visible')&&isfield(addlParms,'comments')
    warning('saveppt2:VisibleComments','Comments are only available if PowerPoint is visible. Removing');
    addlParms=rmfield(addlParms,'comments');
end
% Default the number of columns to 2
if ~isfield(addlParms,'columns')||checkParm(addlParms,'columns')
    addlParms.columns=2;
end
% If no close is specified, default to close the fields.
if ~isfield(addlParms,'close')&&~isfield(addlParms,'ppt')
    addlParms.close=true;
end
%% Configure Print Options
% Validate all of the figures
if isfield(addlParms,'figure')
    % Meaning they just put 'Figure', but didn't specify one, default
    % behavior for print, just remove the field
    if checkParm(addlParms,'figure')
        addlParms=rmfield(addlParms,'figure');
    else
        % More than 4 figures makes it hard to read
        if length(addlParms.figure)>4
            warning('saveppt2:TooManyFigures','More than 4 figures is not reccomended')
        end
    end
    % Check that the figures actually exist
    for i=1:length(addlParms.figure)
        try
            a=get(addlParms.figure(i));
        catch
            error('saveppt2:FigureDoesNotExist',['Figure ' addlParms.figure(i) ' does not exist']);
        end
    end
else
    % If no figure is specified, use the current figure.
    addlParms.figure=gcf;
end
% Resolution options
if isfield(addlParms,'resolution')
    resOpt=['-r ' num2str(addlParms.resolution)];
else
    resOpt='';
end
% Driver options
if isfield(addlParms,'driver')
    if strmatch(addlParms.driver(1),'d')
        addlParms.driver(1)='';
    end
    switch lower(addlParms.driver)
        case 'meta'
            addlParms.driver='-dmeta';
        case 'bitmap'
            addlParms.driver='-dbitmap';
        otherwise
            warning('saveppt2:UnknownDriver','Unknown Print Driver: %s. Using meta.',addlParms.driver);
            addlParms.driver='-dmeta';
    end
else
    addlParms.driver='-dmeta';
end
% Render schema options
if isfield(addlParms,'render')
    switch lower(addlParms.render)
        case 'painters'
            rendOpt='-painters';
        case 'zbuffer'
            rendOpt='-zbuffer';
        case 'opengl'
            rendOpt='-opengl';
        case 'render'
            rendOpt='';
        otherwise
            warning('saveppt2:UnknownRenderer','Unknown Renderer: %s',addlParms.render);
            addlParms=rmfield(addlParms,'render');
    end
else
    rendOpt='';
end

%% Slide functions
% Get height and width of slide:
slide_H = op.PageSetup.SlideHeight;
slide_W = op.PageSetup.SlideWidth;
% Get current number of slides:
slide_count = get(op.Slides,'Count');
% Add a new slide (with title object):
slide_count = int32(double(slide_count)+1);
% Create the appropriate slide (w or w/o title)
if isfield(addlParms,'title')
    % Slide with Title
    if addlParms.figure(1)==0 % Title slide only.
        new_slide = invoke(op.Slides,'Add',slide_count,1);
    else % Title slide with plots.
        new_slide = invoke(op.Slides,'Add',slide_count,11);
        % Set the text frame to autosize
        new_slide.Shapes.Title.TextFrame.AutoSize=1;
        % If padding is specified, use that.
        if isfield(addlParms,'padding')
            set(new_slide.Shapes.Title,'Top',addlParms.padding(3));
        else
            % Otherwise move the title up towards the top of the scope
            set(new_slide.Shapes.Title,'Top',get(new_slide.Shapes.Title.TextFrame.TextRange.Font,'Size')/4);
        end
        % Resize the title so that it is the width of the slide
        set(new_slide.Shapes.Title,'Left',0);
        set(new_slide.Shapes.Title,'Width',slide_W);
        % Set the 'top' of where the bottom of the title is.
        top=get(new_slide.Shapes.Title,'Top')+get(new_slide.Shapes.Title,'Height');
    end
    % Set the text in the title to the specified title
    set(new_slide.Shapes.Title.TextFrame.TextRange,'Text',addlParms.title);
else
    % Slide with No Title
    new_slide = invoke(op.Slides,'Add',slide_count,12);
    if isfield(addlParms,'padding')
        top=addlParms.padding(3);
    else
        top=0;
    end
end
% If padding is given, use that (top is specified above)
if isfield(addlParms,'padding')
    left=addlParms.padding(1);
    right=addlParms.padding(2);
    bottom=addlParms.padding(4);
else
    bottom=0;
    left=0;
    right=0;
end
%% Figure Functions
% Calculate the number of rows and columns
fig.count=length(addlParms.figure);
fig.rows=(floor((fig.count-1)/addlParms.columns))+1;
fig.columns=min(fig.count,addlParms.columns);
% For each figure
for i=1:fig.count
    % For title page only, skip.
    if addlParms.figure(i)==0
        continue;
    end
    % Determine what row and column the current figure is on
    row=floor((i-1)/addlParms.columns);
    column=mod(i-1,addlParms.columns);
    % Copy the figure to the clipboard
    %print(addlParms.driver,['-f' num2str(addlParms.figure(i))],rendOpt,resOpt);
    print(addlParms.driver,addlParms.figure(i),rendOpt,resOpt);
    % Paste the contents of the Clipboard:
    %pic1 = invoke(new_slide.Shapes,'Paste');
    picShapeRange = invoke(new_slide.Shapes,'Paste'); 
    pic1 = invoke(picShapeRange,'Item',1);
    % Get height and width of picture:
    pic_H = get(pic1,'Height');
    pic_W = get(pic1,'Width');
    % If scale is specified:
    if checkParm(addlParms,'scale')
        % If stretch is specified, scretch the figure to it's 'box' (full
        % page if there is only 1)
        if checkParm(addlParms,'stretch')
            set(pic1,'LockAspectRatio','msoFalse')
            set(pic1,'Width',(slide_W-(left+right))/fig.columns);
            set(pic1,'Height',(slide_H-(top+bottom))/fig.rows);
        else
            % Determine if the height or the width will be the constraint,
            % then set the picture height or width accordingly
            if ((slide_H)/fig.rows)/((slide_W)/fig.columns)>(pic_H+(top+bottom))/(pic_W+(left+right))
                set(pic1,'Width',(slide_W-(left+right))/fig.columns);
            else
                set(pic1,'Height',(slide_H-(top+bottom))/fig.rows);
            end
        end
    end
    % Get the figure height and widths
    fig.width=get(pic1,'Width');
    fig.height=get(pic1,'Height');
    % Do a vertical alignment based on input
    if isfield(addlParms,'valign')
        if strcmpi(addlParms.valign,'center')
            set(pic1,'Top',top+0.5*(slide_H-(fig.height*fig.rows+top+bottom))+fig.height*row);
        elseif strcmpi(addlParms.valign,'top')
            set(pic1,'Top',top+fig.height*row);
        elseif strcmpi(addlParms.valign,'bottom')
            set(pic1,'Top',slide_H-(fig.height*fig.rows+bottom)+fig.height*row);
        end
    else
        % Or default to center
        set(pic1,'Top',top+0.5*(slide_H-(fig.height*fig.rows+top+bottom))+fig.height*row);
    end
    % Do a horizontal alignment based on input
    if isfield(addlParms,'halign')
        if strcmpi(addlParms.halign,'center')
            set(pic1,'Left',left+0.5*(slide_W-(fig.width*min(fig.count-fig.columns*row,fig.columns)+left+right))+fig.width*column);
        elseif strcmpi(addlParms.halign,'left')
            set(pic1,'Left',left+fig.width*column);
        elseif strcmpi(addlParms.halign,'right')
            set(pic1,'Left',slide_W-(fig.width*min(fig.count-fig.columns*row,fig.columns)+left+right)+fig.width*column);
        end
    else
        % Or default
        set(pic1,'Left',left+0.5*(slide_W-(fig.width*min(fig.count-fig.columns*row,fig.columns)+left+right))+fig.width*column);
    end
end
% Clean up notes & text box strings.
text={'notes','text','comments'};
for i=1:numel(text)
    % If the notes are a number, convert it to text
    if isfield(addlParms,text{i})
        if isnumeric(addlParms.(text{i}))
            addlParms.(text{i})=num2str(addlParms.(text{i}));
        else
            % Convert \n & \t into characters for powerpoint
            warning('off','MATLAB:strrep:InvalidInputType');
            addlParms.(text{i})=strrep(addlParms.(text{i}),'\t',9);
            addlParms.(text{i})=strrep(addlParms.(text{i}),'\n',13);
            % Convert \n into characters for powerpoint, if added via
            % sprintf, eg note=sprintf('%s\n%s','Hello','World');
            addlParms.(text{i})(addlParms.(text{i})==10)=13;
        end
    end
end
% Add notes if they are specified
if isfield(addlParms,'notes')
    % Taken from this page: http://www.mahipalreddy.com/vba.htm
    if get(new_slide.notesPage.Shapes,'Count')==0
        % Still haven't figured this Matlab -> VBA out. AddRect returns an
        % error
        warning('saveppt2:nonoteadded','No note box found, none added');
    else
        % For each of the shapes, loop through until you find one with a
        % text frame.
        for i=1:get(new_slide.notesPage.Shapes,'Count')
            % If it has a text frame, set the text and break out of the
            % loop.
            if strcmp(get(new_slide.notesPage.Shape.Item(i),'HasTextFrame'),'msoTrue')
                set(new_slide.notesPage.Shape.Item(i).TextFrame.TextRange,'Text',addlParms.notes);
                break;
            end
        end
    end
end
% If comment field is specified
if isfield(addlParms,'comments')
    new_comment=invoke(new_slide.Shapes,'AddComment');
    set(new_comment.TextFrame.TextRange,'Text',addlParms.comments);
end
% Add textbox if it is specified
if isfield(addlParms,'text')
    new_text=invoke(new_slide.Shapes,'AddTextbox','msoTextOrientationHorizontal',0,0,720,540/4);
    set(new_text.TextFrame.TextRange,'Text',addlParms.text);
end
%% Exit Functions
% If saveppt2 was called after an init as part of a batch process, just
% return
if isfield(addlParms,'ppt');
    return;
end
% Save the file
if ~exist(filespec,'file')
    % Save file as new:
    invoke(op,'SaveAs',filespec,1);
else
    % Save existing file:
    invoke(op,'Save');
end
% If asked to close the file.
if checkParm(addlParms,'close')
    % Check if other presentations are open. If so, only close this
    % powerpoint, otherwise quit the application.
    if checkParm(addlParms,'close')
        invoke(op,'Close');
        % Sanity checking for when called from within a script. If saveppt2 are
        % called too close together then the file will not be done being written to
        % or powerpoint will not have completely closed, causing an error. This
        % simply stalls the exit until the ActiveX object has closed. Adds an
        % additional 0.001 seconds to execution, but helps prevent failures in
        % loops.
        % If it doesn't exit by 1000, return anyway
        for i=1:1000;
            try
                % Try to get parameter
                op.ReadOnly
            catch
                % When an error is thrown (the ActiveX object is destroyed), return
                return;
            end
        end
        if ppt.Presentations.Count==0
            invoke(ppt,'Quit');
            for i=1:1000;
                try
                    % Try to get parameter
                    ppt.visible
                catch
                    % When an error is thrown (the ActiveX object is destroyed), return
                    return;
                end
            end
        end
    end
else
    % If the user isn't closing the presentation and is assigning the
    % PowerPoint presentation object to a variable, return it.
    if nargout==1
        varargout{1}=op;
    end
end
end

%% Supporting Functions. Here Be Dragons.
% Check to see if the parameters is 'set'
function result=checkParm(addlParms,parm)
result=0;
try
    if isfield(addlParms,parm)
        if islogical(addlParms.(parm))&&addlParms.(parm)==true
            result=1;
        end
    end
catch
end
return
end

function parameters=validateInput(argsIn,validParameters,force)
%VALIDATEINPUT  Validate input for m-files
%   parameters - validateInput(varargin,validParameters,[force])
%   varargin - passed directly from the parent script.
%   validParameters - A cell of strings or cells with valid input arguments
%       validParameters = {{'print','p'},{'size','s'},'name'};
%       Will accept the following as valid input:
%              print, -print, p, -p
%              size, -size, s, -s
%              name, -name
%
%       If the input pararameter is specified as 'yes', 'on', or 'true' then the
%       parameter is set as true. If it is 'no', 'off', or 'false' then it
%       is returned as false. This is for when calling programs with out
%       parenthesis.
%
%   force - Force the output parameters struct to have all validParameters,
%   even if they are not given. All non-specified input will be set to
%   'false'.
%
%   parameters is a structure with each given input argument. In the case
%   that there are multiple options, the output is set to the first
%   'option'. 'size' and 's' will both set the 'parameters.size' field.
%
%   Example (This is intended to be called from within a function)
%    varargin={'p','s',10,'name','john doe'}
%    validParameters={{'size','s'},{'print','p'},'name'}
%    parameters=validateInput(varargin,validParameters)
%
%    varargin={'p','on','s',10,'name','john doe'}
%    validParameters={{'size','s'},{'print','p'},'name'}
%    parameters=validateInput(varargin,validParameters)
%
%    varargin={'p'}
%    validParameters={{'size','s'},{'print','p'},'name'}
%    parameters=validateInput(varargin,validParameters,true)
%
% Author: Jedediah Frey
% Created: Apr 2010
% Copyright 2010

error(nargchk(1, 3, nargin, 'struct'))
if nargin<3
    force=false;
else
    force=logical(force);
end
i=1; % Set loop variable
while i<=numel(argsIn) % Do until the end of
    % Determine if the current input is a valid parameter.
    [validParameter,parmName]=valid(argsIn{i},validParameters);
    % If it is not a valid input, die with errror.
    if ~validParameter
        error('validateInput:UnknownParameter',['Unknown Parameter: ' argsIn{i}]);
    end
    % If the parameter is the 'last' input or the next argument is a valid
    % input.
    if i+1>numel(argsIn)||valid(argsIn{i+1},validParameters)
        % Set the parameter to true (used for 'optional' calls)
        parameters.(parmName)=true;
        i=i+1; % Increment counter by 1
    else
        % Otherwise, use the next 'input' as the parameter's value
        parameters.(parmName)=argsIn{i+1};
        % If the value is logical and true, sit it to true.
        try
            if islogical(parameters.(parmName))&&parameters.(parmName)==true
                parameters.(parmName)=true;
                % If it is 'yes' or 'on', set it to true.
            elseif strcmpi(parameters.(parmName),'yes')||strcmpi(parameters.(parmName),'on')||strcmpi(parameters.(parmName),'true')
                parameters.(parmName)=true;
            elseif strcmpi(parameters.(parmName),'no')||strcmpi(parameters.(parmName),'off')||strcmpi(parameters.(parmName),'false')
                parameters.(parmName)=false;
                % If it is a number (that may have been passed as a string,
                % then convert it to a number
            elseif ischar(parameters.(parmName))&&~isnan(str2double(parameters.(parmName)))
                parameters.(parmName)=str2double(parameters.(parmName));
            end
        catch
        end
        i=i+2; % Increment counter by 2
    end
end
if ~force
    return;
end
for j=1:numel(validParameters)
    % Get the parameter name.
    if iscell(validParameters{j})
        name=validParameters{j}{1};
    else
        name=validParameters{j};
    end
    % If the parameter is not set, set it to false.
    if ~isfield(parameters,name)
        parameters.(name)=false;
    end
end
end

function [validParameter,name] = valid(parameter,validParameters)
% By default the current parameter isn't valid.
validParameter=false;
name=''; % Set the parameter name to something, in case nothing is returned.
% For each of the validParameters
for j=1:numel(validParameters)
    % If the parameter is a cell.
    if iscell(validParameters{j})
        % For each option in the cell
        for k=1:numel(validParameters{j})
            % If the parameter directly matches OR the first character is a
            % '-' and the rest of the string match.
            try
                if strcmpi(validParameters{j}{k},parameter)||(strcmpi(parameter(1),'-')&&strcmpi(validParameters{j}{k},parameter(2:end)))
                    validParameter=true; % Set as a valid parameter.
                    name=validParameters{j}{1}; % Return the first cell as the variable name'
                    return;
                end
            catch
            end
        end
    else
        % If the validParameter isn't a cell, just directly compare it.
        try
            if strcmpi(validParameters{j},parameter)||(strcmpi(parameter(1),'-')&&strcmpi(validParameters{j},parameter(2:end)))
                name=validParameters{j};
                validParameter=true;
                return;
            end
        catch
        end
    end
end
end