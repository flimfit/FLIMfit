
function h_fig = icy_vidshow(h_fig, data, title)
% h_fig = icy_vidshow(data)
% h_fig = icy_vidshow(data, title)
% h_fig = icy_vidshow(h_fig, data)
% h_fig = icy_vidshow(h_fig, data, title)
%
% Display the 2D+T image 'data' in Icy, and return the handle of the
% corresponding figure.
%
% If the 'h_fig' argument is provided, the corresponding figure is used;
% otherwise, a new figure is created. If the 'title' argument is provided,
% the function will also change the title of the figure, otherwise it is let
% unchanged.

% Allocate a new figure if necessary
if(~exist('title', 'var') && exist('data', 'var') && ischar(data))
	title = data;
	data  = h_fig;
	h_fig = icy_figure();
elseif(~exist('data', 'var'))
	data  = h_fig;
	h_fig = icy_figure();
end

% Default title
persistent counter;
if(isempty(counter))
	counter = 0;
end
if(~exist('title', 'var'))
	title = icy_gettitle(h_fig);
	if(isempty(title))
		counter = counter + 1;
		title   = sprintf('Video %d', counter);
	end
end

% Execute the command
args_in.h_fig = int32(h_fig);
args_in.title = title;
args_in.data  = data;
icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'vidshow', args_in);
