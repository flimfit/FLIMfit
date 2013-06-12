% Displays a progress dialog to notify the user of an ongoing operation.
%
% Input arguments:
% h:
%    graphics handle to a progress bar dialog, a new window is created if
%    not specified
% r:
%    completion ratio, a number between 0.0 and 1.0, completion state is
%    indeterminate if missing
% msg:
%    a message string to be displayed in the window
%
% The arguments may be specified in arbitrary order.
%
% Examples:
% h = waitdialog(r, msg)  creates a progress dialog with completion
%                         ratio of r and message string msg
% h = waitdialog(msg)     creates a progress dialog with indeterminate
%                         completion state and given message string msg
% waitdialog(r, h, msg)   updates the progress dialog h to completion ratio
%                         of r and message string msg
%
% See also: waitbar

% Copyright 2008-2009 Levente Hunyadi
function hfig = waitdialog(varargin)

h = [];
r = [];
msg = [];
for k = 1 : nargin
    [h,r,msg] = waitdialog_chkparam(varargin{k}, h, r, msg);
end

if ~isempty(h) && isempty(r) && isempty(msg)
    warning('gui:waitdialog', 'Only a dialog handle is specified, dialog is not updated.');
    hfig = h;
elseif ischar(msg)
    hfig = progressbar(h, r, msg);
else
    hfig = progressbar(h, r);
end

function [h,r,msg] = waitdialog_chkparam(x, h, r, msg)

if isempty(x)
    return;
elseif ischar(x)  % a string
    msg = x;
elseif isscalar(x) && x ~= 0 && ishandle(x) && strcmp('__progressbar__', get(x, 'Tag'))  % a graphics handle to a progress bar dialog (0 is the root handle)
    h = x;
elseif isscalar(x) && isreal(x) && isnumeric(x) && x >= 0.0 && x <= 1.0  % a real number between 0.0 and 1.0
    r = x;
else
    if isnumeric(x)
        error('gui:waitdialog:ArgumentTypeMismatch', 'Argument of type "%s" with value %s is not recognized, or the referenced graphics handle is not a valid progress bar dialog handle.', class(x), num2str(x));
    else
        error('gui:waitdialog:ArgumentTypeMismatch', 'Argument of type "%s" is not recognized.', class(x));
    end
end
