% Displays a progress dialog to notify the user of an ongoing operation.
%
% Input arguments:
% h:
%    graphics handle to a progress bar dialog, or empty if a new window is
%    about to be created
% r:
%    completion ratio, a number between 0.0 and 1.0, or empty if the
%    completion state is indeterminate
% msg:
%    a message string to be displayed in the window, or empty to display
%    no message

% Copyright 2008-2010 Levente Hunyadi
function h = progressbar(h, r, msg, usejavactrl)

if nargin >= 1 && ~isempty(h)
    %validateattributes(h, {'numeric'}, {'scalar'});
    %assert(h ~= 0 && ishandle(h), ...
    %    'gui:waitdialog:ArgumentTypeMismatch', ...
    %    'First argument is expected to be a graphics handle.');
else
    h = [];
end
if nargin >= 2 && ~isempty(r)
    validateattributes(r, {'numeric'}, {'nonnegative','real','scalar'});
else
    r = [];
end
if nargin >= 3 && ~isempty(msg)
    validateattributes(msg, {'char'}, {'nonempty','row'});
    msgupdate = true;
elseif nargin >= 3
    msgupdate = true;
else
    msgupdate = false;
    msg = '';
end
if nargin >= 4
    assert(isempty(h), ...
        'gui:waitdialog:ArgumentTypeMismatch', ...
        'Cannot change implementation once the dialog is constructed.');
    if isempty(usejavactrl)
        usejavactrl = true;
    else
        validateattributes(usejavactrl, {'logical'}, {'scalar'});
    end
else
    usejavactrl = true;
end

defaultmsg = 'Please wait...';
if isempty(h)  % no handle given, create dialog
    if usejavactrl && usejava('swing')  % Java swing implementation
        % progress bar dialog
        h = progressfigure();
        
        % progress bar
        jbar = javax.swing.JProgressBar(0, 1000);  % min--max
        if ~isempty(r)
            jbar.setValue(fix(1000*r));
            jbar.setStringPainted(true);
        else
            jbar.setStringPainted(false);
            jbar.setIndeterminate(true);
        end
        pixelpos = getpixelposition(h);
        [jbarhg, jbarctrl] = javacomponent(jbar, [0 0 pixelpos(3) pixelpos(4)], h);
        set(jbarctrl, ...
            'Tag', '__progressbarcontrol__', ...  % used to differentiate this container from other containers
            'Units', 'pixels');

        % status message
        if ~isempty(msg)
            defaultmsg = msg;
        end
        uicontrol(h, ...
            'Style', 'text', ...
            'Units', 'pixels', ...
            'BackgroundColor', 'white', ...
            'FontSize', 8, ...
            'String', defaultmsg, ...
            'Visible', 'off');
        if ~isempty(msg)
            set(h, 'Visible', 'on');
        end
        
        % progress bar dialog callbacks
        set(h, ...
            'UserData', jbar, ...
            'ResizeFcn', @progressfigure_onresize);
        progressfigure_onresize(h);  % force control re-arrangement
        set(h, 'Visible', 'on');
    else  % default MatLab implementation
        assert(~isempty(r), ...
            'gui:waitdialog:InvalidOperation', ...
            'waitdialog MatLab implementation cannot be in indeterminate state.');
        if msgupdate
            h = waitbar(r, msg);
        else
            h = waitbar(r);
        end
    end
else  % handle given, update dialog
    jbar = get(h, 'UserData');
    if ~isempty(jbar) && isjava(jbar)  % progress bar created with Java implementation
        if ~isempty(r)
            jbar.setValue(fix(1000*r));
            jbar.setStringPainted(true);
            jbar.setIndeterminate(false);
        else
            jbar.setStringPainted(false);
            jbar.setIndeterminate(true);
        end
        
        % update status message
        if msgupdate
            msgctrl = findobj(h, 'Type', 'uicontrol', 'Style', 'text');
            if ~isempty(msgctrl) && isscalar(msgctrl)
                visible = get(msgctrl, 'Visible');
                if ~isempty(msg)  % update string if given
                    set(msgctrl, ...
                        'String', msg, ...
                        'Visible', 'on');
                else
                    set(msgctrl, ...
                        'Visible', 'off');
                end
                if ~strcmp(visible, get(msgctrl, 'Visible'))  % message visibility changed
                    progressfigure_onresize(h);  % force control re-arrangement
                end
            end
        end
    else  % progress bar created with MatLab implementation
        assert(~isempty(r), ...
            'gui:waitdialog:InvalidOperation', ...
            'waitdialog MatLab implementation cannot be in indeterminate state.');
        if msgupdate
            h = waitbar(r, h, msg);
        else
            h = waitbar(r, h);
        end
    end
end
drawnow;

function h = progressfigure()
% A figure for progress bar and associated controls.

width = 250;
height = 60;
h = figure( ...
    'Units', 'pixels', ...
    'Color', 'white', ...
    'DockControls', 'off', ...
    'IntegerHandle', 'off', ...
    'MenuBar', 'none', ...
    'Name', 'Operation in progress', ...
    'NextPlot', 'new', ...
    'NumberTitle', 'off', ...
    'Pointer', 'watch', ...
    'Position', [0, 0, width, height], ...
    'Tag', '__progressbar__', ...  % used to differentiate this dialog from other dialogs
    'Toolbar', 'none', ...
    'Visible', 'off', ...
    'CloseRequestFcn', ''); %@(source,event) processfigure_onclose(source));
movegui(h, 'center');  % center on screen

% Occurs when the user closes the progress bar window.
function processfigure_onclose(fig)

cleanup = onCleanup(@() delete(fig)); %#ok<NASGU>
set(fig, 'Name', 'Termination in progress');
drawnow;

function progressfigure_onresize(fig, event) %#ok<INUSD>
% Fired when the user resizes the progress bar window.
%
% Input arguments:
% fig:
%    a graphics handle to the progress bar window

ctrlheight = 20;  % desired height of progress bar control in pixels
padding = 20;     % desired padding around left and right edge of progress bar control in pixels

set(fig,'Units','pixels');
[figwidth,figheight] = position2size(get(fig, 'Position'));

jbarctrl = findobj(fig, 'Tag', '__progressbarcontrol__');  % a MatLab HG container that encapsulates the Java control
msgctrl = findobj(fig, 'Type', 'uicontrol', 'Style', 'text');

if ~isempty(msgctrl) && isscalar(msgctrl) && strcmp('on', get(msgctrl, 'Visible'));  % a message text is present
    set(jbarctrl, 'Position', [padding, (figheight-2*ctrlheight)/2, figwidth-2*padding, ctrlheight]);
    set(msgctrl, 'Position', [padding, (figheight-2*ctrlheight)/2+ctrlheight, figwidth-2*padding, ctrlheight]);
else  % no message text
    set(jbarctrl, 'Position', [padding, (figheight-ctrlheight)/2, figwidth-2*padding, ctrlheight]);
end
